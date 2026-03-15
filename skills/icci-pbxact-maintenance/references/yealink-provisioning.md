# Yealink Phone Provisioning Reference

## Overview

All ICCI client endpoints are Yealink phones managed through FreePBX Endpoint
Manager (EPM) with custom basefiles. Provisioning is URL-based only — PnP and
DHCP option 66 are both disabled.

---

## Phone Models in Use

| Model | Type | EPM Profile | Notes |
|-------|------|-------------|-------|
| T48S | Desk phone | T48S | Primary desk phone across most clients |
| T57W | Desk phone | **T48S** | Uses T48S profile (deliberate workaround) |
| T46S | Desk phone | T46S | Some clients |
| T54W | Desk phone | T48S or native | Newer deployments |
| W60 | DECT cordless | W60 | Different provisioning than desk phones |

### The T57W / T48S EPM Hack

Yealink did not pay Sangoma for full T57W EPM profile support. As a workaround,
T57W phones use the T48S EPM profile. The `firmware.url` line in the T48S basefile
points at T57W firmware — this is intentional, not a bug.

```
# In the T48S basefile — this correctly serves T57W firmware to T57W phones
firmware.url = __provisionAddress__/yealink/2/t57w.rom
```

The firmware file itself requires a symlink because Yealink firmware filenames
are unwieldy:

```bash
ln -s "/tftpboot/yealink/2/T54W(T57W,T53W,T53,T53C,T54,T57)-96.87.0.15.rom" \
      /tftpboot/yealink/2/t57w.rom
chown -h asterisk:asterisk /tftpboot/yealink/2/t57w.rom
```

The `-h` flag on `chown` applies ownership to the symlink itself, not the target.

---

## Basefile Key Settings

### Provisioning Behavior
```ini
# Pull config on power-on (enables PoE switch power-cycle reprovisioning)
auto_provision.power_on.enable = 1

# Disable PnP and DHCP option 66 — provisioning is URL-only
static.auto_provision.pnp_enable = 0
static.auto_provision.dhcp_option.enable = 0

# Optional: scheduled re-provisioning (use temporarily during migration)
auto_provision.repeat.enable = 1
auto_provision.repeat.minutes = 10
# Remove after all phones have reprovisioned
```

### SRTP Configuration
```ini
# SRTP mandatory (value 2 = required, not optional)
account.1.srtp_encryption = 2
account.2.srtp_encryption = 2
```

SRTP values:
- `0` = disabled
- `1` = optional (will use if offered)
- `2` = mandatory (will not connect without SRTP)

All ICCI deployments use `2` (mandatory).

### Transport Type
```ini
# Transport type 1 = TCP (matches Telnyx trunk on TCP 5060)
account.1.sip_server.1.transport_type = 1
```

Transport values:
- `0` = UDP
- `1` = TCP
- `2` = TLS
- `3` = DNS-NAPTR

### Codec Priority

Yealink uses its own codec index numbering, different from Asterisk:

| Yealink Index | Codec |
|---------------|-------|
| 1 | PCMU (ulaw) |
| 2 | PCMA (alaw) |
| 3 | G.723.1 |
| 4 | G.729 |
| 5 | G.726 |
| 6 | **G.722** |
| 7 | G.711-A µ-law |
| 8 | iLBC |

Standard ICCI codec priority in basefiles:
```ini
# G.722 first, ulaw fallback, alaw third
account.1.codec.6.priority = 1    # G.722
account.1.codec.1.priority = 2    # PCMU/ulaw
account.1.codec.2.priority = 3    # PCMA/alaw
account.1.codec.5.priority = 4    # G.726 (if needed)

# Same for account 2 if present
account.2.codec.6.priority = 1
account.2.codec.1.priority = 2
account.2.codec.2.priority = 3
```

**Opus is never included in basefile codec priority.** If a phone has Opus
enabled, it can negotiate Opus with Asterisk even if Asterisk doesn't prefer it,
causing recording issues.

