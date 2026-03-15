---
name: icci-aws
license: Proprietary. ICCI LLC Internal Use Only. LICENSE.txt has complete terms.
description: "Manage ICCI's AWS infrastructure — 12 PBXact/FreePBX telephone systems, Plesk web hosting, and supporting services across us-east-1 and us-east-2. Use this skill for AWS audits, cost optimization, security reviews, PBX fleet management, instance provisioning, backup verification, and infrastructure changes. Trigger when the user mentions AWS, EC2, PBX fleet, cost optimization, or ICCI infrastructure."
user-invocable: true
argument-hint: "[task description]"
---

# ICCI AWS Infrastructure Skill

You are managing ICCI's AWS infrastructure -- a managed services provider (MSP) in Ann Arbor/Brighton, Michigan that hosts PBXact/FreePBX telephone systems on AWS for clients including schools, veterinary hospitals, and small businesses. Owner: Aaron. This skill gives you everything needed to audit, monitor, maintain, and provision infrastructure in this account.

> **This file contains infrastructure details.** Do not commit this skill directory to any public repository. When distributing to team members, share directly -- never through public channels.

## Critical Rules

1. **READ-ONLY for audits.** Only use describe/list/get API calls during audit operations. Never modify resources without explicit user approval.
2. **Log ALL CLI commands.** Append every AWS CLI command to `~/Documents/claude-code/aws/audit-commands.log` with a timestamp.
3. **Never modify resources without explicit user approval.** Describe the planned change, its impact, and get a clear "yes" before executing any mutating call.
4. **Redact secret keys.** When displaying access keys, show only the last 4 characters (e.g., `****ABCD`). Never display full secret access keys in output.
5. **Think like an MSP.** Downtime affects real businesses -- schools miss calls, veterinary hospitals miss emergencies, property managers miss tenants. Every action must weigh operational risk.
6. **Always check BOTH us-east-1 AND us-east-2.** Resources are split across regions. An audit of only one region is incomplete.
7. **Reports go to `~/Documents/claude-code/aws/`.** Use markdown format. For audits, follow the structure in `references/audit-checklist.md`.
8. **ALWAYS sync this skill to the GitHub repository** after any modifications. When you edit any file in this skill (SKILL.md or anything in `references/` or `scripts/`), copy the updated files to `~/Documents/GitHub/icci-skills/skills/icci-aws/` so the repository always contains the latest version. Both locations must stay identical.

## Quick Reference

| Item | Value |
|------|-------|
| **AWS Account ID** | 406551117454 |
| **Account Access** | Root (CLI via access keys -- see Known Issues) |
| **Primary PBX Region** | us-east-2 (Ohio) -- 11 of 12 PBX instances |
| **Secondary Region** | us-east-1 (N. Virginia) -- 1 PBX + Plesk + ScreenConnect + UniFi |
| **Active PBX Instances** | 12 |
| **Total EC2 Instances** | 20 (16 running, 4 stopped) |
| **Standard PBX Instance Type** | t3a.medium (2 vCPU, 4 GB RAM) |
| **Standard PBX OS** | Debian 12 (Bookworm) with PBXact 17 |
| **Standard PBX Boot Volume** | 60 GB gp3, encrypted |
| **Standard PBX Swap Volume** | 8 GB gp3, Backup=FALSE |
| **Golden Master AMI** | ami-053390076aa21e8f0 (pbxact17-gm-debian12-24FEB26) |
| **Launch Template** | icciDebianForPBX (us-east-2) |
| **Backup Tag** | `Backup=30` on boot volumes, `Backup=FALSE` on swap |
| **DLM Policy (us-east-2)** | policy-06d6903012adad4de -- Daily 07:22 UTC + Monthly 1st Mon 05:22 UTC, retains 7 daily + 3 monthly |
| **DLM Policy (us-east-1, 30d)** | policy-001c298230ee72b32 -- Mon/Wed/Fri 07:22 UTC, retains 12 snapshots |
| **DLM Policy (us-east-1, 6wk)** | policy-06083753933c6ef82 -- Tue 09:00 UTC, retains 6 snapshots |
| **Monthly Spend (baseline)** | ~$714/mo (Feb 2026) |
| **Savings Plans** | Compute SP $0.06/hr (expires 2026-12-16), EC2 t3a SP $0.16/hr us-east-2 (expires 2026-12-19) |
| **Reserved Instances (us-east-1)** | c5a.large (expires 2026-04-15), 2x t3a.medium (expire 2026-12-19), m5a.xlarge (expires 2027-10-22) |
| **EIP Quota us-east-1** | 6/10 (60%) |
| **EIP Quota us-east-2** | 15/15 (100% -- CRITICAL) |
| **S3 Buckets** | 7 total, 305 GB, ~$2.35/mo |
| **Route 53 Hosted Zones** | 1 (praxisproperties.com) |
| **VPCs** | us-east-1: icciServiceNet (172.16.42.0/24), icciVoIP-east (172.22.48.0/22). us-east-2: icci-east-2 (172.31.0.0/16, default VPC) |
| **Telephony Subnets** | icciTel-2b (172.22.33.0/24), icciTel-2b-501c3 (172.22.34.0/24) -- BOTH us-east-2b only |
| **Key Security Groups** | icci LLC Backdoor (management IPs), VoIP Service Providers (Telnyx trunk IPs), SangomaConnect (mobile + SIP TLS open to world) |
| **CloudTrail** | NOT enabled |
| **GuardDuty** | NOT enabled |
| **CloudWatch Alarms** | NONE |
| **SSM Agent** | NOT installed on any instance |
| **AWS Support Tier** | Developer ($29/mo) |
| **Report Output** | `~/Documents/claude-code/aws/` |
| **Command Log** | `~/Documents/claude-code/aws/audit-commands.log` |

