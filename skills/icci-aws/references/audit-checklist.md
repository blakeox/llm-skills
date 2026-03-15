# ICCI AWS Quarterly Deep Audit Checklist

Run this audit quarterly to assess the full state of ICCI's AWS infrastructure. All operations are **read-only** -- describe/list/get calls only. Log every command to `~/Documents/claude-code/aws/audit-commands.log`.

Output the audit report to `~/Documents/claude-code/aws/audit-<date>.md`.

---

## Pre-Audit Setup

```bash
# Verify identity and account
aws sts get-caller-identity
aws iam list-account-aliases

# Set up command logging
LOGFILE=~/Documents/claude-code/aws/audit-commands.log
echo "=== Quarterly Audit Started $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> $LOGFILE
```

---

## Phase 1: Cost Optimization

### 1.1 Monthly Spend Trend

```bash
# 3-month cost trend
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-3m +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost

# Current month by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Check:** Monthly total should be ~$714. Alert if >$850.

### 1.2 EC2 Instance Review

```bash
# All instances in both regions
aws ec2 describe-instances --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,LaunchTime,Placement.AvailabilityZone]' --output table

aws ec2 describe-instances --region us-east-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,LaunchTime,Placement.AvailabilityZone]' --output table
```

**Check for:**
- [ ] Any new unexpected instances
- [ ] Any stopped instances accumulating EBS costs
- [ ] Instance types matching fleet standard (t3a.medium for PBX)
- [ ] Instances still on previous-gen types (t2.medium, c5a.large)

### 1.3 CPU Utilization (Right-Sizing)

```bash
# 14-day CPU average for all running instances (us-east-2)
for id in $(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-2 --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$id" "Name=key,Values=Name" --region us-east-2 --query 'Tags[0].Value' --output text)
  avg=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$id --start-time $(date -u -v-14d +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 1209600 --statistics Average \
    --region us-east-2 --query 'Datapoints[0].Average' --output text 2>/dev/null)
  echo "$id ($name): ${avg}%"
done

# Same for us-east-1
for id in $(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-1 --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$id" "Name=key,Values=Name" --region us-east-1 --query 'Tags[0].Value' --output text)
  avg=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$id --start-time $(date -u -v-14d +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 1209600 --statistics Average \
    --region us-east-1 --query 'Datapoints[0].Average' --output text 2>/dev/null)
  echo "$id ($name): ${avg}%"
done
```

**Check:** Flag any PBX instance with <3% CPU avg as right-sizing candidate. Remember PBX workloads are bursty -- don't downsize below t3a.medium without careful testing.

### 1.4 EBS Volumes

```bash
# Unattached volumes (both regions)
aws ec2 describe-volumes --filters "Name=status,Values=available" --region us-east-1 \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,Tags[?Key==`Name`].Value|[0],CreateTime]' --output table
aws ec2 describe-volumes --filters "Name=status,Values=available" --region us-east-2 \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,Tags[?Key==`Name`].Value|[0],CreateTime]' --output table

# gp2 volumes still not converted to gp3
aws ec2 describe-volumes --filters "Name=volume-type,Values=gp2" --region us-east-1 \
  --query 'Volumes[*].[VolumeId,Size,Tags[?Key==`Name`].Value|[0]]' --output table
aws ec2 describe-volumes --filters "Name=volume-type,Values=gp2" --region us-east-2 \
  --query 'Volumes[*].[VolumeId,Size,Tags[?Key==`Name`].Value|[0]]' --output table
```

**Check for:**
- [ ] Unattached volumes (delete or archive)
- [ ] Remaining gp2 volumes (convert to gp3 for 20% savings)
- [ ] Volume sizes consistent with fleet standard (60 GB boot, 8 GB swap)

### 1.5 EBS Snapshots

```bash
# Snapshot count and estimated cost per region
aws ec2 describe-snapshots --owner-ids 406551117454 --region us-east-1 --query 'length(Snapshots)'
aws ec2 describe-snapshots --owner-ids 406551117454 --region us-east-2 --query 'length(Snapshots)'