---

## Firmware Management

### Firmware Directory Structure
```
/tftpboot/
└── yealink/
    ├── 1/           # Firmware slot 1 (older firmware versions)
    │   └── t57w.rom → symlink to actual firmware
    └── 2/           # Firmware slot 2 (current firmware versions)
        ├── T54W(T57W,T53W,T53,T53C,T54,T57)-96.87.0.15.rom
        ├── t57w.rom → symlink to above
        └── T46S-66.86.0.160.rom
```

### Creating Firmware Symlinks
```bash
# Always use the full path with proper escaping for parentheses
ln -s "/tftpboot/yealink/2/T54W(T57W,T53W,T53,T53C,T54,T57)-96.87.0.15.rom" \
      /tftpboot/yealink/2/t57w.rom

# Set ownership to asterisk (the -h flag targets the symlink, not the target)
chown -h asterisk:asterisk /tftpboot/yealink/2/t57w.rom

# Verify
ls -la /tftpboot/yealink/2/t57w.rom
```

### Known Firmware Versions (as of Feb 2026)
| Model | Firmware Version |
|-------|-----------------|
| T48S | 66.86.0.160 |
| T57W / T54W family | 96.87.0.15 |
| T46S | 66.86.0.160 |

---

## EPM Basefile Location

EPM basefiles are stored in the FreePBX database and served via the provisioning
HTTP endpoint. To inspect them:

- **GUI:** Admin → Endpoint Manager → [Brand] → [Model] → Basefile
- **Filesystem:** Provisioned configs are generated dynamically; basefiles are
  templates stored in the EPM database

The provisioning URL and port are configured in:
**Admin → Endpoint Manager → Global Settings**

---

## Reprovisioning Phones After Migration

### Method 1: PoE Switch Power-Cycle (Preferred)
Since `auto_provision.power_on.enable = 1`, phones pull config on boot.
Power-cycling the PoE switch forces all phones to reboot and provision from
the new server.

**Prerequisites before power-cycle:**
1. Telnyx trunk registered and tested on new PBX
2. SRTP confirmed on both trunk and extension configs
3. EPM basefiles verified — customizations survived restore
4. Provisioning URL points to new server IP/hostname
5. Firmware symlinks in place

### Method 2: Scheduled Reprovision (For remote/gradual migration)
Add to basefiles BEFORE taking backup on source system:
```ini
auto_provision.repeat.enable = 1
auto_provision.repeat.minutes = 10
```
Phones will check in every 10 minutes and pull new config when the DNS/URL
changes. Remove the repeat settings after all phones have reprovisioned.

### Method 3: After-Hours Site Visit
Physically access the network closet and power-cycle the PoE switch. Required
for W60 DECT bases which may not respond to remote provisioning triggers.

---

## W60 DECT Cordless — Special Considerations

The W60 is a DECT cordless system with a base station and handsets. Provisioning
differs from desk phones:

- The base station provisions, not individual handsets
- DECT pairing between base and handsets is independent of SIP registration
- If the base is re-provisioned, handsets should reconnect automatically
- If handsets lose pairing, they need physical re-registration to the base
- W60 firmware updates are applied to the base station

Always verify W60 provisioning separately from desk phones after migration.

---

## Troubleshooting Phone Registration

| Symptom | Check | Fix |
|---------|-------|-----|
| Phone shows "No Service" | Check PJSIP endpoint status | Verify extension exists and credentials match |
| Phone registers but no audio | SRTP mismatch | Verify `srtp_encryption = 2` in basefile matches PBX config |
| Phone won't provision | Check provisioning URL | Verify EPM Global Settings → provisioning address |
| Phone has wrong firmware | Check firmware.url in basefile | Update symlink and basefile path |
| Phone registers to old server | DNS cache or old config | Power-cycle phone; check provisioning URL |
| Codec mismatch errors | Phone offering Opus | Verify basefile codec priority excludes Opus |
