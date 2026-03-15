# PBXact Configuration Reference

## Table of Contents
1. Critical Advanced Settings
2. fwconsole Command Reference
3. sysadmin Module Operations
4. HAproxy Management
5. Certman & SSL
6. Firewall Module
7. Telnyx Trunk Configuration
8. Call Recording Pipeline
9. Scribe Transcription
10. Useful Diagnostic Tools

---

## 1. Critical Advanced Settings

Access via: **Admin → Advanced Settings**

These settings MUST be verified after every migration. The backup restore may
change them to values from the source system.

| Setting | Required Value | Why |
|---------|---------------|-----|
| SIP and IAX allow | `g722&ulaw` | **No Opus.** Opus causes recording/transcription issues |
| SIP canreinvite | `no` | Required for AWS — prevents re-INVITE failures through NAT |
| SIP encryption | `yes` | SRTP enabled |
| SIP sendrpid | `pai` | Required for Telnyx — sends P-Asserted-Identity header |
| Call Recording Format | `wav` | Required for Scribe compatibility |
| Ringtime Default | `15` (or higher per client preference) | Seconds before no-answer routing |
| Extension Concurrency Limit | `5` | Max simultaneous calls per extension |
| Trunk Dial Timeout | `60-120` | Seconds; default 300 is excessive |

### Checking Settings via CLI

```bash
# Query a specific setting from the database
mysql -u root -e "SELECT keyword,value FROM asterisk.freepbx_settings WHERE keyword='SIPSETTINGS_ALLOW';"

# Check all codec-related settings
mysql -u root -e "SELECT keyword,value FROM asterisk.freepbx_settings WHERE keyword LIKE '%allow%' OR keyword LIKE '%codec%';"

# Check recording format
mysql -u root -e "SELECT keyword,value FROM asterisk.freepbx_settings WHERE keyword LIKE '%MIXMON%' OR keyword LIKE '%RECORDING%';"
```

---

## 2. fwconsole Command Reference

`fwconsole` is the primary CLI tool for FreePBX/PBXact management.

### Module Management
```bash
# List all modules with status
fwconsole ma list

# List specific module
fwconsole ma list | grep <module-name>

# Install/reinstall a module (repairs module database)
fwconsole ma install <module-name>

# Remove a module
fwconsole ma remove <module-name>

# Download and install from URL
fwconsole ma downloadinstall <url>

# Download and install with edge channel
fwconsole ma downloadinstall <module-name> --edge

# Update all modules
fwconsole ma updateall
```

### System Operations
```bash
# Reload FreePBX configuration (applies GUI changes to Asterisk)
fwconsole reload

# Restart FreePBX framework
fwconsole restart

# Check system status
fwconsole sysadmin info
```

### Backup & Restore
```bash
# List available backups
fwconsole backup --list

# Run a backup
fwconsole backup --id=<backup-id>

# Restore from file
fwconsole backup --restore --file=<backup-file>
```

---

## 3. sysadmin Module Operations

The sysadmin module manages system-level settings including networking, ports,
DNS, email, and in some deployments, OpenVPN.

```bash
# Display activation info
fwconsole sa info

# Activate with deployment ID
fwconsole sa activate <deployment-id>

# Deactivate (before migration)
fwconsole sa deactivate

# Refresh activation
fwconsole sa update

# Display port mappings
fwconsole sa ports

# Rebuild HAproxy config
fwconsole sa rebuildhaproxy

# Update Apache SSL certificate
fwconsole sa updatecert

# Disable forced HTTPS redirect
fwconsole sa cf

# Show SSL protocol
fwconsole sa ssp

# Reset SSL protocol to default (TLSv1.2)
fwconsole sa rsp

# Custom Postfix settings
fwconsole sa addpostfix --set='<setting>'
fwconsole sa showpostfix
fwconsole sa savepostfix
fwconsole sa cleanpostfix
```

### Standard Port Mappings

| Port | Name | Purpose |
|------|------|---------|
| 80 | leport | Let's Encrypt / HTTP redirect |
| 2001 | acp | Admin panel (HTTP) |
| 28255 | sslacp | Admin panel (HTTPS) — primary access |
| 8255 | sslucp | User Control Panel (HTTPS) |
| 21445 | sslrestapps | REST Apps (HTTPS) |
| 21345 | sslrestapi | REST API (HTTPS) |
| 14325 | sslhpro | Phone Apps (HTTPS) |

