# ICCI AWS Emergency Response Procedures

These procedures cover the most likely emergency scenarios for ICCI's AWS infrastructure. In all cases:

1. **Stay calm.** PBX outages feel urgent but panic causes mistakes.
2. **Read-only first.** Diagnose before acting. Do not modify anything until you understand the problem.
3. **Log everything.** All commands go to `~/Documents/claude-code/aws/audit-commands.log`.
4. **Communicate.** If client PBX systems are affected, document the timeline for the incident report.

---

## Emergency 1: PBX Instance Down (Status Check Failed)

**Symptoms:** Client reports phones not working. Unable to SSH to PBX. SIP registrations failing.

### Step 1: Confirm the Problem

```bash
# Check instance status (replace INSTANCE_ID and REGION)
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'InstanceStatuses[0].[InstanceState.Name,SystemStatus.Status,InstanceStatus.Status]' --output text

# If instance is running but status checks fail, get details
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'InstanceStatuses[0].[SystemStatus.Details,InstanceStatus.Details]'
```

### Step 2: Identify Which PBX

Cross-reference against fleet inventory:

| Client | Instance ID | Region | EIP |
|--------|------------|--------|-----|
| BayDesign | i-0449a85fc75e22cdc | us-east-1 | 18.211.103.202 |
| HealingPBX | i-0e6c60d8be50245b7 | us-east-2 | 18.220.233.90 |
| Praxis | i-0f5caf9b7b2802035 | us-east-2 | 18.218.6.250 |
| AAO | i-036f677b82ad1d49d | us-east-2 | 52.14.222.219 |
| Irani & Wise | i-06dad05c1b135be76 | us-east-2 | 3.22.184.229 |
| FCI | i-01b082fa7983654f2 | us-east-2 | 3.143.26.10 |
| SJD | i-0e8b687de485b7ed0 | us-east-2 | 3.17.119.119 |
| BLBC | i-0238d4e8408901737 | us-east-2 | 3.131.205.245 |
| icci | i-007cf0b2e89c134c2 | us-east-2 | 18.216.232.95 |
| WVH | i-06108abf84cc8c9c7 | us-east-2 | 3.136.1.208 |
| DDP | i-08e0b307d4d86fce7 | us-east-2 | 18.188.128.90 |
| FMT | i-0b960f7c26d457fba | us-east-2 | 3.13.128.184 |

### Step 3: Attempt Recovery

**If system status check failed (AWS hardware issue):**
```bash
# Stop and start the instance (NOT reboot -- stop/start moves to new hardware)
# WARNING: This requires explicit user approval
aws ec2 stop-instances --instance-ids <INSTANCE_ID> --region <REGION>
# Wait for stopped state
aws ec2 wait instance-stopped --instance-ids <INSTANCE_ID> --region <REGION>
# Start
aws ec2 start-instances --instance-ids <INSTANCE_ID> --region <REGION>
aws ec2 wait instance-running --instance-ids <INSTANCE_ID> --region <REGION>
```

**CRITICAL:** After stop/start, verify the EIP is still associated:
```bash
aws ec2 describe-addresses --region <REGION> \
  --filters "Name=instance-id,Values=<INSTANCE_ID>" \
  --query 'Addresses[0].PublicIp' --output text
```

If the EIP became disassociated, re-associate immediately (see Emergency 4).

**If instance status check failed (OS-level issue):**
```bash
# Try a reboot first (softer approach)
aws ec2 reboot-instances --instance-ids <INSTANCE_ID> --region <REGION>

# Wait 3-5 minutes, then check status
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID> --region <REGION>
```

If reboot does not resolve, try stop/start. If that fails, proceed to Step 4.

### Step 4: Restore from Snapshot

If the instance cannot be recovered:

```bash
# Find the most recent snapshot of the boot volume
BOOT_VOL=$(aws ec2 describe-instances --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName==`/dev/sda1`].Ebs.VolumeId' --output text)

aws ec2 describe-snapshots --filters "Name=volume-id,Values=$BOOT_VOL" --region <REGION> \
  --query 'Snapshots | sort_by(@, &StartTime) | [-3:].[SnapshotId,StartTime,State]' --output table
```

**Recovery options (require explicit approval):**

**Option A: Replace boot volume (fastest, same instance)**
1. Stop the instance
2. Detach the current boot volume
3. Create a new volume from the latest snapshot
4. Attach the new volume as /dev/sda1
5. Start the instance

