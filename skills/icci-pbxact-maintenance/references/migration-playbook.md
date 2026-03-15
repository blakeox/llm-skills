# ICCI PBXact Migration Playbook

Complete, battle-tested procedures for migrating PBXact 15/16 (CentOS 7) to
PBXact 17 (Debian 12). Based on production migrations including Washtenaw
Veterinary Hospital (16→17, Feb 2026) and Dahlmann Properties (15→17, in progress).

---

## Table of Contents
1. Pre-Migration Analysis
2. Module Risk Matrix
3. Pre-Migration Preparation
4. Migration Execution
5. Post-Migration Verification
6. Post-Migration Hardening
7. Lessons Learned & Gotchas

---

## 1. Pre-Migration Analysis

Run `../scripts/pre-migration-analysis.sh` on the SOURCE system before touching
anything. It covers 13 critical areas. Review the output for these red flags:

### What to Look For

| Area | Red Flag | Action |
|------|----------|--------|
| Extensions | PJSIP vs chan_sip mix | chan_sip auto-converts on restore but verify |
| Extensions | Unreachable FXO gateways | Need manual PJSIP conversion on 17 |
| Codecs | Opus loaded | Must be removed before or after migration |
| Modules | scribe installed (broken) | `fwconsole ma remove scribe` before backup |
| VPN | 10.x.x.x subnet on tun interface | Identify if sysadmin or SangomaConnect manages it |
| Custom scripts | Files in /usr/local/sbin/ | Copy to S3 before migration |
| Recordings | Post-record scripts configured | Copy scripts and note Advanced Settings path |
| Disk | Source > 60GB used | May need larger target EBS volume |

### Version Jump Complexity

| Migration Path | Complexity | Notes |
|---------------|-----------|-------|
| PBXact 16 → 17 | Moderate | CentOS 7 → Debian 12, most modules migrate cleanly |
| PBXact 15 → 17 | High | Larger module version delta, more chan_sip remnants, possible FXO gateway issues |

---

## 2. Module Risk Matrix

### HIGH RISK — Action Required

| Module | Risk | Required Action |
|--------|------|-----------------|
| `sangomaconnect` | Auto-generated certs not portable | Rebuild from scratch on 17. Never migrate. |
| `scribe` | Ghost config corrupts fresh install | Uninstall on source BEFORE backup. Fresh install on 17 with `--edge` flag. |
| `firewall` | Trusted networks may not transfer | Manually verify Telnyx IP ranges in trusted zone post-restore. |
| `sysadmin` | License activation, haproxy generation | Verify activation post-restore. If HAproxy fails: `fwconsole ma install sysadmin`. |

### MEDIUM RISK — Verify Post-Restore

| Module | Risk | Verification |
|--------|------|-------------|
| `certman` | Certs tied to old system | Reissue for new hostname/IP via `fwconsole sa updatecert`. |
| `endpoint` (EPM) | Basefiles may not survive | Check all basefile customizations and provisioning URLs. |
| `sipsettings` | Config may revert to old values | Confirm TCP 5060, SRTP enabled, codec order = `g722&ulaw`. |
| `vqplus` | License required | Activate license. Historical VQ data won't migrate. |
| `restapps` | Pairings not portable | Re-pair all REST app connections. |

### LOW RISK — Standard Restore

These modules restore cleanly from backup with no special handling:

`backup`, `calendar`, `timeconditions`, `ivr`, `queues`, `ringgroups`,
`voicemail`, `announcement`, `findmefollow`, `parking`, `fax`, `faxpro`

**Note:** CDR/CEL historical call data does NOT migrate with a standard config
backup. Historical records remain on the old system only.

---

## 3. Pre-Migration Preparation

### On the Source System

**Step 1 — Snapshot the source instance in AWS**

Take an AWS snapshot BEFORE any changes. This enables the side-by-side trick:
spin up the snapshot with Security Group access restricted to Aaron's office IP
only, for reference during migration without risking production.

**Step 2 — Uninstall problematic modules**

```bash
# Remove broken scribe (if present and broken)
fwconsole ma remove scribe

# Do NOT remove sangomaconnect — just plan to rebuild it on 17
```

**Step 3 — Copy critical files to S3 migration directory**

