# sngrep — SIP Packet Capture and Dialog Viewer

The most useful SIP diagnostic tool on the box. Full-screen ncurses UI that captures
live SIP traffic and displays it as dialog flows — showing the full SIP conversation
between Asterisk and Telnyx (or any endpoint) in real time.

Essential for diagnosing registration failures, one-way audio, INVITE/BYE sequencing
issues, and SRTP negotiation problems.

---

## Quick Start

```bash
# Basic launch — captures all SIP traffic
sngrep

# Filter to a specific IP (e.g., Telnyx SIP edge)
sngrep host 192.168.1.1

# Filter to SIP port only
sngrep port 5060

# Capture to file for offline review
sngrep -O /tmp/capture.pcap

# Read a previously saved capture
sngrep -I /tmp/capture.pcap

# Combine filters
sngrep host 192.168.1.1 and port 5060
```

---

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Open selected dialog — shows full SIP message flow |
| `F1` | Help |
| `F2` | Save capture to file |
| `F3` | Search / filter dialogs |
| `F4` | Toggle between dark/light display |
| `F5` | Toggle display of RTP streams alongside SIP |
| `F7` | Filter — enter a BPF expression (e.g., `host 192.168.1.1`) |
| `F8` | Toggle display of alias/resolved hostnames |
| `Tab` | Switch between dialog list and flow view |
| `Arrow keys` | Navigate dialogs |
| `Space` | Select/deselect a dialog |
| `q` | Quit |

---

## What to Look For — Common PBXact 17 / Telnyx Scenarios

| Symptom | What to look for in sngrep |
|---------|---------------------------|
| Trunk not registering | Find the REGISTER dialog — look for 401/403/408 responses from Telnyx |
| Inbound calls not arriving | No INVITE appearing from Telnyx — likely firewall or wrong IP whitelist |
| Outbound calls failing | Find the INVITE — look at the response code (403 = auth, 503 = capacity, 488 = codec mismatch) |
| One-way audio | INVITE and 200 OK present but check SDP — look for mismatched RTP IP/port or SRTP crypto lines |
| Call drops after ~30 seconds | Look for re-INVITE or BYE — often a NAT or media timeout issue |
| SRTP negotiation failure | Look for `488 Not Acceptable Here` — crypto lines in SDP are mismatched between Asterisk and Telnyx |
| Audio quality issues | Press F5 to toggle RTP display — check for packet loss, jitter, out-of-order packets |

---

## Reading SDP (Session Description Protocol) in sngrep

When you open a dialog and look at the INVITE or 200 OK, the SDP section tells you
everything about the media negotiation. Key lines to check:

```
m=audio <port> RTP/SAVP <codec-ids>     ← RTP/SAVP means SRTP; RTP/AVP means unencrypted
a=rtpmap:9 G722/8000                     ← G.722 offered
a=rtpmap:0 PCMU/8000                     ← ulaw offered
a=crypto:1 AES_CM_128_HMAC_SHA1_80 ...  ← SRTP crypto line
c=IN IP4 <ip-address>                    ← Where RTP is expected (check for NAT issues)
```

**Red flags in SDP:**
- `RTP/AVP` instead of `RTP/SAVP` when SRTP is required → encryption not negotiating
- Missing `a=crypto` lines → SRTP not offered
- `c=IN IP4` showing a private IP (10.x, 172.x, 192.168.x) when it should be public → NAT issue
- Opus codec IDs appearing when they shouldn't be (Opus = dynamic payload type, usually 111 or 116)

---

## Tips for Use on AWS

- sngrep captures on the interface level — on AWS with a single ENI, it sees
  everything on eth0/ens5
- If running inside tmux (which you should be), sngrep's full-screen mode works
  fine but make sure your terminal is wide enough for the message flow view
- Save captures before closing: F2 writes to pcap format which you can also open
  in Wireshark later if you pull the file off the server
- For intermittent issues: run `sngrep -O /tmp/sip-debug-$(date +%s).pcap` in a
  tmux pane and let it capture while reproducing the issue

---

## Example Troubleshooting Workflow

**Problem:** Outbound calls failing after migration to PBXact 17

```bash
# 1. Start sngrep
sngrep

# 2. Make a test call from a phone

# 3. In sngrep, find the INVITE dialog (should appear almost immediately)

# 4. Press Enter to open the dialog flow

# 5. Look at the response from Telnyx:
#    - 100 Trying → good, Telnyx received it
#    - 403 Forbidden → authentication/IP whitelist issue
#    - 488 Not Acceptable → codec or SRTP mismatch
#    - 503 Service Unavailable → Telnyx capacity issue

# 6. If 488, open the INVITE and check SDP:
#    - Is G.722 offered? (should be)
#    - Is SRTP crypto line present? (should be)
#    - Is Opus listed? (should NOT be)

# 7. Compare with the 488 response SDP (if present) to see what Telnyx expected
```

---

## Installation

sngrep should be pre-installed. If missing:

```bash
apt install -y sngrep
```