**Option B: Launch new instance from snapshot (if instance is corrupt)**
1. Create AMI from the latest snapshot
2. Launch new instance from the AMI using the same instance type, security groups, and subnet
3. Disassociate EIP from old instance
4. Associate EIP with new instance
5. Verify phone registrations resume

### Step 5: Post-Incident

- Verify all phone extensions re-register
- Test inbound and outbound calls
- Check voicemail delivery
- Document the incident timeline
- Take a fresh manual snapshot once stable

---

## Emergency 2: Suspected Toll Fraud / SIP Abuse

**Symptoms:** Unusual call patterns, calls to international premium numbers, CDR showing unknown extensions, high concurrent call count, client reports unauthorized outbound calls.

### Step 1: Immediate Network Assessment

```bash
# Check CPU utilization spike (toll fraud causes high CPU from transcoding)
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Maximum --region <REGION>

# Check network traffic spike
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name NetworkOut \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Sum --region <REGION>
```

### Step 2: Isolate the System (requires explicit approval)

**CRITICAL DECISION POINT:** Isolating the PBX will stop ALL calls, including legitimate ones. Weigh this against ongoing fraud costs.

**Option A: Block outbound SIP (surgical -- stops fraud, keeps inbound working)**
- SSH to the PBX and disable outbound routes in FreePBX
- This is a PBX-level action, not an AWS action

**Option B: Restrict SIP at security group level (nuclear -- stops all SIP traffic)**
```bash
# Create a "SIP Emergency Block" SG that allows only icci management IPs
# Then replace VoIP SGs on the affected instance with the block SG
# This kills ALL SIP traffic (inbound and outbound calls stop)

# First, document current SGs
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' --output table

# Save the current SG list (you will need to restore this)
CURRENT_SGS=$(aws ec2 describe-instances --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' --output text | tr '\t' ' ')
echo "SAVED SGs for $INSTANCE_ID: $CURRENT_SGS" >> ~/Documents/claude-code/aws/audit-commands.log
```

### Step 3: Investigate on the PBX

SSH to the PBX and check:
- CDR (Call Detail Records) for unusual patterns
- Active SIP registrations (`asterisk -rx "sip show peers"` or `pjsip show endpoints`)
- Fail2Ban logs for brute-force attempts
- `/var/log/asterisk/full` for unauthorized REGISTER or INVITE attempts
- FreePBX Firewall / Responsive Firewall status

### Step 4: Contact SIP Trunk Provider

If toll fraud is confirmed:
- **Telnyx:** Contact immediately to freeze outbound international calling
- Document the timeframe and estimated fraudulent call volume
- Request CDR export from the trunk provider for the incident period

### Step 5: Remediate

Common remediation steps (require approval):
1. Change all SIP extension passwords
2. Disable compromised extensions
3. Enable Responsive Firewall if not already active
4. Review and restrict SangomaConnect SG if SIP TLS was the entry point
5. Add rate limiting for SIP registrations
6. Update Fail2Ban rules

### Step 6: Restore Service

```bash
# If SGs were modified for isolation, restore original SGs
aws ec2 modify-instance-attribute --instance-id <INSTANCE_ID> --groups $CURRENT_SGS --region <REGION>
```

### Step 7: Post-Incident

- Document the full incident timeline
- Calculate financial impact (fraud call charges)
- File claim with trunk provider if applicable
- Update security group rules to prevent recurrence
- Consider removing SangomaConnect SG from affected instance if not actively needed

---

## Emergency 3: Suspected Unauthorized AWS Access

**Symptoms:** Unexpected resource changes, unknown instances launched, SG rules modified, unfamiliar IAM activity.

### Step 1: Assess Scope

```bash
# Check recent API activity (if CloudTrail is enabled)
aws cloudtrail lookup-events --max-results 50 --region us-east-1 2>/dev/null
aws cloudtrail lookup-events --max-results 50 --region us-east-2 2>/dev/null

# If CloudTrail is NOT enabled (baseline state), check for evidence:

# New or modified instances
aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],LaunchTime,State.Name]' --output table
aws ec2 describe-instances --region us-east-2 --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],LaunchTime,State.Name]' --output table

# New security groups
aws ec2 describe-security-groups --region us-east-1 --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table
aws ec2 describe-security-groups --region us-east-2 --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table

# New IAM users or access keys
aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table

# New S3 buckets
aws s3api list-buckets --query 'Buckets[*].[Name,CreationDate]' --output table
```

### Step 2: Check for Crypto Mining