```bash
# Mount the S3 utility if not already mounted
# (see aws-infrastructure.md for mount details)

# Post-record scripts
cp /usr/local/sbin/*.sh /mnt/migrate-utility/<CLIENT>/

# EPM basefiles for reference
cp /tftpboot/yealink/*basefile* /mnt/migrate-utility/<CLIENT>/ 2>/dev/null

# Any custom AGI scripts
cp /var/lib/asterisk/agi-bin/*.sh /mnt/migrate-utility/<CLIENT>/ 2>/dev/null
cp /var/lib/asterisk/agi-bin/*.php /mnt/migrate-utility/<CLIENT>/ 2>/dev/null
```

**Step 4 — Take the backup**

```bash
# Use the FreePBX backup module
fwconsole backup --id=<backup-id>

# Copy backup file to S3
cp /var/spool/asterisk/backup/<backup-name>/*.tgz /mnt/migrate-utility/<CLIENT>/
```

**Step 5 — Deactivate the license**

```bash
fwconsole sa deactivate
```

### On the Target System (Fresh PBXact 17)

1. Launch new EC2 instance from golden master AMI (see `golden-master-build.md`)
2. Complete the first-run checklist (swap, hostname, SSH rekey)
3. Run `freepbx_install_script.sh` to install PBXact 17
4. Mount S3 migrate utility
5. **Do NOT activate license yet** — restore backup first

---

## 4. Migration Execution

### Restore with Trunks Disabled

Restore the backup. The Telnyx trunk will be enabled in the backup data.
Immediately disable it in the GUI BEFORE applying config — this prevents the
new system from trying to register with Telnyx while the old system is still live.

```bash
# Restore the backup
fwconsole backup --restore --file=/mnt/migrate-utility/<CLIENT>/<backup>.tgz
```

After restore completes:
1. Navigate to Connectivity → Trunks in the GUI
2. Disable the Telnyx trunk
3. Apply Config

### License Transfer

```bash
# On the new system
fwconsole sa activate <deployment-id>
fwconsole sa update

# Verify
fwconsole sa info
```

### Install Missing Modules

```bash
# Scribe — always fresh install, never from backup
fwconsole ma downloadinstall scribe --edge
fwconsole reload

# Dialplan Visualizer (dpviz) — from GitHub
fwconsole ma downloadinstall \
  https://github.com/madgen78/dpviz/archive/refs/heads/main.zip
fwconsole reload
```

### Restore Post-Record Scripts

```bash
# Copy from S3 to the standard location
cp /mnt/migrate-utility/<CLIENT>/postrecord.sh /usr/local/sbin/
cp /mnt/migrate-utility/<CLIENT>/emailrecording*.sh /usr/local/sbin/
chmod 755 /usr/local/sbin/*.sh
chown asterisk:asterisk /usr/local/sbin/*.sh

# Also restore the mixmonitor merge script if needed
ls -la /var/lib/asterisk/bin/mixmonitor-audio-merge.sh
```

Wire up in GUI: Admin → Advanced Settings → Developer and Customization →
Post Call Recording Script.

---

## 5. Post-Migration Verification

Run these checks in order. Do not skip steps.

### 5.1 Extensions

