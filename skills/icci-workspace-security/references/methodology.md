# Google Workspace Security Audit Methodology

## Overview

This document defines the phased analysis workflow for Google Workspace security assessments. Follow these phases in order. Each phase builds on the previous one.

---

## Phase 1: Data Collection

### 1.1 Scope Definition
- Identify all Google Workspace domains in scope
- Determine the incident trigger (if any): compromised account, suspicious activity alert, routine audit
- Define the analysis window (default: 180 days for login events, narrower for forensics)

### 1.2 GAM Data Pull (Preferred)
If GAM is configured for the client domain, pull data programmatically. See `gam-commands.md`.

```bash
# Verify GAM access
~/bin/gam7/gam info domain

# Pull login events (all users, 180 days)
~/bin/gam7/gam report login start -180d > login_events.csv

# Pull MFA status
~/bin/gam7/gam print users fields name,email,isEnforcedIn2Sv,isEnrolledIn2Sv > mfa_status.csv

# Pull OAuth tokens
~/bin/gam7/gam all users print tokens > oauth_tokens.csv
```

### 1.3 Manual CSV Export (Fallback)
If GAM is not configured, guide the user through Admin Console exports:

1. **Login events**: Admin Console > Reporting > Audit and investigation > Login audit log
   - Filter: All users, last 180 days (or custom range)
   - Export as CSV
   - Repeat for each domain

2. **OAuth events**: Admin Console > Reporting > Audit and investigation > Token audit log
   - Export for each domain

3. **Drive events**: Admin Console > Reporting > Audit and investigation > Drive log events
   - For incident response: filter by affected user and date range
   - Export for each domain

4. **Gmail events**: Admin Console > Reporting > Audit and investigation > Gmail log events
   - For incident response: filter by affected user and date range
   - WARNING: Gmail exports can be very large (100K+ records, 80MB+)

### 1.4 File Organization
```
~/Documents/claude-code/{FQDN}/
├── {CLIENT}_login_events.csv
├── {CLIENT}_mfa_status.csv
├── {CLIENT}_oauth_tokens.csv
├── {CLIENT}_admin_audit.csv
├── {CLIENT}_drive_audit.csv
├── {CLIENT}_gmail_audit.csv
├── analyze_logins.py       (generated per engagement)
├── analyze_deep.py         (generated per engagement)
├── generate_pdf.py         (generates PDF directly, no HTML output)
├── {CLIENT}_Executive_Report.pdf
└── {CLIENT}_Technical_Reference.md
```
Note: Use the client's short name (not FQDN) for file prefixes within the directory.

---

## Phase 2: Login Event Analysis

### 2.1 Initial Parse
```python
# Parse CSV, handle embedded JSON in Network info
# Detect JSON schema variant (IP ASN vs City/State/Country)
# Print summary: record count, date range, distinct users, event types
```

### 2.2 ASN Classification
For every unique IP in the dataset:
1. Extract ASN from Network info JSON (if available)
2. If ASN not in JSON, perform WHOIS lookup
3. Classify as LEGITIMATE (residential ISP, cellular, business) or ATTACK (hosting, VPN, cloud)
4. See `asn-classification.md` for the maintained database

**Critical**: This step determines the accuracy of the entire analysis. Misclassifying a property's ISP as an attacker will inflate attack numbers and undermine credibility.

### 2.3 Traffic Separation
Split all events into two buckets:
- **Legitimate traffic**: Events from known property/staff ASNs. Failed logins here are genuine user errors.
- **Attack traffic**: Events from hosting/VPN/cloud ASNs. These are the real threats.

### 2.4 Attack Analysis
On attack traffic only:
- **Successful logins**: CRITICAL — confirmed compromise. Record IP, ASN, timestamp, user.
- **Failed logins**: Credential guessing/stuffing. Count by target account, source ASN.
- **MFA blocks**: Where MFA stopped the attacker. These are proof points for the MFA case.
- **Cross-domain hits**: Same ASN/IP range hitting multiple domains = coordinated targeting.

### 2.5 Burst Detection
- Sliding window: 10-minute window, threshold of 5+ events
- Identifies automated credential-stuffing attacks
- Record burst windows with source IPs and target accounts

### 2.6 Newness Detection
For each event, flag if the IP, geo, or user agent is being seen for the first time:
- First-seen per domain
- First-seen globally (across all domains)
- Sudden appearance of new infrastructure during a specific window = suspicious

---

## Phase 3: Deep Forensics (Compromise Confirmed)

Only proceed to this phase if Phase 2 found a confirmed successful login from attack infrastructure.

### 3.1 Define Compromise Window
- **Start**: Timestamp of successful attacker login
- **End**: Timestamp of password reset / token revocation
- This is the window during which the attacker had access

### 3.2 OAuth Token Analysis
Pull OAuth events for the affected domain. Check for:
- **Attacker session tokens**: Chrome sign-in tokens issued to attacker IPs
- **Rogue third-party app grants**: New OAuth apps authorized during/after compromise
- **Overly broad existing grants**: Migration tools, third-party apps with full mail/drive access
- **Token revocation timing**: When was the attacker's token revoked?