```bash
# Look for unusual instance types (GPU, large compute)
for region in us-east-1 us-east-2 us-west-1 us-west-2 eu-west-1; do
  count=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region $region --query 'length(Reservations[*].Instances[*])' --output text 2>/dev/null)
  if [ "$count" != "0" ] && [ "$count" != "None" ]; then
    echo "$region: $count running instances"
    aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region $region \
      --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,LaunchTime]' --output table
  fi
done
```

### Step 3: Contain (requires explicit approval)

**If root key compromise is suspected:**
1. **DO NOT delete the root keys immediately** -- you may need them for recovery
2. Create a new IAM admin user with MFA first
3. Then deactivate (not delete) the compromised root keys
4. Rotate all IAM access keys

```bash
# Deactivate root access key (ONLY after creating IAM admin user)
# aws iam update-access-key --access-key-id <KEY_ID> --status Inactive --user-name root

# List and deactivate all potentially compromised keys
for user in $(aws iam list-users --query 'Users[*].UserName' --output text); do
  for key in $(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[?Status==`Active`].AccessKeyId' --output text); do
    echo "Active key: $user / $key"
  done
done
```

### Step 4: Terminate Unauthorized Resources

```bash
# If unknown instances are found, terminate them (requires approval)
# aws ec2 terminate-instances --instance-ids <UNKNOWN_INSTANCE_IDS> --region <REGION>

# If unknown SGs were created, document and delete them
# aws ec2 delete-security-group --group-id <SG_ID> --region <REGION>
```

### Step 5: Enable Monitoring

If CloudTrail and GuardDuty are still not enabled, this incident makes enabling them an immediate priority:

```bash
# Enable CloudTrail (multi-region)
# aws cloudtrail create-trail --name icci-audit-trail --s3-bucket-name <BUCKET> --is-multi-region-trail
# aws cloudtrail start-logging --name icci-audit-trail

# Enable GuardDuty
# aws guardduty create-detector --enable --region us-east-1
# aws guardduty create-detector --enable --region us-east-2
```

### Step 6: Post-Incident

- Full audit of all resources across all regions
- Rotate ALL access keys
- Enable MFA on all accounts
- Enable CloudTrail and GuardDuty (if not already done)
- Document the incident for compliance/records
- Consider engaging AWS Support for forensic assistance

---

## Emergency 4: EIP Disassociation / Lost IP

**Symptoms:** PBX phones lose registration, client reports "no service", SIP trunk shows unreachable.

### Step 1: Verify EIP Status

```bash
# Check if the EIP is still allocated and associated
aws ec2 describe-addresses --public-ips <EXPECTED_EIP> --region <REGION> \
  --query 'Addresses[0].[PublicIp,AllocationId,InstanceId,AssociationId]' --output text

# If the IP is not found, it may have been released
# Check instance's current public IP
aws ec2 describe-instances --instance-ids <INSTANCE_ID> --region <REGION> \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,NetworkInterfaces[0].Association.PublicIp]' --output text
```

### Step 2: Re-associate EIP (requires approval)

```bash
# If EIP is allocated but not associated:
aws ec2 associate-address --instance-id <INSTANCE_ID> --allocation-id <ALLOCATION_ID> --region <REGION>

# Verify association
aws ec2 describe-addresses --allocation-ids <ALLOCATION_ID> --region <REGION> \
  --query 'Addresses[0].[PublicIp,InstanceId]' --output text
```

### Step 3: If EIP Was Released

**This is a serious situation.** Once an EIP is released, the IP address goes back to the AWS pool and cannot be recovered. All client phones, SIP trunks, and DNS records pointing to that IP are now broken.

Recovery options:
1. Allocate a new EIP
2. Update the client's SIP trunk provider with the new IP
3. Update DNS records (if any point to the PBX IP)
4. Update client phone configurations (provisioning URL, SIP registrar)
5. Update the icci PBXact 17 hub's IAX peer list if this PBX has IAX trunking
6. Update the VoIP Service Providers SG if this PBX's IP was referenced

**PREVENTION:** This is why EIP management is critical. Never release an EIP unless you are certain the client has been decommissioned.

---

## Emergency 5: EBS Volume Failure

**Symptoms:** Instance becomes unresponsive, I/O errors in logs, status check reports "impaired" for attached EBS.

### Step 1: Diagnose

```bash
# Check volume status
aws ec2 describe-volume-status --volume-ids <VOLUME_ID> --region <REGION>

# Check instance status
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID> --region <REGION>

# List recent events for the volume
aws ec2 describe-volume-status --volume-ids <VOLUME_ID> --region <REGION> \
  --query 'VolumeStatuses[0].Events'
```