# Snapshots older than 90 days
aws ec2 describe-snapshots --owner-ids 406551117454 --region us-east-2 \
  --query "Snapshots[?StartTime<='$(date -u -v-90d +%Y-%m-%dT%H:%M:%S)'].[SnapshotId,VolumeId,VolumeSize,StartTime,Description]" --output table
```

**Check:** Snapshot costs should be ~$144/mo. Alert if >$180.

### 1.6 Elastic IPs

```bash
# All EIPs and their association status (both regions)
aws ec2 describe-addresses --region us-east-1 \
  --query 'Addresses[*].[PublicIp,AllocationId,InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table
aws ec2 describe-addresses --region us-east-2 \
  --query 'Addresses[*].[PublicIp,AllocationId,InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table
```

**Check for:**
- [ ] Unassociated EIPs (costing $3.50/mo each with no value)
- [ ] EIPs on stopped instances (also costing $3.50/mo)
- [ ] EIP quota utilization (us-east-2 was at 100%)

### 1.7 S3 Storage

```bash
# Bucket sizes
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text); do
  size=$(aws s3 ls s3://$bucket --summarize --recursive 2>/dev/null | tail -1 | awk '{print $3}')
  echo "$bucket: ${size:-0} bytes"
done

# Check lifecycle policies
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text); do
  echo "=== $bucket ==="
  aws s3api get-bucket-lifecycle-configuration --bucket $bucket 2>/dev/null || echo "  No lifecycle policy"
done
```

**Check for:**
- [ ] Unexpected storage growth (especially wvh-call-recordings-feb26)
- [ ] Buckets still missing lifecycle policies
- [ ] Incomplete multipart uploads consuming hidden storage

### 1.8 Reserved Instances & Savings Plans

```bash
# Active RIs
aws ec2 describe-reserved-instances --filters "Name=state,Values=active" --region us-east-1 \
  --query 'ReservedInstances[*].[ReservedInstancesId,InstanceType,InstanceCount,End]' --output table
aws ec2 describe-reserved-instances --filters "Name=state,Values=active" --region us-east-2

# Active Savings Plans
aws savingsplans describe-savings-plans --query 'SavingsPlans[?State==`active`].[SavingsPlanId,SavingsPlanType,Commitment,End]' --output table

# SP utilization
aws ce get-savings-plans-utilization \
  --time-period Start=$(date -u -v-1m +%Y-%m-01),End=$(date -u +%Y-%m-01) \
  --granularity MONTHLY
```

**Check for:**
- [ ] RIs expiring within 90 days (plan renewal or SP replacement)
- [ ] SP utilization <90% (commitment may be too high)
- [ ] SP utilization >99% (may benefit from increased commitment)

---

## Phase 2: Security

### 2.1 IAM Root Account

```bash
# Check root access keys
aws iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent'

# Credential report (MFA, password age, key age)
aws iam generate-credential-report
sleep 5
aws iam get-credential-report --query Content --output text | base64 --decode
```

**Check for:**
- [ ] Root access keys still present (CRITICAL -- should be deleted)
- [ ] Root MFA enabled
- [ ] Any new IAM admin user with MFA created (remediation from previous audit)

### 2.2 IAM Users & Access Keys

```bash
# List all users with access key age and last used
aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table

# Access key details for each user
for user in $(aws iam list-users --query 'Users[*].UserName' --output text); do
  echo "=== $user ==="
  aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]' --output table
  for key in $(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
    aws iam get-access-key-last-used --access-key-id $key --query 'AccessKeyLastUsed.[LastUsedDate,ServiceName]' --output text
  done
done
```

**Check for:**
- [ ] Keys older than 90 days (all were >90 days at baseline)
- [ ] Dormant keys (never used or not used in >180 days)
- [ ] Any user with MFA enabled (none had MFA at baseline)
- [ ] New users created since last audit

### 2.3 Security Groups

```bash
# SGs with 0.0.0.0/0 inbound rules
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-security-groups --region $region \
    --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName]' --output table
done

# Check SangomaConnect SG rules (the main SIP exposure concern)
aws ec2 describe-security-groups --group-ids sg-0ba27c0ff14b4d65d --region us-east-2 \
  --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpProtocol,IpRanges[*].CidrIp]'

