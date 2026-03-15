#!/bin/bash
###############################################################
# Script Name   : pre-migration-analysis.sh
# Author        : Aaron Salsitz
# Organization  : ICCI, LLC
# Title         : Master Bit Herder
# Created Date  : 2026-02-25
# Version       : 1.0
# Contributors  : Claude (Anthropic)
# Description   : Comprehensive 13-section pre-migration audit
#                 for PBXact systems. Captures system state,
#                 module inventory, extensions, trunks, codecs,
#                 recordings, VPN, network, and storage info.
#                 Run on the SOURCE system before any migration.
# Usage         : ./pre-migration-analysis.sh [output-file]
#                 If output-file is provided, results are saved
#                 there in addition to stdout.
# Notes         : Run as root on the source PBXact system.
#                 Safe to run on production — read-only queries.
#
# License       : Creative Commons Attribution 4.0 International
#                 (CC BY 4.0) — You are free to share and adapt
#                 this work provided appropriate credit is given
#                 to ICCI, LLC and the original authors.
#                 https://creativecommons.org/licenses/by/4.0/
#
# Changes v1.0  : Initial release. 13-section analysis covering
#                 system ID, modules, extensions, trunks, codecs,
#                 recordings, voicemail, VPN, network, scripts,
#                 backups, EPM, and disk space.
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
# Dependency check
#---------------------------------------------------------------
if ! command -v asterisk &>/dev/null; then
    error "asterisk binary not found. Is PBXact installed?"
    exit 1
fi

if ! command -v fwconsole &>/dev/null; then
    error "fwconsole not found. Is FreePBX/PBXact installed?"
    exit 1
fi

#---------------------------------------------------------------
# Optional output file
#---------------------------------------------------------------
OUTPUT_FILE="${1:-}"
if [[ -n "${OUTPUT_FILE}" ]]; then
    progress "Saving output to: ${OUTPUT_FILE}"
    exec > >(tee -a "${OUTPUT_FILE}") 2>&1
fi

#---------------------------------------------------------------
# Header
#---------------------------------------------------------------
echo ""
echo "============================================================"
echo "  ICCI PBXact Pre-Migration Analysis"
echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  Host: $(hostname -f 2>/dev/null || hostname)"
echo "============================================================"
echo ""

#---------------------------------------------------------------
# Section 1: System Identification
#---------------------------------------------------------------
progress "[1/13] System Identification"
echo "------------------------------------------"
echo "Hostname: $(hostname -f 2>/dev/null || hostname)"
echo ""
echo "PBXact/FreePBX Version:"
cat /etc/sangoma/pbx-version 2>/dev/null || echo "  Version file not found at /etc/sangoma/pbx-version"
fwconsole sa info 2>/dev/null | grep -iE "deployment|version|activation" || echo "  sysadmin info unavailable"
echo ""
echo "Asterisk Version:"
asterisk -rx "core show version" 2>/dev/null
echo ""
echo "Operating System:"
cat /etc/os-release 2>/dev/null | head -5
echo ""
echo "Kernel:"
uname -r
echo ""
echo "Uptime:"
uptime
echo ""

#---------------------------------------------------------------
# Section 2: Module Inventory
#---------------------------------------------------------------
progress "[2/13] Module Inventory"
echo "------------------------------------------"
fwconsole ma list 2>/dev/null
echo ""

#---------------------------------------------------------------
# Section 3: Extension Analysis
#---------------------------------------------------------------
progress "[3/13] Extension Analysis"
echo "------------------------------------------"
echo "--- PJSIP Extensions ---"
asterisk -rx "pjsip show endpoints" 2>/dev/null || echo "  No PJSIP endpoints found"
echo ""
echo "--- chan_sip Extensions (legacy) ---"
asterisk -rx "sip show peers" 2>/dev/null || echo "  chan_sip not loaded (expected on PBXact 17)"
echo ""
echo "Extension count:"
asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "Endpoint:" || echo "  0 PJSIP endpoints"
asterisk -rx "sip show peers" 2>/dev/null | tail -1 || echo "  0 chan_sip peers"
echo ""

#---------------------------------------------------------------
# Section 4: Trunk Analysis
#---------------------------------------------------------------
progress "[4/13] Trunk Analysis"
echo "------------------------------------------"
echo "--- PJSIP Registrations ---"
asterisk -rx "pjsip show registrations" 2>/dev/null || echo "  No PJSIP registrations"
echo ""
echo "--- chan_sip Registry (legacy) ---"
asterisk -rx "sip show registry" 2>/dev/null || echo "  chan_sip not loaded"
echo ""
echo "--- Active Channels ---"
asterisk -rx "core show channels concise" 2>/dev/null
echo ""

#---------------------------------------------------------------
# Section 5: Codec Check
#---------------------------------------------------------------
progress "[5/13] Codec Check"
echo "------------------------------------------"
echo "Loaded codecs (looking for g722, ulaw, opus):"
asterisk -rx "core show codecs" 2>/dev/null | grep -iE "opus|g722|ulaw|alaw|g729"
echo ""
echo "SIP allow setting (from database):"
mysql -u root -sN -e "SELECT CONCAT(keyword, ' = ', value) FROM asterisk.freepbx_settings WHERE keyword LIKE '%ALLOW%' OR keyword LIKE '%allow%';" 2>/dev/null || echo "  Database query failed"
echo ""
echo "*** WARNING CHECK: Is Opus present? ***"
OPUS_CHECK=$(asterisk -rx "core show codecs" 2>/dev/null | grep -ic opus)
if [[ "${OPUS_CHECK}" -gt 0 ]]; then
    echo -e "${RED}  !! OPUS IS LOADED — Must be removed before/after migration !!${NC}"