### Step 2: Find the Latest Snapshot

```bash
# Get the 3 most recent snapshots for this volume
aws ec2 describe-snapshots --filters "Name=volume-id,Values=<VOLUME_ID>" --region <REGION> \
  --query 'Snapshots | sort_by(@, &StartTime) | [-3:].[SnapshotId,StartTime,State,VolumeSize]' --output table
```

### Step 3: Create Replacement Volume (requires approval)

```bash
# Create new volume from latest snapshot
aws ec2 create-volume --snapshot-id <SNAPSHOT_ID> --availability-zone <AZ> \
  --volume-type gp3 --encrypted --region <REGION> \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value="<Name> Replacement"},{Key=Backup,Value="30"}]'

# Wait for volume to become available
aws ec2 wait volume-available --volume-ids <NEW_VOLUME_ID> --region <REGION>
```

### Step 4: Swap Volumes (requires approval)

```bash
# Stop the instance
aws ec2 stop-instances --instance-ids <INSTANCE_ID> --region <REGION>
aws ec2 wait instance-stopped --instance-ids <INSTANCE_ID> --region <REGION>

# Detach failed volume
aws ec2 detach-volume --volume-id <FAILED_VOLUME_ID> --region <REGION>
aws ec2 wait volume-available --volume-ids <FAILED_VOLUME_ID> --region <REGION>

# Attach replacement volume
aws ec2 attach-volume --volume-id <NEW_VOLUME_ID> --instance-id <INSTANCE_ID> \
  --device /dev/sda1 --region <REGION>

# Start the instance
aws ec2 start-instances --instance-ids <INSTANCE_ID> --region <REGION>
aws ec2 wait instance-running --instance-ids <INSTANCE_ID> --region <REGION>
```

### Step 5: Verify Recovery

```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID> --region <REGION>

# Verify EIP still associated
aws ec2 describe-addresses --region <REGION> \
  --filters "Name=instance-id,Values=<INSTANCE_ID>" \
  --query 'Addresses[0].PublicIp' --output text
```

- SSH to the instance and verify services are running
- Check FreePBX/Asterisk is operational
- Test inbound and outbound calls
- Verify voicemail

---

## Emergency 6: Regional Outage Response

**Symptoms:** Multiple instances unreachable simultaneously, AWS status page shows us-east-2 issues, multiple client PBX systems down.

### Step 1: Confirm Regional Outage

```bash
# Check AWS status
# Web: https://health.aws.amazon.com/health/status

# Try to query the region
aws ec2 describe-instance-status --region us-east-2 --query 'InstanceStatuses[0].AvailabilityZone' --output text

# Check if it is an AZ-specific issue
aws ec2 describe-instance-status --region us-east-2 \
  --query 'InstanceStatuses[*].[InstanceId,AvailabilityZone,SystemStatus.Status]' --output table
```

### Step 2: Assess Impact

**If us-east-2b goes down (worst case -- 10 PBX systems affected):**

| PBX | Client | Impact |
|-----|--------|--------|
| HealingPBXact | HealingPBX | Phones down |
| Praxis PBX | Praxis Properties | Phones down |
| AAO PBX | Ann Arbor Observer | Phones down |
| IraniWise PBX | Irani & Wise | Phones down |
| FCI PBX | Financial Concepts | Phones down |
| SJD PBX 17 | St. Joseph Dexter | Phones down |
| BLBC PBX 17 | BLBC | Phones down |
| icci PBXact 17 | icci, LLC | ICCI's own phones down + IAX hub down |
| WVH PBX 17 | WVH | Phones down |
| DDP PBX 17 | Dahlmann Properties | Phones down |

**NOT affected (different AZ/region):**
- BayDesign PBX (us-east-1d)
- FMT Reports4u (us-east-2a)
- Maeslantkering (us-east-2c)

### Step 3: During Outage

**There is very little you can do during a regional/AZ outage:**
1. Monitor AWS status page for updates
2. Communicate with clients: "AWS is experiencing an outage in our hosting region. Phone service will be restored as soon as AWS resolves the issue."
3. Consider forwarding critical client numbers to cell phones if their carrier supports it
4. Document the timeline for the incident report

### Step 4: Post-Outage Recovery

Once the AZ/region recovers:
1. Verify all instances restarted automatically
2. Check EIP associations (EIPs are region-scoped, should survive AZ outage)
3. Verify SIP registrations resume
4. Test calls for each client
5. Check DLM snapshots resume

### Step 5: Post-Incident Action

