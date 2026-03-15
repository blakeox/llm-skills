# ICCI Script Conventions Reference

All bash scripts produced for ICCI follow these conventions exactly. No exceptions.

---

## Header Template

```bash
#!/bin/bash
###############################################################
# Script Name   : script-name.sh
# Author        : Aaron Salsitz
# Organization  : ICCI, LLC
# Title         : Master Bit Herder
# Created Date  : YYYY-MM-DD
# Version       : X.Y
# Contributors  : Claude (Anthropic)
# Description   : [What this script does — 2-3 lines max,
#                 wrapped at column 61]
# Usage         : ./script-name.sh [arguments]
# Notes         : [Environment requirements, prerequisites,
#                 warnings]
#
# License       : Creative Commons Attribution 4.0 International
#                 (CC BY 4.0) — You are free to share and adapt
#                 this work provided appropriate credit is given
#                 to ICCI, LLC and the original authors.
#                 https://creativecommons.org/licenses/by/4.0/
#
# Changes v1.0  : Initial release. [Brief description.]
# Changes v1.1  : [Chronological — each version gets a line.]
###############################################################
```

### Header Rules
- Contributors always includes `Claude (Anthropic)` when Claude helped write it
- Other contributors (e.g., `ChatGPT`) included if they contributed to earlier versions
- Changes are chronological — newest version last
- Description wraps at column 61 (aligned with `#` comment block)
- License block is always CC BY 4.0

---

## Color Definitions

Every script begins with these after the header:

```bash
# Color definitions
RED='\033[1;31m'
ORANGE='\033[0;33m'
REVERSED='\033[7m'
NC='\033[0m' # No color

# lolcat detection
USE_LOLCAT=false
if command -v lolcat &>/dev/null; then
    USE_LOLCAT=true
fi
```

---

## Output Helpers

Every script includes these three functions:

```bash
error()    { echo -e "${RED}Error: $*${NC}" >&2; }
progress() { echo -e "${ORANGE}$*${NC}"; }
success()  {
    if $USE_LOLCAT; then
        echo "$*" | lolcat -S 11
    else
        echo -e "${REVERSED}$*${NC}"
    fi
}
```

### Usage Rules
- **Errors:** `error()` → RED to stderr
- **Progress/warnings:** `progress()` → ORANGE
- **Success:** `success()` → lolcat with seed 11, or REVERSED text as fallback
- Every significant step gets a progress echo
- Use step counters: `progress "[3/9] Cleaning apt cache..."`

---

## Standard Guards

### Root Check (required in every script)
```bash
if [[ "${EUID}" -ne 0 ]]; then
    error "This script must be run as root."
    exit 1
fi
```

### Dependency Check
```bash
if ! command -v asterisk &>/dev/null; then
    error "asterisk binary not found. Is PBXact installed?"
    exit 1
fi
```

---

## File & Naming Conventions

| Item | Convention |
|------|-----------|
| Script permissions | `chmod 700` always |
| Date format | DDMMMYY with abbreviated month in caps (e.g., `22FEB26`) |
| AMI names | `pbxact17-gm-debian12-DDMMMYY` |
| Scripts on GM | `/root/` |
| Post-record scripts | `/usr/local/sbin/` |
| Ownership | `root:root` unless script runs as asterisk |

---

## Box-Style Warning Output

For destructive operations:

```bash
echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                  !!  WARNING  !!                            ║${NC}"
echo -e "${RED}║                                                              ║${NC}"
echo -e "${RED}║  This script will:                                           ║${NC}"
echo -e "${RED}║    - [action 1]                                              ║${NC}"
echo -e "${RED}║    - [action 2]                                              ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
```

Count characters carefully for proper box alignment.

---

## Countdown Pattern

For scripts with irreversible actions (shutdown, destructive cleanup):

```bash
for i in $(seq 30 -1 1); do
    if $USE_LOLCAT; then
        echo "Shutting down in ${i}..." | lolcat -S $((i * 3))
    else
        echo -e "${ORANGE}Shutting down in ${i}...${NC}"
    fi
    sleep 1
done
```

The rotating lolcat seed (`-S $((i * 3))`) creates a color-shifting countdown.

---

## Double Confirmation Pattern

For destructive scripts, require two confirmations:

```bash
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm1
if [[ "${confirm1}" != "yes" ]]; then
    error "Aborted by user."
    exit 1
fi

echo ""
read -p "This action is IRREVERSIBLE. Type 'CONFIRM' to continue: " confirm2
if [[ "${confirm2}" != "CONFIRM" ]]; then
    error "Aborted by user."
    exit 1
fi
```

---

## Complete Script Skeleton

```bash
#!/bin/bash
###############################################################
# Script Name   : example.sh
# Author        : Aaron Salsitz
# Organization  : ICCI, LLC
# Title         : Master Bit Herder
# Created Date  : 2026-03-01
# Version       : 1.0
# Contributors  : Claude (Anthropic)
# Description   : [Description here]
# Usage         : ./example.sh
# Notes         : Run as root on PBXact 17 / Debian 12.
#
# License       : Creative Commons Attribution 4.0 International
#                 (CC BY 4.0) — You are free to share and adapt
#                 this work provided appropriate credit is given
#                 to ICCI, LLC and the original authors.
#                 https://creativecommons.org/licenses/by/4.0/
#
# Changes v1.0  : Initial release.
###############################################################

# Color definitions
RED='\033[1;31m'
ORANGE='\033[0;33m'
REVERSED='\033[7m'
NC='\033[0m'

# lolcat detection
USE_LOLCAT=false
if command -v lolcat &>/dev/null; then
    USE_LOLCAT=true
fi

# Output helpers
error()    { echo -e "${RED}Error: $*${NC}" >&2; }
progress() { echo -e "${ORANGE}$*${NC}"; }
success()  {
    if $USE_LOLCAT; then
        echo "$*" | lolcat -S 11
    else
        echo -e "${REVERSED}$*${NC}"
    fi
}

#---------------------------------------------------------------
# Root check
#---------------------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    error "This script must be run as root."
    exit 1
fi

#---------------------------------------------------------------
# Dependency checks
#---------------------------------------------------------------
# Add checks for required binaries here

#---------------------------------------------------------------
# Main
#---------------------------------------------------------------
progress "[1/N] Doing the thing..."

# ... work ...

success "Done."
exit 0
```
