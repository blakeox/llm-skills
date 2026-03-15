# Golden Master (GM) Image — Build & Maintenance Guide

## Overview

The Golden Master is a clean Debian 12 (Bookworm) base image with NO PBXact
installed. It contains pre-installed dependencies, bootstrap tooling, and a
technician-facing first-run checklist. PBXact is installed on top of the GM
after instance launch via `freepbx_install_script.sh`.

---

## What's Included in the GM

### Pre-Installed Packages
- `tmux` — Session management (critical for long-running operations)
- `lolcat` — Rainbow text output for success messages
- `cowsay` — Fortune display on admin login (Aaron always reads the fortune)
- `fortune-mod` — Fortune database for cowsay
- `libsasl2-modules` — SASL auth plugins for Postfix SMTP AUTH (required for
  AWS SES email relay; missing by default on Debian, causes
  "SASL authentication failed; no mechanism available")
- `s3fs-fuse` — FUSE-based S3 bucket mounting
- `sngrep` — SIP packet capture tool
- Standard Debian base packages

### Scripts in /root
All scripts are `chmod 700` and follow ICCI script conventions.

| Script | Purpose |
|--------|---------|
| `freepbx_install_script.sh` | Installs PBXact 17 on top of the GM |
| `change_hostname.sh` | Sets system hostname and updates FreePBX |
| `sshd-rekey-debian.sh` | Regenerates SSH host keys (run post-deploy) |
| `sysprep.sh` | Prepares GM for AMI snapshot (destructive) |
| `migrate_utility_s3mount_debian.sh` | Mounts S3 migrate utility bucket |
| `root_ssh_enable.sh` | Enables root SSH (run from admin account) |

### User Accounts
- `root` — Primary operator account; SSH via key auth
- `admin` — Bootstrap account for initial root SSH enablement; has a single
  purpose: run `root_ssh_enable.sh`. Login experience includes bordered
  instruction box and cowsay fortune

### Network & Storage
- Root volume: 60GB EBS (ext4)
- Swap volume: 8GB EBS at `/dev/nvme1n1` (included in AMI)
- fstab swap entry uses device path with `nofail` flag
- SSH host keys are preserved during sysprep (NOT regenerated — rekeyed after deploy)

---

## GM Build Process

### Starting Point
Begin with a clean Debian 12 minimal install on an EC2 instance.

### Package Installation
```bash
apt-get update
apt-get install -y \
    tmux lolcat cowsay fortune-mod \
    libsasl2-modules \
    s3fs sngrep \
    curl wget git vim htop iotop \
    net-tools dnsutils
```

### Profile Configuration

**Root `.bash_profile`** includes:
- Interactivity check (early, before color definitions)
- No shebang (file is sourced, not executed)
- Color definitions (once, not duplicated from .bashrc)
- Public IP display with timeout: `curl -4 -s -m 3 ifconfig.me`
- tmux status bar with active channel count
- First-run checklist display (if checklist not completed)
- All aliases consolidated in `.bashrc` only

**Root `.bashrc`** includes:
- `ls` aliases with `-FlAhp` flags
- History configuration: `HISTCONTROL=ignoreboth:erasedups`, `HISTSIZE=10000`
- `dircolors` (run once, here only)
- Safe `lol()` function with lolcat availability check