else
    echo "  Opus is NOT loaded. Good."
fi
echo ""

#---------------------------------------------------------------
# Section 6: Call Recording Status
#---------------------------------------------------------------
progress "[6/13] Call Recording Status"
echo "------------------------------------------"
echo "Recording directory contents (last 5):"
ls -lt /var/spool/asterisk/monitor/ 2>/dev/null | head -6
echo ""
echo "Recording settings (from database):"
mysql -u root -sN -e "SELECT CONCAT(keyword, ' = ', value) FROM asterisk.freepbx_settings WHERE keyword LIKE '%MIXMON%' OR keyword LIKE '%RECORDING%';" 2>/dev/null || echo "  Database query failed"
echo ""
echo "Post-record scripts in /usr/local/sbin/:"
ls -la /usr/local/sbin/*.sh 2>/dev/null || echo "  No .sh files found"
echo ""
echo "Mixmonitor merge script:"
ls -la /var/lib/asterisk/bin/mixmonitor-audio-merge.sh 2>/dev/null || echo "  Not found"
echo ""

#---------------------------------------------------------------
# Section 7: Voicemail
#---------------------------------------------------------------
progress "[7/13] Voicemail Configuration"
echo "------------------------------------------"
VM_COUNT=$(grep -c "^[0-9]" /etc/asterisk/voicemail.conf 2>/dev/null || echo "0")
echo "Voicemail boxes configured: ${VM_COUNT}"
echo ""
echo "Voicemail storage:"
du -sh /var/spool/asterisk/voicemail/ 2>/dev/null || echo "  Voicemail directory not found"
echo ""

#---------------------------------------------------------------
# Section 8: VPN Configuration
#---------------------------------------------------------------
progress "[8/13] VPN Configuration"
echo "------------------------------------------"
echo "OpenVPN service status:"
systemctl status openvpn* 2>/dev/null | head -10 || echo "  No OpenVPN service found"
echo ""
echo "OpenVPN config files:"
ls -la /etc/openvpn/ 2>/dev/null || echo "  /etc/openvpn/ not found"
echo ""
echo "Tunnel interfaces:"
ip addr show 2>/dev/null | grep -A 2 -E "tun|tap" || echo "  No tunnel interfaces found"
echo ""
echo "VPN subnet (if present):"
ip route show 2>/dev/null | grep -E "tun|tap" || echo "  No VPN routes found"
echo ""

#---------------------------------------------------------------
# Section 9: Network Settings
#---------------------------------------------------------------
progress "[9/13] Network Settings"
echo "------------------------------------------"
echo "Interfaces:"
ip addr show 2>/dev/null
echo ""
echo "Default route:"
ip route show default 2>/dev/null
echo ""
echo "DNS:"
cat /etc/resolv.conf 2>/dev/null
echo ""
echo "Firewall module zones:"
fwconsole firewall list 2>/dev/null || echo "  Firewall CLI unavailable"
echo ""

#---------------------------------------------------------------
# Section 10: Custom Scripts
#---------------------------------------------------------------
progress "[10/13] Custom Scripts"
echo "------------------------------------------"
echo "/usr/local/sbin/ contents:"
ls -la /usr/local/sbin/ 2>/dev/null || echo "  Empty or not found"
echo ""
echo "/var/lib/asterisk/bin/ custom scripts:"
ls -la /var/lib/asterisk/bin/ 2>/dev/null | grep -v ".pyc" | grep -v "__pycache__"
echo ""

#---------------------------------------------------------------
# Section 11: Backup Status
#---------------------------------------------------------------
progress "[11/13] Backup Status"
echo "------------------------------------------"
echo "Configured backups:"
fwconsole backup --list 2>/dev/null || echo "  Backup list unavailable"
echo ""
echo "Backup directory (last 5):"
ls -lt /var/spool/asterisk/backup/ 2>/dev/null | head -6
echo ""

#---------------------------------------------------------------
# Section 12: Endpoint Provisioning
#---------------------------------------------------------------
progress "[12/13] Endpoint Provisioning"
echo "------------------------------------------"
echo "EPM module status:"
fwconsole ma list 2>/dev/null | grep -iE "endpoint|epm"
echo ""
echo "TFTP boot directory:"
ls /tftpboot/ 2>/dev/null || echo "  /tftpboot/ not found"
echo ""
echo "Yealink firmware files:"
find /tftpboot/yealink/ -name "*.rom" -o -name "*.bin" 2>/dev/null | head -20
echo ""
echo "Firmware symlinks:"
find /tftpboot/ -type l 2>/dev/null
echo ""

#---------------------------------------------------------------
# Section 13: Disk Space
#---------------------------------------------------------------
progress "[13/13] Disk Space"
echo "------------------------------------------"
df -h
echo ""
echo "Swap status:"
swapon --show 2>/dev/null || echo "  No swap configured"
free -h
echo ""

#---------------------------------------------------------------
# Summary
#---------------------------------------------------------------
echo ""
echo "============================================================"
success "  Pre-migration analysis complete."
echo "============================================================"
echo ""

if [[ -n "${OUTPUT_FILE}" ]]; then
    success "Results saved to: ${OUTPUT_FILE}"
fi

exit 0