## PBXact Fleet Inventory

### Active PBX Instances (12 systems)

| # | Instance ID | Name | Client | Region/AZ | Type | OS | PBX Ver | EIP |
|---|-------------|------|--------|-----------|------|----|---------|-----|
| 1 | i-0449a85fc75e22cdc | BayDesign PBX | Bay Design Store | us-east-1d | c5a.large | CentOS 7 (EOL) | 16 | 18.211.103.202 |
| 2 | i-0e6c60d8be50245b7 | HealingPBXact | HealingPBX | us-east-2b | t2.medium | SNG7 (EOL) | 16 | 18.220.233.90 |
| 3 | i-0f5caf9b7b2802035 | Praxis PBX | Praxis Properties | us-east-2b | t3a.medium | SNG7 (EOL) | 16 | 18.218.6.250 |
| 4 | i-036f677b82ad1d49d | AAO PBX | Ann Arbor Observer | us-east-2b | t3a.medium | Debian 12 | 16* | 52.14.222.219 |
| 5 | i-06dad05c1b135be76 | IraniWise PBX | Irani & Wise | us-east-2b | t3a.medium | SNG7 (EOL) | 16 | 3.22.184.229 |
| 6 | i-01b082fa7983654f2 | FCI PBX | Financial Concepts | us-east-2b | t3a.medium | SNG7 (EOL) | 16 | 3.143.26.10 |
| 7 | i-0e8b687de485b7ed0 | SJD PBX 17 | St. Joseph Dexter | us-east-2b | t3a.medium | Debian 12 | 17 | 3.17.119.119 |
| 8 | i-0238d4e8408901737 | BLBC PBX 17 | BLBC | us-east-2b | t3a.medium | Debian 12 | 17 | 3.131.205.245 |
| 9 | i-007cf0b2e89c134c2 | icci PBXact 17 | icci, LLC | us-east-2b | t3a.medium | Debian 12 | 17 | 18.216.232.95 |
| 10 | i-06108abf84cc8c9c7 | WVH PBX 17 | WVH (Washtenaw Co.) | us-east-2b | t3a.medium | Debian 12 | 17 | 3.136.1.208 |
| 11 | i-08e0b307d4d86fce7 | DDP PBX 17 | Dahlmann Properties | us-east-2b | t3a.medium | Debian 12 | 17 | 18.188.128.90 |
| 12 | i-0b960f7c26d457fba | FMT Reports4u | White Cap - Form Tech | us-east-2a | t3a.small | Debian 12 | N/A** | 3.13.128.184 |