**Admin `.bash_profile`** includes:
- Single-purpose login: bordered instruction box pointing to `root_ssh_enable.sh`
- Cowsay fortune (retained because Aaron always reads the fortune)
- No PBX-related tooling (admin account doesn't touch the PBX)

### Security Configuration
- Root SSH: key authentication only, no password
- Admin account: limited to running the SSH enablement script
- No unnecessary services running
- SSH host keys preserved during sysprep for AMI consistency

### Swap Configuration
```bash
# Create and attach 8GB EBS volume as /dev/sdf (appears as /dev/nvme1n1)
mkswap /dev/nvme1n1
swapon /dev/nvme1n1

# fstab entry (already present in GM)
# /dev/nvme1n1 none swap sw,nofail 0 0
```

**AWS NVMe device mapping note:** When a tech creates and attaches an 8GB EBS
volume in the EC2 console with device name `/dev/sdf`, the OS sees it as
`/dev/nvme1n1`. The fstab entry already references this device path. The volume
must be attached BEFORE the instance starts for swap to activate on boot.

---

## Sysprep Process

`sysprep.sh` prepares the GM for AMI snapshot. It is destructive and shuts down
the server. Run it as the last step before taking the AMI.

### What sysprep.sh Does (in order)
1. Double confirmation prompt (asks twice — this is destructive)
2. Resets `/etc/machine-id` (truncate + symlink)
3. Clears shell history for all users
4. Cleans apt cache: `apt-get clean && apt-get autoremove -y`
5. Removes temp files: `/tmp/*`, `/var/tmp/*`
6. Truncates system logs: syslog, auth.log
7. Rotates and vacuums journal logs
8. Removes `.viminfo` for all users
9. Disables opendkim if present
10. Cleans cloud-init state
11. Seeds first-run checklist (creates `/root/.checklist_status` and
    `/root/FIRST_RUN_CHECKLIST.md`)
12. 30-second countdown with rotating lolcat colors
13. `shutdown -h now`

### What sysprep.sh Does NOT Do
- Does NOT regenerate SSH host keys (done post-deploy via `sshd-rekey-debian.sh`)
- Does NOT change hostname (handled by AWS on boot, then `change_hostname.sh`)
- Does NOT touch the swap volume or fstab

### After Sysprep
1. Wait for instance to reach `stopped` state in EC2 console
2. Do NOT reboot before snapshot — machine-id and keys would regenerate on GM
3. Create AMI image (not a launch template)
4. Include both EBS volumes (root + swap) in the AMI
5. Tag image and snapshots together

---

## AMI Creation

### Naming Convention
```
pbxact17-gm-debian12-DDMMMYY
```
Example: `pbxact17-gm-debian12-22FEB26`

Day-month-year with abbreviated month in caps.

### Required Tags
| Key | Value |
|-----|-------|
| `Name` | `pbxact17-gm-debian12-DDMMMYY` |
| `Organization` | `ICCI` |
| `Type` | `golden-master` |
| `OS` | `debian12` |
| `PBX Version` | `pbxact17` |
| `Built` | `DDMMMYY` |

Tag both the image and the underlying snapshots (select "Tag image and snapshots
together" in the AWS console).

### AMI Creation Steps
1. In EC2 Console → select stopped GM instance → Actions → Image and templates →
   **Create image** (NOT "Create template from instance")
2. Image name: `pbxact17-gm-debian12-DDMMMYY`
3. Image description: `PBXact 17 / Debian 12 Golden Master. ICCI LLC. Pre-install
   base image with GM tooling, admin bootstrap account, and first-run checklist.
   Launch freepbx_install_script.sh after instance init. Built DDMMMYY. Do not
   launch directly.` (255 char limit)
4. Instance volumes: Include both volumes (root + swap). Uncheck "Reboot instance"
   since it's already stopped.
5. Add tags as listed above
6. Create image

---

## First-Run Checklist (Post-AMI Launch)

When a tech launches a new instance from the GM AMI, the first-run checklist
displays automatically on root login. Steps:

1. **Verify swap is active:** `swapon --show` (auto-detected if present)
2. **Set hostname:** Run `change_hostname.sh`
3. **Rekey SSH:** Run `sshd-rekey-debian.sh`
4. **Install PBXact:** Run `freepbx_install_script.sh`
5. **Mount S3:** Run `migrate_utility_s3mount_debian.sh`

The checklist tracks completion status in `/root/.checklist_status`. Each script
writes a completion marker when it finishes successfully. The `.bash_profile`
displays remaining items on each login until all are complete.

---

## Updating the GM

When changes are needed (new packages, script updates, config changes):

1. Launch a new instance from the current GM AMI
2. Make changes
3. Run sysprep.sh
4. Create new AMI with incremented date
5. Keep the old AMI for rollback until the new one is validated