```bash
asterisk -rx "pjsip show endpoints"
```
All extensions should appear as Unavailable (phones aren't provisioned yet).
Count should match source system.

### 5.2 Opus Must Be Absent

```bash
asterisk -rx "core show codecs" | grep -i opus
```
Must return nothing. If Opus appears, the backup restore re-added it.

Also check in GUI: Admin → Advanced Settings → Device Settings → SIP and IAX
allow. Must be `g722&ulaw`, not `opus&g722` or similar.

### 5.3 Critical Advanced Settings

| Setting | Required Value | Why |
|---------|---------------|-----|
| SIP and IAX allow | `g722&ulaw` | Opus breaks recordings |
| SIP canreinvite | `no` | Required for AWS (prevents re-INVITE failures) |
| SIP encryption | `yes` | SRTP |
| SIP sendrpid | `pai` | Required for Telnyx |
| Call Recording Format | `wav` | Required for Scribe |
| Ringtime Default | 15-25 | Verify appropriate for client |

### 5.4 Enable and Verify Telnyx Trunk

In GUI: Connectivity → Trunks → Enable Telnyx trunk → Apply Config

```bash
asterisk -rx "pjsip show registrations"
# Should show: Registered
```

If trunk won't register, check:
- Firewall trusted zones include Telnyx IP ranges
- Transport is TCP 5060
- SRTP is enabled on the trunk
- Use `sngrep` to see the REGISTER flow

### 5.5 Email Test

```bash
echo "Test from PBX" | mail -s "SMTP Test $(hostname)" <test-email>
tail -f /var/log/mail.log
```

If SASL auth fails: `apt install -y libsasl2-modules && systemctl restart postfix`
See `postfix-email-config.md` for full email config.

### 5.6 HAproxy / Admin Interface

```bash
curl -kI https://localhost:28255
ss -tlnp | grep haproxy
```

If HAproxy is running but listening on 0 ports:
```bash
fwconsole ma install sysadmin
fwconsole sa rebuildhaproxy
systemctl restart haproxy
ss -tlnp | grep haproxy
```

### 5.7 Recording Pipeline

```bash
# Verify S3 mount
ls /mnt/migrate-utility/<CLIENT>/

# Verify post-record scripts
ls -la /usr/local/sbin/*.sh

# Check recording storage path
ls /var/spool/asterisk/monitor/
```

### 5.8 Full Reboot and Recheck

```bash
reboot
# After boot, verify everything survived:
asterisk -rx "pjsip show registrations"
ss -tlnp | grep haproxy
swapon --show
systemctl status asterisk postfix haproxy
```

### 5.9 End-to-End Test Call

Place a test call and verify:
- Call connects via Telnyx trunk
- Audio codec is G.722 (check with `asterisk -rx "core show channels verbose"`)
- SRTP negotiated (check with sngrep — look for crypto lines in SDP)
- Call recording created in `/var/spool/asterisk/monitor/`
- Recording is stereo (two channels) — required for Scribe
- Recording uploads to S3 (if post-record script configured)

---

## 6. Post-Migration Hardening

After migration is verified and phones are working:

```bash
# Disable OpenDKIM (redundant with SES)
systemctl disable --now opendkim

# Verify fail2ban
fail2ban-client status
fail2ban-client get asterisk-iptables bantime
# Should be 3000000 (~34 days)

# Check system health
uptime
free -h
df -h
```

---

## 7. Lessons Learned & Gotchas

### From WVH Migration (PBXact 16 → 17, Feb 2026)

1. **libsasl2-modules** — Must be installed on Debian for Postfix SMTP AUTH.
   Now baked into golden master. Symptom: `SASL authentication failed; no
   mechanism available`.

2. **Opus sneaks back in** — Backup restore re-adds `opus` to Advanced Settings
   codec allow list even if removed from source. Always verify post-restore.

3. **OpenDKIM is unnecessary** — AWS SES handles DKIM. Disable it.

4. **T57W EPM hack** — T57W phones use the T48S EPM profile. Yealink didn't pay
   Sangoma for full T57W support. The firmware.url pointing at t57w.rom inside a
   T48S basefile is intentional, not a bug.

5. **`sip show peers` doesn't exist** — PBXact 17 is PJSIP-only. Use
   `pjsip show endpoints`.

6. **Full reboot > `core restart now`** — `core restart now` only restarts
   Asterisk (~90%). Full reboot ensures all services come up clean.

7. **S3 Filestore ACL issue** — The Filestore module may have ACL problems
   with S3 buckets. Consider post-record script approach as alternative.

8. **Recording format** — Must be `wav` for Scribe. Stereo preferred.

9. **fail2ban bantime** — Set to 3000000 seconds (~34 days).

### From DDP Analysis (PBXact 15 → 17, in progress)

1. **Larger version jumps** — 15→17 has more module version delta and more
   chan_sip remnants than 16→17.

2. **FXO gateways** — Unreachable chan_sip FXO gateways need manual PJSIP
   conversion. They won't auto-convert.

3. **VPN ownership** — The OpenVPN service for phones (e.g., 10.33.33.0/24)
   may be managed by the sysadmin module, NOT SangomaConnect. Don't assume —
   check which component owns the VPN config.

4. **1Password SSH agent conflict** — When using Claude Code with SSH, the
   1Password SSH agent intercepts connections. Fix in SSH config:
   ```
   Host <pbx-host>
       IdentitiesOnly yes
       IdentityFile ~/.ssh/<specific-key>
   ```

### Pending Integration: Scribe + Dictation

The FreePBX Dictation module (dial *34 to record, *35 to send) uses
`audio-email.pl` to email recordings as attachments. Integration with Scribe for
voice-to-text dictation is being explored. Two approaches identified:

1. Replace `audio-email.pl` with a wrapper that mimics call recordings for Scribe
2. Create a wrapper that uses Scribe's GUI upload endpoint via HTTP

Approach 2 is recommended as more viable. Main challenge: Scribe lacks a public
API or CLI for programmatic audio submission.