# Check for "EEK - NO FIREWALL" SGs (should be deleted)
for region in us-east-1 us-east-2; do
  aws ec2 describe-security-groups --filters "Name=group-name,Values=*EEK*,*FIREWALL*" --region $region \
    --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
done

# Check Maeslantkering SSH exposure
aws ec2 describe-security-groups --group-ids sg-08682dc09525a43ba --region us-east-2 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'
```

**Check for:**
- [ ] SIP 5061 still open to world on SangomaConnect (known issue)
- [ ] OPEN SIP SG still on WVH (should have been removed)
- [ ] EEK - NO FIREWALL SGs still exist (should have been deleted)
- [ ] SSH open to world on Maeslantkering (should have been restricted)
- [ ] Any new SGs with open access patterns
- [ ] Unused SGs count (baseline: 23 unused)

### 2.4 CloudTrail, GuardDuty, Config, Flow Logs

```bash
# CloudTrail
aws cloudtrail describe-trails --region us-east-1
aws cloudtrail describe-trails --region us-east-2

# GuardDuty
aws guardduty list-detectors --region us-east-1
aws guardduty list-detectors --region us-east-2

# AWS Config
aws configservice describe-configuration-recorders --region us-east-1
aws configservice describe-configuration-recorders --region us-east-2

# VPC Flow Logs
aws ec2 describe-flow-logs --region us-east-1
aws ec2 describe-flow-logs --region us-east-2
```

**Check:** All four should be enabled. At baseline (March 2026) NONE were enabled.

### 2.5 S3 Security

```bash
# Account-level public access block
aws s3control get-public-access-block --account-id 406551117454

# Per-bucket encryption and versioning
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text); do
  echo "=== $bucket ==="
  aws s3api get-bucket-versioning --bucket $bucket
  aws s3api get-bucket-encryption --bucket $bucket 2>/dev/null || echo "  No encryption"
done
```

**Check for:**
- [ ] Account-level public access block still enabled (all 4 flags)
- [ ] S3 versioning enabled on critical buckets (none had it at baseline)
- [ ] All buckets encrypted (all were AES256 at baseline)

### 2.6 EBS Encryption

```bash
# Unencrypted volumes
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-volumes --filters "Name=encrypted,Values=false" --region $region \
    --query 'Volumes[*].[VolumeId,Size,Tags[?Key==`Name`].Value|[0]]' --output table
done

# Encryption-by-default status
aws ec2 get-ebs-encryption-by-default --region us-east-1
aws ec2 get-ebs-encryption-by-default --region us-east-2
```

**Check:** 7 unencrypted volumes existed at baseline (all 8 GB swap volumes in us-east-2). EBS encryption-by-default was not enabled.

### 2.7 KMS Key Rotation

```bash
# Customer-managed keys and rotation status
for key in $(aws kms list-keys --region us-east-2 --query 'Keys[*].KeyId' --output text); do
  desc=$(aws kms describe-key --key-id $key --region us-east-2 --query 'KeyMetadata.[KeyManager,Description]' --output text)
  if echo "$desc" | grep -q "CUSTOMER"; then
    rotation=$(aws kms get-key-rotation-status --key-id $key --region us-east-2 --query 'KeyRotationEnabled')
    echo "Key $key: rotation=$rotation ($desc)"
  fi
done
```

---

## Phase 3: Architecture & Reliability

### 3.1 AZ Distribution

```bash
# Instance distribution by AZ
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region $region \
    --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table
done
```

**Check:** At baseline, 10 of 11 PBX instances in us-east-2 were in us-east-2b. Any improvement in AZ distribution should be noted.

### 3.2 Backup Coverage

```bash
# Volumes with Backup=30 tag
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region $region \
    --query 'Volumes[*].[VolumeId,Tags[?Key==`Name`].Value|[0],Size,State,Attachments[0].InstanceId]' --output table
done

# Volumes MISSING Backup tag (potential gaps)
aws ec2 describe-volumes --region us-east-2 \
  --query 'Volumes[?!not_null(Tags[?Key==`Backup`].Value|[0])].[VolumeId,Size,Tags[?Key==`Name`].Value|[0]]' --output table