---

## 4. HAproxy Management

HAproxy sits in front of Apache and routes traffic to the correct FreePBX
services based on port. It is managed entirely by the sysadmin module.

### Common Failure: HAproxy Running with Zero Ports

**Symptom:** `ss -tlnp | grep haproxy` returns nothing, but
`systemctl status haproxy` shows active/running.

**Root cause:** The sysadmin module's database is corrupt or uninitialized.
`fwconsole sa rebuildhaproxy` reports success but generates an empty config
(only global/defaults sections, no frontend/backend blocks).

**Fix:**
```bash
# Repair the sysadmin module (this is the actual fix)
fwconsole ma install sysadmin

# Then rebuild HAproxy
fwconsole sa rebuildhaproxy

# Verify ports are now bound
ss -tlnp | grep haproxy
```

### Verifying HAproxy Health
```bash
# Check process is running
systemctl status haproxy

# Check listening ports (should show 28255, 8255, etc.)
ss -tlnp | grep haproxy

# Check config file has frontend/backend blocks
grep -c "frontend\|backend" /etc/haproxy/haproxy.cfg
# Should return > 0

# Test admin panel access
curl -kI https://localhost:28255
# Should return HTTP 302 or 200
```

### DO NOT manually edit `/etc/haproxy/haproxy.cfg`

The sysadmin module owns this file and will overwrite manual changes. Always
use `fwconsole sa` commands to manage HAproxy.

---

## 5. Certman & SSL

Certificate Manager handles SSL certificates for the PBXact web interface.

```bash
# Update/reissue Apache SSL cert
fwconsole sa updatecert

# Install HTTPS cert for a specific hostname
fwconsole sa ihc --set='talk.clientdomain.com'

# Install default cert
fwconsole sa ihc default
```

After migration, certs from the source system are tied to the old hostname/IP.
Reissue for the new system:

1. GUI: **Admin → Certificate Manager**
2. Delete old certificates
3. Create new Let's Encrypt certificate for the new hostname
4. Apply to Apache via sysadmin module

---

## 6. Firewall Module

The FreePBX firewall provides application-level filtering on top of AWS
Security Groups.

### Post-Migration Verification

Telnyx IP ranges must be in the trusted zone. These may not transfer from backup:

1. GUI: **Connectivity → Firewall → Networks**
2. Verify Telnyx SIP signaling IPs are listed as Trusted
3. If missing, add them manually

### Firewall Zones
- **Internal** — Trusted local networks (VPN subnets, etc.)
- **External** — Everything else (internet-facing)
- **Trusted** — Explicitly trusted IPs (Telnyx, management IPs)

### CLI Operations
```bash
# Check firewall status
fwconsole firewall status

# List rules (limited CLI support — use GUI for full management)
iptables -L -n | head -40
```

---

## 7. Telnyx Trunk Configuration

### Trunk Settings (GUI: Connectivity → Trunks)

| Setting | Value |
|---------|-------|
| Trunk Type | PJSIP |
| Transport | TCP (0.0.0.0:5060) |
| Registration | IP-based (Telnyx uses IP authentication) |
| Format | e164-us |
| SRTP | Enabled |
| Codecs | G.722 priority, ulaw fallback |

### Verifying Trunk Status
```bash
# Check registration
asterisk -rx "pjsip show registrations"
# Should show: Registered

# Check endpoint details
asterisk -rx "pjsip show endpoints"

# Check active channels on trunk
asterisk -rx "core show channels concise" | grep PJSIP/
```

### Telnyx Noise Suppression

Telnyx offers noise suppression engines in their portal (Media Profiles):
- **Denoiser** — Basic spectral subtraction
- **Deep Filter Net / Large** — ML-based, higher latency
- **Krisp Viva variants** — Commercial noise suppression

These are Telnyx-side DSP processing applied to the RTP stream before it reaches
the PBX. Implications:

- SRTP: Telnyx decrypts, processes, re-encrypts (normal for their architecture)
- Recordings: Will capture post-processed audio (cleaner, but not raw)
- Latency: Deep Filter Net and Krisp Promodel add measurable latency