This is the strongest justification for the AZ distribution project:
- Create telephony subnets in us-east-2a and us-east-2c
- Redistribute PBX instances across 3 AZs
- No single AZ failure should take down more than 4 PBX systems
- EIPs are region-scoped so they follow the instance across AZs

---

## Emergency 7: DLM Policy Failure (Missing Snapshots)

**Symptoms:** Routine monthly check reveals PBX volumes without recent snapshots. DLM policy may be disabled or malfunctioning.

### Step 1: Check DLM Policy Status

```bash
# List all DLM policies and their state
aws dlm get-lifecycle-policies --region us-east-2
aws dlm get-lifecycle-policies --region us-east-1

# Get detailed policy info
aws dlm get-lifecycle-policy --policy-id policy-06d6903012adad4de --region us-east-2
aws dlm get-lifecycle-policy --policy-id policy-001c298230ee72b32 --region us-east-1
```

### Step 2: Identify Gaps

```bash
# Find volumes tagged Backup=30 with no snapshot in last 48 hours
THRESHOLD=$(date -u -v-48H +%Y-%m-%dT%H:%M:%S)

for vol in $(aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region us-east-2 --query 'Volumes[*].VolumeId' --output text); do
  name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$vol" "Name=key,Values=Name" --region us-east-2 --query 'Tags[0].Value' --output text)
  latest=$(aws ec2 describe-snapshots --filters "Name=volume-id,Values=$vol" --region us-east-2 \
    --query 'Snapshots | sort_by(@, &StartTime) | [-1].StartTime' --output text)

  if [ "$latest" = "None" ] || [ -z "$latest" ]; then
    echo "CRITICAL: $vol ($name) -- NO SNAPSHOTS EXIST"
  elif [[ "$latest" < "$THRESHOLD" ]]; then
    echo "STALE: $vol ($name) -- last snapshot $latest"
  else
    echo "OK: $vol ($name) -- $latest"
  fi
done
```

### Step 3: Remediate

**If DLM policy is DISABLED:**
```bash
# Re-enable the policy (requires approval)
# aws dlm update-lifecycle-policy --policy-id <POLICY_ID> --state ENABLED --region <REGION>
```

**If DLM policy is ENABLED but not creating snapshots:**
- Check the target tag matches volume tags exactly (case-sensitive)
- Check the IAM role used by DLM still exists and has proper permissions
- Check for DLM errors in CloudWatch (if CloudWatch integration exists)

**If a volume lost its Backup tag:**
```bash
# Re-tag the volume (requires approval)
# aws ec2 create-tags --resources <VOLUME_ID> --tags Key=Backup,Value=30 --region <REGION>
```

### Step 4: Manual Snapshot (if needed)

If a PBX volume has gone more than 48 hours without a snapshot, take a manual one immediately:

```bash
# Create manual snapshot (requires approval)
# aws ec2 create-snapshot --volume-id <VOLUME_ID> --description "Emergency manual snapshot $(date -u +%Y-%m-%d) - DLM failure" --region <REGION>
```

### Step 5: Post-Incident

- Verify DLM policy is running on schedule
- Check all volumes have Backup tags
- Set a reminder to verify snapshot freshness again in 24 hours
- Consider enabling CloudWatch alarms for DLM policy failures (if CloudWatch is available)

---

## Incident Report Template

```markdown
# ICCI AWS Incident Report

**Incident Type:** [PBX Down / Toll Fraud / Unauthorized Access / EIP Lost / Volume Failure / Regional Outage / DLM Failure]
**Affected Client(s):** [Client name(s)]
**Affected Instance(s):** [Instance ID(s)]
**Severity:** [Critical / High / Medium]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| YYYY-MM-DD HH:MM | Issue detected / reported |
| YYYY-MM-DD HH:MM | Diagnosis started |
| YYYY-MM-DD HH:MM | Root cause identified |
| YYYY-MM-DD HH:MM | Remediation action taken |
| YYYY-MM-DD HH:MM | Service restored |
| YYYY-MM-DD HH:MM | Post-incident verification complete |

## Root Cause
[Description of what caused the incident]

## Impact
- Duration of outage: [X minutes/hours]
- Clients affected: [X of 12]
- Services affected: [inbound calls / outbound calls / voicemail / all]
- Estimated financial impact: [$X if toll fraud]

## Actions Taken
1. [Action 1]
2. [Action 2]
3. [Action 3]

## Prevention
[What changes will prevent this from happening again]

## Commands Executed
[List all AWS CLI commands run during the incident, from audit-commands.log]
```