# Latest snapshot per backed-up volume
for vol in $(aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region us-east-2 --query 'Volumes[*].VolumeId' --output text); do
  name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$vol" "Name=key,Values=Name" --region us-east-2 --query 'Tags[0].Value' --output text)
  latest=$(aws ec2 describe-snapshots --filters "Name=volume-id,Values=$vol" --region us-east-2 \
    --query 'Snapshots | sort_by(@, &StartTime) | [-1].StartTime' --output text)
  echo "$vol ($name): latest snapshot $latest"
done
```

**Check for:**
- [ ] All 12 active PBX boot volumes have Backup=30 tag
- [ ] All backed-up volumes have a snapshot within the last 48 hours
- [ ] No unattached volumes still being snapshotted (waste)
- [ ] DLM policies are in ENABLED state

### 3.3 DLM Policy Health

```bash
# DLM policy status
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws dlm get-lifecycle-policies --region $region \
    --query 'Policies[*].[PolicyId,Description,State]' --output table
done

# Detailed policy schedule and retention
for region in us-east-1 us-east-2; do
  for pol in $(aws dlm get-lifecycle-policies --region $region --query 'Policies[*].PolicyId' --output text); do
    echo "=== $pol ($region) ==="
    aws dlm get-lifecycle-policy --policy-id $pol --region $region \
      --query 'Policy.PolicyDetails.Schedules[*].[Name,CopyTags,RetainRule,CreateRule]'
  done
done
```

### 3.4 Cross-Region Backup

```bash
# Check if any DLM policies have cross-region copy
for region in us-east-1 us-east-2; do
  for pol in $(aws dlm get-lifecycle-policies --region $region --query 'Policies[*].PolicyId' --output text); do
    cross=$(aws dlm get-lifecycle-policy --policy-id $pol --region $region \
      --query 'Policy.PolicyDetails.Schedules[*].CrossRegionCopyRules' --output text)
    echo "$pol ($region): cross-region=$cross"
  done
done
```

**Check:** At baseline, no cross-region backup existed.

### 3.5 EIP Quota

```bash
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-1 \
  --query 'Quota.[QuotaName,Value]' --output text
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-2 \
  --query 'Quota.[QuotaName,Value]' --output text

# Current usage
echo "us-east-1 EIPs: $(aws ec2 describe-addresses --region us-east-1 --query 'length(Addresses)')"
echo "us-east-2 EIPs: $(aws ec2 describe-addresses --region us-east-2 --query 'length(Addresses)')"
```

### 3.6 Route 53 & DNS

```bash
# Hosted zones
aws route53 list-hosted-zones --query 'HostedZones[*].[Id,Name,ResourceRecordSetCount]' --output table

# Health checks
aws route53 list-health-checks --query 'HealthChecks[*].[Id,HealthCheckConfig.FullyQualifiedDomainName,HealthCheckConfig.Type]' --output table
```

### 3.7 AMI Inventory

```bash
# Custom AMIs
aws ec2 describe-images --owners self --region us-east-2 \
  --query 'Images[*].[ImageId,Name,CreationDate,State]' --output table
aws ec2 describe-images --owners self --region us-east-1 \
  --query 'Images[*].[ImageId,Name,CreationDate,State]' --output table
```

---

## Phase 4: Operational Excellence

### 4.1 CloudWatch Alarms

```bash
aws cloudwatch describe-alarms --region us-east-1 --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
aws cloudwatch describe-alarms --region us-east-2 --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
```

**Check:** Zero alarms existed at baseline. Any new alarms are progress.

### 4.2 CloudWatch Dashboards

```bash
aws cloudwatch list-dashboards --region us-east-1
aws cloudwatch list-dashboards --region us-east-2
```

**Check:** One empty "billing" dashboard existed at baseline.

### 4.3 SSM Agent Status

```bash
aws ssm describe-instance-information --region us-east-1 --query 'InstanceInformationList[*].[InstanceId,PlatformName,AgentVersion]' --output table
aws ssm describe-instance-information --region us-east-2 --query 'InstanceInformationList[*].[InstanceId,PlatformName,AgentVersion]' --output table
```

**Check:** No SSM-managed instances at baseline.

### 4.4 Instance Status Checks

```bash
# Health of all running instances
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-instance-status --filters "Name=instance-state-name,Values=running" --region $region \
    --query 'InstanceStatuses[*].[InstanceId,SystemStatus.Status,InstanceStatus.Status]' --output table
