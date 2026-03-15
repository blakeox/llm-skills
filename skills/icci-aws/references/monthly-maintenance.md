# ICCI AWS Monthly Maintenance Checklist

Run this checklist monthly between quarterly deep audits. This is a lighter-weight review focused on catching drift, cost anomalies, and operational issues before they become critical.

**Time estimate:** 30-45 minutes
**Output:** `~/Documents/claude-code/aws/monthly-<YYYY-MM>.md`
**Command log:** Append all commands to `~/Documents/claude-code/aws/audit-commands.log`

---

## 1. Cost Anomaly Check

```bash
# Current month vs. previous month
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-2m +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Action items:**
- [ ] Monthly total is within expected range (~$714, alert if >$850)
- [ ] No unexpected new service charges
- [ ] EBS snapshot costs stable (~$144/mo, alert if >$180)
- [ ] Public IPv4 costs decreasing as stopped instances are terminated
- [ ] S3 costs stable (~$2.35/mo, alert if >$10)

---

## 2. Unassociated Elastic IPs

```bash
# Find EIPs not attached to any instance
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-addresses --region $region \
    --query 'Addresses[?!InstanceId].[PublicIp,AllocationId,Tags[?Key==`Name`].Value|[0]]' --output table
done
```

**Action items:**
- [ ] No new unassociated EIPs since last check
- [ ] Any previously-flagged unassociated EIPs released (each costs $3.50/mo)
- [ ] EIPs on stopped instances flagged for review

---

## 3. DLM Snapshot Freshness

Verify every PBX boot volume has a snapshot within the last 48 hours.

```bash
echo "=== PBX Backup Freshness Check ==="
THRESHOLD=$(date -u -v-48H +%Y-%m-%dT%H:%M:%S)

for region in us-east-1 us-east-2; do
  for vol in $(aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region $region --query 'Volumes[*].VolumeId' --output text); do
    name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$vol" "Name=key,Values=Name" --region $region --query 'Tags[0].Value' --output text)
    attached=$(aws ec2 describe-volumes --volume-ids $vol --region $region --query 'Volumes[0].Attachments[0].InstanceId' --output text)
    latest=$(aws ec2 describe-snapshots --filters "Name=volume-id,Values=$vol" --region $region \
      --query 'Snapshots | sort_by(@, &StartTime) | [-1].StartTime' --output text)

    if [ "$latest" = "None" ] || [ -z "$latest" ]; then
      echo "ALERT: $vol ($name) -- NO SNAPSHOTS FOUND"
    elif [[ "$latest" < "$THRESHOLD" ]]; then
      echo "STALE: $vol ($name) -- last snapshot $latest (>48h ago)"
    else
      echo "OK: $vol ($name) -- last snapshot $latest"
    fi
  done
done
```

**Action items:**
- [ ] All 12 PBX boot volumes have snapshots within 48 hours
- [ ] No STALE or ALERT results
- [ ] If any volume is missing recent snapshots, check DLM policy status:
  ```bash
  aws dlm get-lifecycle-policies --region us-east-2
  aws dlm get-lifecycle-policies --region us-east-1
  ```

---

## 4. Cost Explorer Anomalies

```bash
# Daily cost for the last 14 days (spot spikes)
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-14d +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

**Action items:**
- [ ] No single day >$35 (daily average should be ~$23)
- [ ] No sustained multi-day cost increase without explanation
- [ ] Data transfer costs stable (no DDoS or unusual outbound traffic)

---

## 5. Security Group Changes

```bash
# Check for any SGs modified recently (requires CloudTrail -- skip if not enabled)
# If CloudTrail is enabled:
# aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress --start-time $(date -u -v-30d +%Y-%m-%dT%H:%M:%S)

# Manual check: SGs with 0.0.0.0/0 rules (compare against known baseline)
for region in us-east-1 us-east-2; do
  echo "=== $region: SGs with 0.0.0.0/0 ==="
  aws ec2 describe-security-groups --region $region \
    --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName]' --output table
done
```

**Known SGs with open access (baseline):**
- SangomaConnect: TCP 5061, UDP 10000-20000 open to world (on 9 PBX instances)
- OPEN SIP: UDP/TCP 5060/5061/5160/5161 open to world (on WVH only)
- Maeslantkering Custom: SSH 22 open to world
- VoIP EEK-NO FIREWALL (unattached, should be deleted)
- EEK - NO FIREWALL (unattached, should be deleted)

**Action items:**
- [ ] No new SGs with 0.0.0.0/0 rules beyond the known baseline
- [ ] No new instances attached to dangerous SGs
- [ ] Known open SGs remediation progress tracked

---

## 6. Instance Health

```bash
# Status checks for all running instances
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-instance-status --filters "Name=instance-state-name,Values=running" --region $region \
    --query 'InstanceStatuses[*].[InstanceId,SystemStatus.Status,InstanceStatus.Status]' --output table
done
```

**Action items:**
- [ ] All 16 running instances show ok/ok status
- [ ] No instances in "impaired" state
- [ ] No new stopped instances that should be running

---

## 7. EIP Quota Check

```bash
echo "us-east-1 EIPs: $(aws ec2 describe-addresses --region us-east-1 --query 'length(Addresses)')/$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-1 --query 'Quota.Value' --output text)"
echo "us-east-2 EIPs: $(aws ec2 describe-addresses --region us-east-2 --query 'length(Addresses)')/$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-2 --query 'Quota.Value' --output text)"
```