### 3.3 Drive Activity Analysis
Pull Drive audit for the compromised user, filtered to the compromise window (plus 2 days before/after).
- **Attacker IP events**: Any Drive activity from attack ASNs = data access confirmed
- **Downloads during window**: What files were downloaded? From which IPs?
- **Sharing changes**: Were any files shared externally during the window?
- **New file creation**: Were any files created (potential staging for exfiltration)?

### 3.4 Gmail Activity Analysis
Pull Gmail audit for the compromised user, filtered to the compromise window (plus 2 days before/after).
- **Attacker IP events**: Any Gmail activity from attack ASNs
- **Forwarding rules**: Were any email forwarding rules created?
- **Delegation changes**: Were any delegates added?
- **Sends from attacker**: Did the attacker send email as the compromised user?
- **Link clicks**: Were any phishing links clicked during the window?

### 3.5 Post-Compromise User Behavior
Look for signs the user noticed the compromise:
- Password changes
- Checking forwarding settings
- Unusual login patterns (e.g., logging in from multiple devices rapidly)

---

## Phase 4: MFA Gap Analysis

### 4.1 User Enumeration
For each domain in scope:
```bash
~/bin/gam7/gam print users fields name,email,isEnforcedIn2Sv,isEnrolledIn2Sv
```
Or from login events: identify all unique users and their challenge types.

### 4.2 MFA Classification
| Challenge Type | MFA Strength | Classification |
|---|---|---|
| Passkey / FIDO2 | Strongest | Phishing-resistant |
| Security Key | Strong | Phishing-resistant |
| Google Prompt | Good | Push notification (MFA fatigue risk) |
| Google Authenticator | Good | TOTP |
| SMS / Voice | Weak | SIM-swap vulnerable |
| Backup codes only | Weak | Static codes |
| None / No challenge | **None** | Password-only |

### 4.3 Risk Categorization
Prioritize unprotected accounts by risk:
1. **Admin accounts** without MFA — catastrophic risk
2. **Shared/role accounts** (frontdesk@, info@, admin@) — high risk, high attack volume
3. **Executive accounts** — high-value targets
4. **Individual user accounts** — standard risk
5. **Service accounts** — typically lower risk but check OAuth scopes

### 4.5 Shared Account Analysis
Shared/role accounts (frontdesk@, vettech@, info@, reception@) require special attention:
- **Multiple people sharing one password** = larger attack surface (more people who can leak it)
- **Backup codes are the weakest MFA** — static, printable, easily photographed. On shared accounts, backup codes are often posted near the workstation for convenience. This was the attack vector in WVH-2026-03 (frontdesk@ compromised via VPN + backup code).
- **Exchange/IMAP sync generates noise** — shared account workstations with always-on email clients produce automated `login_type=exchange` events 24/7 from the static office IP. Filter these when analyzing interactive login patterns.
- **Cannot attribute logins** — when a shared account is compromised, you cannot determine who leaked the credentials. This is a fundamental limitation.
- **High failure rates are normal** — 10-15% login failure rate on shared accounts is typical (multiple people entering different passwords). Do not confuse this with credential attacks.
- **Recommendation**: Always recommend migrating shared accounts to individual accounts with a shared mailbox/Google Group. This is the single most impactful security improvement for small practices.

### 4.4 Coverage Metrics
Calculate per domain:
- Total users
- Users with strong MFA (Passkey/FIDO2/Security Key)
- Users with any MFA (including Prompt/TOTP)
- Users with no MFA
- Coverage percentage

---

## Phase 5: Report Generation

### 5.1 Executive PDF Report
Use the ICCI-branded HTML template. Target audience: business owners and executives.
- Lead with the confirmed incident (if any)
- Show the numbers: attack events, MFA gaps, cross-domain targeting
- Include industry breach comparisons (see `industry-context.md`)
- Make the case for MFA with proof from the client's own data
- Include prioritized recommendations

Generate via:
```bash
python scripts/gw-report.py --client "{CLIENT}" --input-dir ~/Documents/claude-code/{FQDN}/
```

### 5.2 ICCI Technical Reference
Generate a comprehensive markdown file for ICCI internal records:
- Full IOC table (all attack IPs, ASNs, WHOIS data)
- Complete forensic analysis details
- Traffic classification methodology and results
- All remediation items with status
- Lessons learned for future engagements

### 5.3 PDF Generation
```bash
weasyprint {CLIENT}_Executive_Report.html {CLIENT}_Executive_Report.pdf
```

---

## Phase 6: Self-Improvement

After every engagement, update the skill:

### What to Update
| Finding | Update Target |
|---|---|
| New attack ASNs observed | `references/asn-classification.md` |
| New CSV format variations | `scripts/gw-audit.py` + SKILL.md CSV reference |
| New report sections needed | `references/report-sections.md` |
| New industry breach examples | `references/industry-context.md` |
| New GAM commands discovered | `references/gam-commands.md` |
| Methodology gaps identified | `references/methodology.md` |

### Sync to GitHub
After updates:
```bash
cp -r ~/.claude/skills/icci-workspace-security/* ~/Documents/GitHub/icci-skills/skills/icci-workspace-security/
cd ~/Documents/GitHub/icci-skills && git add -A && git commit -m "Update workspace security skill" && git push
```