done
```

### 4.5 Tagging Compliance

```bash
# Check for missing customer tags on PBX instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`customer`].Value|[0],Tags[?Key==`PBX Version`].Value|[0],Tags[?Key==`Backup`].Value|[0]]' --output table

aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`customer`].Value|[0]]' --output table
```

**Check for:**
- [ ] All instances have `Name` and `customer` tags
- [ ] PBX instances have `PBX Version` tag
- [ ] All boot volumes have `Backup` tag
- [ ] No inconsistent tag key naming (customer vs CLIENT)

### 4.6 SES Identities

```bash
aws ses list-identities --region us-east-1
aws ses list-identities --region us-east-2
```

---

## Phase 5: PBXact Fleet

### 5.1 Fleet Health

```bash
# All PBX instance status
for id in i-0449a85fc75e22cdc i-0e6c60d8be50245b7 i-0f5caf9b7b2802035 i-036f677b82ad1d49d i-06dad05c1b135be76 i-01b082fa7983654f2 i-0e8b687de485b7ed0 i-0238d4e8408901737 i-007cf0b2e89c134c2 i-06108abf84cc8c9c7 i-08e0b307d4d86fce7 i-0b960f7c26d457fba; do
  region="us-east-2"
  if [ "$id" = "i-0449a85fc75e22cdc" ]; then region="us-east-1"; fi
  status=$(aws ec2 describe-instance-status --instance-ids $id --region $region \
    --query 'InstanceStatuses[0].[SystemStatus.Status,InstanceStatus.Status]' --output text 2>/dev/null)
  name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$id" "Name=key,Values=Name" --region $region --query 'Tags[0].Value' --output text)
  echo "$id ($name): $status"
done
```

### 5.2 PBX OS & Version Audit

Compare each instance against the fleet standard:
- **Target OS:** Debian 12
- **Target PBX Version:** PBXact 17
- **Target Instance Type:** t3a.medium

Document any instances still on CentOS 7/SNG7 or PBXact 16.

### 5.3 Security Group Compliance

For each PBX, verify:
1. icci LLC Backdoor is attached (management access)
2. VoIP Service Providers is attached (Telnyx trunk access)
3. SangomaConnect is only attached where actively needed
4. Per-PBX custom SG exists with client-specific rules
5. No "OPEN SIP" or "EEK - NO FIREWALL" SGs attached

### 5.4 Backup Verification

Cross-reference the fleet inventory table against backup status. Every active PBX boot volume MUST have:
- `Backup=30` tag
- At least one snapshot within the last 48 hours
- Swap volume tagged `Backup=FALSE` (not being wastefully snapshotted)

### 5.5 EIP Mapping Verification

Verify each PBX's EIP matches the fleet inventory table. Check for:
- EIP disassociations (PBX lost its IP)
- New EIPs that don't match known fleet IPs
- EIPs on stopped instances that should be released

---

## Audit Report Template

```markdown
# ICCI AWS Quarterly Audit Report
**Account:** 406551117454
**Audit Date:** YYYY-MM-DD
**Auditor:** Claude Code (read-only)
**Regions:** us-east-1, us-east-2

## Executive Summary
[1-2 paragraph overview of findings]

## Scorecard
| Category | Status | Change from Last Audit |
|----------|--------|----------------------|
| Cost | $XXX/mo | +/-$XX |
| Security Posture | X critical / Y high | +/- from baseline |
| Backup Coverage | XX/12 PBX backed up | same/improved/degraded |
| Fleet Standardization | X/10 | +/- from baseline |
| AZ Distribution | X AZs in use | same/improved |

## Phase 1: Cost -- [findings]
## Phase 2: Security -- [findings]
## Phase 3: Architecture -- [findings]
## Phase 4: Operations -- [findings]
## Phase 5: PBXact Fleet -- [findings]

## Changes Since Last Audit
[List all changes detected]

## Recommendations
[Prioritized list]

## Commands Logged
All commands logged to ~/Documents/claude-code/aws/audit-commands.log
```

---

## Post-Audit

```bash
echo "=== Quarterly Audit Completed $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> $LOGFILE
```