**Action items:**
- [ ] us-east-2 quota not at 100% (was 15/15 at baseline; request increase if still full)
- [ ] us-east-1 has headroom (was 6/10)
- [ ] If quota increase was requested, verify it was approved

---

## 8. RI/SP Expiration Timeline

```bash
# Check for RIs expiring within 90 days
aws ec2 describe-reserved-instances --filters "Name=state,Values=active" --region us-east-1 \
  --query 'ReservedInstances[*].[ReservedInstancesId,InstanceType,End]' --output table

# Check SP end dates
aws savingsplans describe-savings-plans --query 'SavingsPlans[?State==`active`].[SavingsPlanId,SavingsPlanType,End]' --output table
```

**Key dates to watch:**
- 2026-04-15: c5a.large RI expires (do NOT renew -- migrate BayDesign to t3a.medium)
- 2026-12-16: Compute SP expires
- 2026-12-19: EC2 Instance SP + 2x t3a.medium RI expire
- 2027-10-22: m5a.xlarge RI expires (no action needed for a while)

**Action items:**
- [ ] Note any RI/SP expiring within 90 days
- [ ] Plan renewal or replacement strategy before expiration
- [ ] Track BayDesign migration progress (must happen before c5a.large RI renewal decision)

---

## 9. AWS Security Advisories

```bash
# Check for AWS personal health events
aws health describe-events --filter "eventTypeCategories=scheduledChange,accountSpecific,issue" --region us-east-1 2>/dev/null || echo "Health API requires Business Support"
aws health describe-events --filter "eventTypeCategories=scheduledChange,accountSpecific,issue" --region us-east-2 2>/dev/null || echo "Health API requires Business Support"
```

**Note:** AWS Health API may require Business Support tier. If unavailable, manually check the AWS Personal Health Dashboard in the console.

**Action items:**
- [ ] No pending maintenance events for ICCI instances
- [ ] No security advisories affecting ICCI's instance types or AMIs
- [ ] No upcoming EC2 retirements

---

## 10. S3 Storage Growth

```bash
# Bucket sizes
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text); do
  count=$(aws s3api list-objects-v2 --bucket $bucket --query 'KeyCount' --output text 2>/dev/null)
  echo "$bucket: $count objects"
done
```

**Watch specifically:**
- [ ] `wvh-call-recordings-feb26` -- monitor growth, ensure lifecycle policy is in place
- [ ] `iccillc.plesk.okf.org` -- check for stale multipart uploads
- [ ] `cloudberry.0001` -- largest bucket (230 GB), should be mostly Glacier

---

## 11. PBX Migration Progress

Track the CentOS 7 / SNG7 to Debian 12 migration:

| PBX | Baseline Status | Current Status | Notes |
|-----|----------------|----------------|-------|
| BayDesign PBX | CentOS 7 + c5a.large | [check] | RI expires Apr 15 |
| HealingPBXact | SNG7 + t2.medium | [check] | |
| Praxis PBX | SNG7 + t3a.medium | [check] | Oldest PBX (Dec 2020) |
| IraniWise PBX | SNG7 + t3a.medium | [check] | |
| FCI PBX | SNG7 + t3a.medium | [check] | |

**Action items:**
- [ ] Update migration status for each PBX
- [ ] Note any newly migrated systems since last check
- [ ] Verify newly migrated systems have proper tags and backup coverage

---

## 12. Stopped Instance Review

```bash
for region in us-east-1 us-east-2; do
  echo "=== $region ==="
  aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --region $region \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],StateTransitionReason]' --output table
done
```

**Baseline stopped instances:**
- DDP PBX (OLD) i-00250861fe908cc1c -- safe to terminate
- icci UNMS i-09d822ecbadc95bb4 -- evaluate for termination
- CentOS7-recovery i-09d0a264466d68d0b -- safe to terminate
- icciPBX17 Feb26 GM i-096cc133db680ea1f -- KEEP (gold master)

**Action items:**
- [ ] No new unexpectedly stopped instances
- [ ] Previously-flagged stopped instances terminated (or justified)
- [ ] EBS volumes on terminated instances cleaned up

---

## Monthly Report Template

```markdown
# ICCI AWS Monthly Maintenance Report
**Month:** YYYY-MM
**Run Date:** YYYY-MM-DD
**Auditor:** Claude Code (read-only)

## Summary
- Monthly cost: $XXX (baseline: $714, threshold: $850)
- All PBX instances: [healthy/issues]
- Backup coverage: [XX/12 current within 48h]
- EIP quota us-east-2: [XX/XX]
- New issues found: [count]

## Checklist Results

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Cost anomalies | PASS/FAIL | |
| 2 | Unassociated EIPs | PASS/FAIL | |
| 3 | Snapshot freshness | PASS/FAIL | |
| 4 | Daily cost spikes | PASS/FAIL | |
| 5 | Security group changes | PASS/FAIL | |
| 6 | Instance health | PASS/FAIL | |
| 7 | EIP quota | PASS/FAIL | |
| 8 | RI/SP expiry | PASS/FAIL | |
| 9 | Security advisories | PASS/FAIL | |
| 10 | S3 storage growth | PASS/FAIL | |
| 11 | PBX migration progress | [X/5 migrated] | |
| 12 | Stopped instances | PASS/FAIL | |

## Issues Found
[List any new issues]

## Remediation Progress
[Track progress on known issues from baseline]

## Next Actions
[Prioritized list for the coming month]
```
