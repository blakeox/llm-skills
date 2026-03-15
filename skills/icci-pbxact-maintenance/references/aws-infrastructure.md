# AWS Infrastructure Reference

## Instance Architecture

Each PBXact client runs on a dedicated EC2 instance. There are 16 instances total
plus golden master instances used for image building.

### Standard Instance Layout

| Resource | Specification |
|----------|--------------|
| Instance type | Varies by client (t3.medium typical for small offices) |
| Root volume | 60GB EBS (ext4, gp3) |
| Swap volume | 8GB EBS at /dev/nvme1n1 |
| OS | Debian 12 (Bookworm) |
| Network | Single ENI, public IP or Elastic IP |

### NVMe Device Mapping

AWS instances with NVMe storage controllers rename EBS device paths:

| AWS Console Name | OS Device Path | Purpose |
|-----------------|---------------|---------|
| `/dev/sda1` or `/dev/xvda` | `/dev/nvme0n1` | Root volume |
| `/dev/sdf` | `/dev/nvme1n1` | Swap volume |

When a tech attaches an EBS volume in the console with device name `/dev/sdf`,
the OS will see it as `/dev/nvme1n1`. The fstab entry already references
`/dev/nvme1n1` with the `nofail` flag so the system boots cleanly whether or
not the swap volume is attached.

---

## Security Architecture — Layered Model

### Layer 1: AWS Security Groups

Security groups are the primary perimeter. Administrative interfaces (ports 28255,
etc.) are BLOCKED at the Security Group level — they are never exposed to the
internet.

**Standard inbound rules:**

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Aaron's office IP | SSH |
| 5060 | TCP | Telnyx IP ranges | SIP signaling |
| 10000-20000 | UDP | Telnyx IP ranges | RTP media |
| 443 | TCP | 0.0.0.0/0 | HTTPS (provisioning, Let's Encrypt) |
| 1194 | UDP | 0.0.0.0/0 | OpenVPN |

**Standard outbound rules:**

| Port | Protocol | Destination | Purpose |
|------|----------|------------|---------|
| 587 | TCP | 0.0.0.0/0 | SMTP (AWS SES) |
| 443 | TCP | 0.0.0.0/0 | HTTPS (updates, S3) |
| 5060 | TCP | Telnyx IP ranges | SIP signaling |
| 10000-20000 | UDP | 0.0.0.0/0 | RTP media |

### Layer 2: PBXact Firewall Module

The FreePBX firewall module provides application-level filtering. Telnyx IP ranges
must be in the trusted/whitelist zone. After migration, manually verify these are
present — they may not transfer cleanly from backup.

### Layer 3: fail2ban

fail2ban monitors Asterisk logs for authentication failures and bans offending IPs
via iptables. Standard configuration:

```bash
# Verify fail2ban is running
fail2ban-client status

# Check Asterisk jail specifically
fail2ban-client status asterisk-iptables

# Verify ban time (should be 3000000 = ~34 days)
fail2ban-client get asterisk-iptables bantime
```

### Layer 4: SSH Key Authentication

Root SSH access uses key-only authentication (no passwords). Given the Security
Group restrictions, this doesn't materially expand the attack surface. This
justification is documented in script headers for auditors.

---

## S3 Integration

### Per-Client Recording Buckets

Each client has a dedicated S3 bucket for call recording storage.

**Bucket creation checklist:**
1. **Bucket name:** `<client-abbrev>-call-recordings` (e.g., `wvh-call-recordings`)
2. **Region:** Same as the EC2 instance (critical for latency and transfer costs)
3. **Block all public access:** ON
4. **Versioning:** Off (recordings don't need versioning)
5. **Encryption:** SSE-S3 (AES-256) — no cost, good practice
6. **Object Lock:** Off

### IAM Configuration

Create a dedicated IAM user per client (or use EC2 instance roles) with a policy
scoped to the specific bucket:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::<bucket-name>",
                "arn:aws:s3:::<bucket-name>/*"
            ]
        }
    ]
}
```

### S3 Mount via s3fs

The migrate utility S3 bucket is mounted via s3fs-fuse for backup/restore operations:

```bash
# Run the mount script (pre-installed in GM)
./migrate_utility_s3mount_debian.sh
```

Mount point: `/mnt/migrate-utility/<CLIENT>/`

### S3 for Call Recording Archives

Two approaches exist:
1. **FreePBX Filestore module** — Native S3 integration, but has known ACL issues
2. **Post-record script** — Custom script that uploads recordings after Asterisk
   writes them. More reliable but requires manual setup.

The Filestore ACL issue may cause recordings to fail to upload silently. If using
Filestore, verify recordings actually appear in S3 after test calls.

---

## AMI Management

### Creating an AMI

See `golden-master-build.md` for the full GM AMI process.

For client instance AMIs (used for snapshots/backups):

```bash
# From AWS CLI (if configured):
aws ec2 create-image \
    --instance-id i-XXXXX \
    --name "<client>-pbxact17-DDMMMYY" \
    --no-reboot
```

Or use the EC2 console: select instance → Actions → Image and templates →
Create image.

### Aaron's Side-by-Side Trick

Before migrating a client, snapshot the old system. If anything goes wrong during
migration, spin up the snapshot as a new instance with Security Group rules
restricting access to Aaron's office IP only. This allows side-by-side comparison
between old and new systems without the old instance trying to register trunks or
serve phones.

---

## Server Hardening Checklist

Post-deployment hardening for production PBXact instances:

### SSH
- Key-only authentication (no passwords)
- Root access via key auth (justified by layered security model)
- Host keys regenerated post-deploy via `sshd-rekey-debian.sh`

### Services
- Disable opendkim: `systemctl disable --now opendkim`
- Verify only required services are running:
  ```bash
  systemctl list-units --type=service --state=running
  ```

### Kernel Tuning for VoIP
```bash
# Check current values
sysctl net.core.rmem_max
sysctl net.core.wmem_max

# Recommended for VoIP workloads (add to /etc/sysctl.d/99-voip.conf):
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
```

### Filesystem
```bash
# Verify root volume has discard enabled (SSD TRIM)
mount | grep " / "
# Should show: rw,discard

# Verify swap is active
swapon --show
free -h
```

### System Health Baseline
```bash
uptime
free -h
df -h
```