**Recommendation:** Test with Krisp Viva Tel Lite on one low-stakes client first.
Verify recording quality and measure latency via RTCP reports before rolling out.

---

## 8. Call Recording Pipeline

### Recording Format
- Format: wav (required for Scribe compatibility)
- Channels: Stereo (two-channel) preferred for transcription quality
- Storage: Local first, then S3 via Filestore or post-record script

### Post-Record Scripts

Custom scripts that run after each recording is complete. Located in
`/usr/local/sbin/` with the primary merge script at
`/var/lib/asterisk/bin/mixmonitor-audio-merge.sh`.

**Advanced Settings path:**
Admin → Advanced Settings → Developer and Customization → Post Call Recording Script

**Standard value:**
```
/var/lib/asterisk/bin/mixmonitor-audio-merge.sh ^{ASTSPOOLDIR} ^{YEAR} ^{MONTH} ^{DAY} ^{CALLFILENAME} ^{MIXMON_FORMAT} ^{MIXMON_DIR}
```

**Permissions:**
```bash
chmod 755 /usr/local/sbin/*.sh
chown asterisk:asterisk /usr/local/sbin/*.sh
chmod 755 /var/lib/asterisk/bin/mixmonitor-audio-merge.sh
```

### Recording Storage Locations
- Local: `/var/spool/asterisk/monitor/`
- S3: Per-client bucket (see `aws-infrastructure.md`)

---

## 9. Scribe Transcription

Scribe is FreePBX's call transcription module. It must ALWAYS be installed fresh
on PBXact 17 — never migrated from a backup.

### Installation
```bash
fwconsole ma downloadinstall scribe --edge
fwconsole reload
```

### Configuration
- License must be associated with the deployment ID in the Sangoma portal
- Enable per user/group in User Manager after license is confirmed
- Requires wav recording format (verify in Advanced Settings)
- Stereo recordings improve transcription accuracy

### Known Issues
- Scribe lacks a public API or CLI for programmatic audio submission
- If Scribe was broken on the source system and included in the backup,
  it can carry ghost config into the new system — always uninstall before
  backup and reinstall fresh
- The Dictation module (dial *34/*35) uses `audio-email.pl` and does NOT
  integrate with Scribe natively — this is an active exploration area

---

## 10. Useful Diagnostic Tools

### Asterisk CLI Commands
```bash
# Interactive Asterisk CLI
asterisk -rvvv

# One-shot commands (preferred for scripting)
asterisk -rx "pjsip show registrations"
asterisk -rx "pjsip show endpoints"
asterisk -rx "core show channels"
asterisk -rx "core show channels concise"    # Deprecated but still works in Asterisk 21
asterisk -rx "core show version"
asterisk -rx "core show codecs"
asterisk -rx "pjsip show endpoint <name>"    # Detailed endpoint info

# Note: "sip show peers" does NOT exist on PBXact 17 (PJSIP-only)
```

### System Diagnostics
```bash
# Service status
systemctl status asterisk haproxy postfix openvpn

# Port listening
ss -tlnp

# Active connections
ss -tnp | grep :5060

# System resources
uptime
free -h
df -h
top -bn1 | head -20

# Network
ip addr show
ip route show
cat /etc/resolv.conf
```

### Log Files
| Log | Path | Purpose |
|-----|------|---------|
| Asterisk | `/var/log/asterisk/full` | Full Asterisk debug log |
| FreePBX | `/var/log/asterisk/freepbx.log` | Module and framework logs |
| Mail | `/var/log/mail.log` | Postfix email delivery |
| Auth | `/var/log/auth.log` | SSH and authentication events |
| Syslog | `/var/log/syslog` | General system events |
| HAproxy | `/var/log/haproxy.log` | Web proxy events |

### Dialplan Visualizer (dpviz)

Installed from GitHub, provides visual call flow rendering in the GUI:

```bash
# Install
fwconsole ma downloadinstall https://github.com/madgen78/dpviz/archive/refs/heads/main.zip
fwconsole reload

# Access via GUI: Reports → Dial Plan Visualizer
```

Version 1.0.30+ resolves the "Tampered Files" error on FreePBX 17.