\* AAO PBX rebuilt on Debian 12 in Dec 2025 but may still run PBXact 16.
\** FMT Reports4u has no VoIP security groups, no IAX peering, and 0.1% CPU avg -- likely a reporting server, not a PBX.

### Non-PBX Instances (4 running)

| Instance ID | Name | Region/AZ | Type | Purpose |
|-------------|------|-----------|------|---------|
| i-065a0a494ccd320f5 | SC-Windows-FEB24 | us-east-1d | t3a.medium | ScreenConnect remote support |
| i-0193b6c43e6c1a146 | UniFi Ubuntu 20 LTS | us-east-1d | t3a.medium | UniFi network controller |
| i-0641b18aabb6968b7 | web1 Plesk | us-east-1a | m5a.xlarge | Plesk web hosting (pigboats.com etc.) |
| i-06b879aba99d0ac53 | Maeslantkering | us-east-2c | t3a.small | Utility server |

### Stopped Instances (4)

| Instance ID | Name | Type | Status | Action |
|-------------|------|------|--------|--------|
| i-00250861fe908cc1c | DDP PBX (OLD) | t2.medium | Stopped | Safe to terminate -- replaced by DDP PBX 17 |
| i-09d822ecbadc95bb4 | icci UNMS | t3a.small | Stopped since 2025-12-16 | Evaluate for termination |
| i-09d0a264466d68d0b | CentOS7-recovery | t3a.medium | Stopped | Safe to terminate -- ancient, CentOS 7 EOL |
| i-096cc133db680ea1f | icciPBX17 Feb26 GM | t3a.medium | Stopped | KEEP -- gold master image |

### Decommissioned Clients (former PBX systems, no longer in account)

| Former Client | Former IP | Evidence |
|---------------|-----------|----------|
| Formtech | 18.220.191.128 | IAX peer in icci SG; EIP released |
| Batteries Plus | 18.220.235.94 | IAX peer in icci SG; EIP released |
| Woodland Sales | 18.220.25.72 | IAX peer in icci SG; EIP released |
| Oxford VP | 3.140.106.48 | IAX peer in icci SG; EIP released |

## Known Issues / Baseline (as of March 2026)

### CRITICAL

| Issue | Detail | Remediation Status |
|-------|--------|--------------------|
| Root access keys (12 years old) | 2 active root keys; Key 1 dormant since 2015, Key 2 in active use. Full account compromise risk if leaked. | NOT STARTED -- need IAM admin user w/ MFA first |
| No CloudTrail | Zero audit trail. Cannot investigate security incidents. No API call logging anywhere. | NOT STARTED |
| No GuardDuty | Zero threat detection. No alerts for compromised instances, crypto mining, toll fraud, or brute-force attacks. | NOT STARTED |
| All PBX in us-east-2b (single AZ) | 10 of 11 us-east-2 PBX instances in one AZ. AZ outage takes down entire fleet simultaneously. | NOT STARTED -- requires telephony subnets in 2a/2c |
| EIP quota 100% in us-east-2 | 15/15 EIPs allocated. Cannot deploy new PBX or redistribute across AZs without quota increase. | NOT STARTED -- request increase to 20-25 |
| No cross-region backups | All snapshots in same region as source. Regional outage loses production AND backups. | NOT STARTED |

### HIGH

| Issue | Detail | Remediation Status |
|-------|--------|--------------------|
| SIP 5061 open to world on 9/12 PBX | SangomaConnect SG opens TCP 5061 to 0.0.0.0/0 on 9 PBX instances. Primary toll fraud attack vector. | NOT STARTED -- evaluate if SangomaConnect is actively used on all 9 |
| WVH triple SIP exposure | WVH PBX 17 has OPEN SIP + SangomaConnect + VoIP Providers. OPEN SIP adds UDP 5060 to world unnecessarily. | NOT STARTED -- remove OPEN SIP SG from WVH |
| Zero CloudWatch alarms | No alerting on status check failures, CPU spikes, or disk exhaustion. Outages detected only by user complaints. | NOT STARTED |
| CentOS 7 EOL on 5 instances | BayDesign (CentOS 7), HealingPBXact, Praxis, IraniWise, FCI (all SNG7/CentOS 7). EOL since June 2024, no security patches. | IN PROGRESS -- PBXact 16->17 migration underway |
| 0/36 IAM users have MFA | All administrative work done via root. No second factor on any service account key. | NOT STARTED |
| All access keys >90 days old | 36 IAM users, all keys 2-12 years old. Many dormant. | NOT STARTED |
| No SSM agent on any instance | Cannot manage fleet at scale. Manual SSH to each instance required for all operations. | NOT STARTED |
| No VPC Flow Logs | No network traffic visibility. Cannot detect SIP scanning or brute-force attempts at network level. | NOT STARTED |
| No AWS Config | No configuration change tracking or compliance evaluation. | NOT STARTED |

### MEDIUM

| Issue | Detail |
|-------|--------|
| 7 unencrypted EBS volumes (swap) | 8 GB /dev/sdb volumes on PBX 17 instances in us-east-2 |
| EBS encryption-by-default not enabled | New volumes will be unencrypted unless explicitly specified |
| No S3 bucket versioning | Accidental deletion unrecoverable on all 7 buckets |
| 2 KMS customer keys without rotation | key 1515eb4e and ebcc2e99 in us-east-2 |
| 23 unused security groups | Clutter; includes dangerous "EEK - NO FIREWALL" and "SSH from everywhere" |
| Inconsistent tagging | Mix of `customer` vs `CLIENT`; no Environment/Owner/CostCenter tags |
| SSH open to world on Maeslantkering | Maeslantkering Custom SG has SSH 0.0.0.0/0 on a running instance |
| Monthly spend ~$714 with ~$150-200/mo savings available | See Cost Monitoring section |

## Cost Monitoring Thresholds

Based on the February 2026 baseline ($714/mo):

| Cost Category | Baseline/Mo | Alert Threshold | Notes |
|---------------|------------|-----------------|-------|
| **Monthly total** | ~$714 | >$850 | Investigate any month over $850 |
| **EC2 compute (on-demand)** | ~$154 | >$200 | Spike may indicate new unplanned instances |
| **EBS snapshots** | ~$144 | >$180 | Growth indicates snapshot retention creep or new large volumes |
| **Public IPv4 (EIPs)** | ~$70 | Decreases expected | Should drop as stopped instances are terminated and unused EIPs released |
| **Data transfer** | ~$43 | >$65 | Spike may indicate DDoS or unusual web traffic |
| **Savings Plans committed** | ~$148 | Fixed | $0.06/hr + $0.16/hr committed; check utilization quarterly |
| **S3 storage** | ~$2.35 | >$10 | Watch wvh-call-recordings-feb26 growth |
| **AWS Support** | $29 | Fixed | Developer tier |

### Top Savings Opportunities

| Action | Est. Savings/Mo | Effort | Risk |
|--------|----------------|--------|------|
| Delete unattached EBS vol-042e61ad56699071c | $6.00 | 5 min | None |
| Release 2 unassociated EIPs | $7.00 | 5 min | None |
| Terminate DDP PBX (OLD) + release EIP | $8.30 | 15 min | None (replaced by DDP PBX 17) |
| Reduce DLM retention on 1200 GB + 1024 GB volumes | $30-50 | 30 min | Low |
| Convert 4 gp2 volumes to gp3 | $2.52 | 30 min | None (online, no downtime) |
| Terminate icci UNMS + release EIP | $5.90 | 15 min | Low (evaluate first) |
| Migrate BayDesign from c5a.large to t3a.medium (after RI expires Apr 15) | $20-28 | 4-6 hrs | Medium |
| Migrate HealingPBXact from t2.medium to t3a.medium | $6-8 | 4-6 hrs | Medium |
| **Total achievable** | **$86-116** | | |

### RI/SP Expiry Timeline

| Date | Reservation | Action Needed |
|------|------------|---------------|
| **2026-04-15** | c5a.large RI (us-east-1) | DO NOT RENEW -- migrate BayDesign to t3a.medium |
| 2026-12-16 | Compute SP ($0.06/hr) | Evaluate renewal based on fleet size |
| 2026-12-19 | EC2 Instance SP t3a us-east-2 ($0.16/hr) | Evaluate renewal; consider increasing commitment |
| 2026-12-19 | 2x t3a.medium RI (us-east-1) | Evaluate renewal for UniFi + SC-Windows/future |
| 2027-10-22 | m5a.xlarge RI (us-east-1) | No action -- covers web1 Plesk through Oct 2027 |

## Standard Operations

### Launching a New PBX Instance

1. **Pre-flight checks:**
   ```bash
   # Check EIP quota in target region (us-east-2 is at 100% -- request increase first)
   aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-2
   # Check available subnets
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-693eff00" --region us-east-2 --query 'Subnets[*].[SubnetId,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table
   ```

2. **Launch from GM using launch template:**
   ```bash
   aws ec2 run-instances \
     --launch-template LaunchTemplateName=icciDebianForPBX \
     --instance-type t3a.medium \
     --subnet-id <target-subnet> \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="<CLIENT> PBX 17"},{Key=customer,Value="<Client Name>"},{Key="PBX Version",Value="17"},{Key=Backup,Value="30"},{Key=Environment,Value=production}]' \
     --region us-east-2
   ```

3. **Post-launch:**
   - Allocate and associate EIP (or reassign existing)
   - Attach security groups: icci LLC Backdoor + VoIP Service Providers + SangomaConnect (if needed) + per-client Custom SG
   - Tag boot volume: `Name=<Client> PBX 17 Boot`, `Backup=30`
   - Tag swap volume: `Name=<Client> PBX 17 Swap`, `Backup=FALSE`
   - Verify DLM snapshot picks up the new volume within 24 hours
   - SSH in, configure FreePBX, set up trunks, register extensions

### Migrating PBXact 16 to 17

This is the standard procedure for moving a CentOS 7/SNG7 PBX to Debian 12/PBXact 17:

1. **Pre-migration:**
   - Take a manual EBS snapshot of the source PBX boot volume (safety net)
   - Export PBX config from the FreePBX GUI (Backup & Restore module) or `fwconsole backup`
   - Document current EIP, security groups, and tags
   - Notify client of maintenance window (typically 30-60 minutes of downtime)

2. **Build new instance:**
   - Launch new t3a.medium from latest Debian 12 GM AMI (ami-053390076aa21e8f0)
   - Apply all standard security groups + client-specific custom SG
   - Tag properly (see launch procedure above)
   - SSH in, restore FreePBX config from backup
   - Test: inbound calls, outbound calls, voicemail, IVR, ring groups, time conditions

3. **Cutover:**
   - Stop old PBX instance
   - Disassociate EIP from old instance
   - Associate same EIP with new instance (preserves all client phone registrations and trunk configs)
   - Verify phones re-register to new instance
   - Monitor for 24-48 hours

4. **Cleanup:**
   - After 7-14 days of stable operation, take final snapshot of old instance
   - Terminate old instance
   - Tag old snapshot as archive: `Name=<Client> PBX16 Archive <date>`

### Checking Backup Status

```bash
# List all volumes with Backup=30 tag and their latest snapshots (us-east-2)
aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region us-east-2 \
  --query 'Volumes[*].[VolumeId,Tags[?Key==`Name`].Value|[0],Size,State,Attachments[0].InstanceId]' --output table

# Check most recent snapshot per volume
for vol in $(aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region us-east-2 --query 'Volumes[*].VolumeId' --output text); do
  echo "=== $vol ==="
  aws ec2 describe-snapshots --filters "Name=volume-id,Values=$vol" --region us-east-2 \
    --query 'Snapshots | sort_by(@, &StartTime) | [-1].[SnapshotId,StartTime,State]' --output text
done

# Same for us-east-1
for vol in $(aws ec2 describe-volumes --filters "Name=tag:Backup,Values=30" --region us-east-1 --query 'Volumes[*].VolumeId' --output text); do
  echo "=== $vol ==="
  aws ec2 describe-snapshots --filters "Name=volume-id,Values=$vol" --region us-east-1 \
    --query 'Snapshots | sort_by(@, &StartTime) | [-1].[SnapshotId,StartTime,State]' --output text
done

# Check DLM policy health
aws dlm get-lifecycle-policies --region us-east-2
aws dlm get-lifecycle-policies --region us-east-1
```

### Cost Review

```bash
# Current month's cost by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# 3-month trend
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-3m +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost

# Savings Plans utilization
aws ce get-savings-plans-utilization \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY

# RI coverage check
aws ec2 describe-reserved-instances --filters "Name=state,Values=active" --region us-east-1
aws ec2 describe-reserved-instances --filters "Name=state,Values=active" --region us-east-2
aws savingsplans describe-savings-plans --query 'SavingsPlans[?State==`active`]'
```

### Security Group Audit

```bash
# Find SGs with 0.0.0.0/0 inbound rules (us-east-2)
aws ec2 describe-security-groups --region us-east-2 \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName,Description]' --output table

# Same for us-east-1
aws ec2 describe-security-groups --region us-east-1 \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName,Description]' --output table

# Check which SGs are attached to running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],SecurityGroups[*].[GroupId,GroupName]]' --output json

# Find unattached SGs
aws ec2 describe-security-groups --region us-east-2 --query 'SecurityGroups[*].GroupId' --output text | tr '\t' '\n' | while read sg; do
  count=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$sg" --region us-east-2 --query 'length(NetworkInterfaces)')
  if [ "$count" = "0" ]; then echo "UNATTACHED: $sg"; fi
done
```

## Security Group Architecture

Each PBX instance follows a layered security group model:

| Layer | SG Name | Purpose | Scope |
|-------|---------|---------|-------|
| 1 | icci LLC Backdoor | Management access from 4 ICCI office IPs | ALL instances |
| 2 | VoIP Service Providers | Telnyx SIP trunk IPs (192.76.120.10/32, 64.16.250.10/32) + media subnets | Most PBX instances |
| 3 | SangomaConnect | Sangoma/Acrobits mobile relay servers + SIP TLS 5061 open to world + RTP 10000-20000 open to world | 9 of 12 PBX (known issue) |
| 4 | Per-PBX Custom | Client office IPs (all traffic), OpenVPN, UCP, HTTPS provisioning, Let's Encrypt | One per PBX |
| 5 | Additional (varies) | SipStation (on icci, IraniWise), OPEN SIP (on WVH -- should be removed), AAO-specific | Select instances |

**Security group IDs (us-east-2):**
- icci LLC Backdoor: sg-a02d5cc9
- VoIP Service Providers: sg-3c86f955
- SangomaConnect: sg-0ba27c0ff14b4d65d
- OPEN SIP: sg-e787a98f (attached only to WVH -- remove this)
- EEK - NO FIREWALL: sg-02c47ceb39ffc4170 (unattached -- delete this)

**Security group IDs (us-east-1):**
- VoIP icci LLC ONLY: sg-0c99281908452d37d
- VoIP Service Providers: sg-023d35719b54101d3
- VoIP SangomaConnect: sg-0917f63bffa21b42b
- VoIP EEK-NO FIREWALL: sg-04c38db510f0124d7 (unattached -- delete this)

## PBX-to-Security-Group Mapping

```
                           Backdoor  VoIP-Prov  SangConn  Custom-SG  SipStation  OPEN-SIP
BayDesign PBX (e1)         icci-ONLY  VoIP-Prov  SangConn  BD-Custom      --        --
HealingPBXact              Backdoor   VoIP-Prov    --      Healing-C      --        --
Praxis PBX                 Backdoor   VoIP-Prov    --      Praxis-C       --        --
AAO PBX                    Backdoor   VoIP-Prov  SangConn  AAO-Custom     --        --
IraniWise PBX              Backdoor   VoIP-Prov  SangConn  IW-Custom    SipStn      --
FCI PBX                    Backdoor   VoIP-Prov  SangConn  FCI-Custom     --        --
SJD PBX 17                 Backdoor   VoIP-Prov  SangConn  STJOS-C        --        --
BLBC PBX 17                Backdoor   VoIP-Prov  SangConn  BLBC-Custom    --        --
icci PBXact 17             Backdoor   VoIP-Prov  SangConn  icci-Custom  SipStn      --
WVH PBX 17                 Backdoor   VoIP-Prov  SangConn  WVH-Custom     --      OPEN-SIP
DDP PBX 17                 Backdoor   VoIP-Prov  SangConn  DDP-Custom     --        --
FMT Reports4u              Backdoor     --         --      FT-Tight       --        --
```

## OS Migration Status

| OS | Count | Instances | Status |
|----|-------|-----------|--------|
| Debian 12 (current) | 7 | SJD, BLBC, icci, WVH, DDP, AAO, FMT | Current -- supported through June 2028 |
| SNG7 / CentOS 7 (EOL) | 4 | HealingPBXact, Praxis, IraniWise, FCI | **EOL since June 2024** -- migrate to Debian 12 |
| CentOS 7 (EOL) | 1 | BayDesign PBX | **EOL since June 2024** -- migrate to Debian 12 |

**Migration priority order:**
1. BayDesign PBX -- CentOS 7 + c5a.large (over-provisioned) + RI expires Apr 15
2. HealingPBXact -- SNG7 + t2.medium (legacy instance type) + deregistered AMI
3. Praxis PBX -- oldest running PBX (Dec 2020) + deregistered AMI
4. IraniWise PBX -- SNG7 + deregistered AMI
5. FCI PBX -- SNG7 + deregistered AMI

## Golden Master AMIs

| AMI ID | Name | Created | Used By |
|--------|------|---------|---------|
| ami-053390076aa21e8f0 | pbxact17-gm-debian12-24FEB26 | 2026-02-25 | DDP PBX 17 (latest) |
| ami-05486b7df94762930 | pbxact17-gm-debian12-22FEB26 | 2026-02-22 | WVH PBX 17 |
| ami-0be990232fa7ea85a | Debian12_Base_PBXact17Plus_Optimized_19JAN25 | 2025-01-19 | BLBC PBX 17 |
| ami-0de626b5d55a64111 | SNG7-PBX16-64bit-2306-1-JUL24 | 2024-07-27 | (reference, SNG7) |

Always use the latest GM AMI for new deployments. Currently: **ami-053390076aa21e8f0** (2026-02-25).

## S3 Buckets

| Bucket | Size | Storage Class | Lifecycle | Purpose |
|--------|------|--------------|-----------|---------|
| cloudberry.0001 | 230.8 GB | Standard -> Glacier (14d) | Yes | CloudBerry backups |
| iccillc.cbm.oxford2015 | 21.0 GB | Standard -> Glacier (14d) | Yes | CBM backups |
| iccillc.ec2.freepbx-first | 0 | N/A | No | Empty -- consider deleting |
| iccillc.pbxupdate.utility | 4.9 GB | Standard | No | PBX upgrade files |
| iccillc.plesk.deeparchive.jan25 | 5.5 GB | Standard (should be Glacier DA) | No | Plesk archive (mislabeled) |
| iccillc.plesk.okf.org | 22.4 GB | Mixed | No | OKF backups (has stale multipart uploads) |
| wvh-call-recordings-feb26 | 0 | N/A | No | WVH call recordings (needs lifecycle policy) |

## Reporting

All reports go to `~/Documents/claude-code/aws/` in markdown format.

**Audit reports** should follow the structure in `references/audit-checklist.md` and cover all 5 phases:
1. Cost Optimization
2. Security
3. Architecture & Reliability
4. Operations
5. PBXact Fleet

**Monthly maintenance** reports should follow `references/monthly-maintenance.md`.

**Command logging:** Every AWS CLI command executed must be appended to `~/Documents/claude-code/aws/audit-commands.log` with a timestamp:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] aws ec2 describe-instances ..." >> ~/Documents/claude-code/aws/audit-commands.log
```

## Reference Files

Read these on demand when you need deeper detail:

| File | When to Read |
|------|-------------|
| `references/audit-checklist.md` | Running a quarterly deep audit -- full 5-phase runbook with AWS CLI commands |
| `references/monthly-maintenance.md` | Running the monthly maintenance checklist |
| `references/emergency-procedures.md` | Responding to PBX outage, toll fraud, unauthorized access, or other emergencies |

## Task: $ARGUMENTS
