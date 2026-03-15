# GAM Commands for Google Workspace Security Audits

## Prerequisites

- GAM 7 installed at `~/bin/gam7/gam`
- GAM must be configured with service account credentials for the target domain
- Check status: `~/bin/gam7/gam info domain`
- Multi-customer: `~/bin/gam7/gam print channelcustomers fields name,domain`

---

## Data Collection Commands

### Login / Authentication Events
```bash
# All login events, last 180 days
~/bin/gam7/gam report login start -180d > {CLIENT}_login_events.csv

# Login events for specific user
~/bin/gam7/gam report login user {user@domain.com} start -180d > {USER}_login_events.csv

# Login events filtered by event type
~/bin/gam7/gam report login start -180d filter "event==login_failure" > {CLIENT}_failed_logins.csv

# Suspicious login events only
~/bin/gam7/gam report login start -180d filter "is_suspicious==true" > {CLIENT}_suspicious.csv
```

### MFA / 2-Step Verification Status
```bash
# All users with MFA enrollment status
~/bin/gam7/gam print users fields primaryEmail,name,isEnforcedIn2Sv,isEnrolledIn2Sv > {CLIENT}_mfa_status.csv

# Detailed user security info
~/bin/gam7/gam print users fields primaryEmail,name,isEnforcedIn2Sv,isEnrolledIn2Sv,lastLoginTime,creationTime,suspended > {CLIENT}_users_security.csv
```

### OAuth Token Grants
```bash
# All OAuth tokens for all users
~/bin/gam7/gam all users print tokens > {CLIENT}_oauth_tokens.csv

# OAuth tokens for specific user
~/bin/gam7/gam user {user@domain.com} print tokens > {USER}_oauth_tokens.csv

# Show detailed token info including scopes
~/bin/gam7/gam all users show tokens > {CLIENT}_oauth_detailed.txt
```

### Drive Audit
```bash
# Drive activity for specific user (last 30 days)
~/bin/gam7/gam report drive user {user@domain.com} start -30d > {USER}_drive_audit.csv

# Drive activity for all users
~/bin/gam7/gam report drive start -30d > {CLIENT}_drive_audit.csv

# Drive file sharing activity only
~/bin/gam7/gam report drive start -30d filter "event==change_user_access" > {CLIENT}_drive_sharing.csv
```

### Gmail Audit
```bash
# Gmail activity for specific user (last 30 days)
~/bin/gam7/gam report gmail user {user@domain.com} start -30d > {USER}_gmail_audit.csv

# Gmail activity for all users
~/bin/gam7/gam report gmail start -30d > {CLIENT}_gmail_audit.csv
```

### Admin Activity
```bash
# Admin console activity (user management, security changes)
~/bin/gam7/gam report admin start -180d > {CLIENT}_admin_audit.csv

# Specifically look for password resets, MFA changes
~/bin/gam7/gam report admin start -180d filter "event==CHANGE_PASSWORD" > {CLIENT}_password_resets.csv
```

### Groups and Shared Access
```bash
# List all groups
~/bin/gam7/gam print groups fields email,name,directMembersCount > {CLIENT}_groups.csv

# Group members (for shared account analysis)
~/bin/gam7/gam print group-members group {group@domain.com} > {GROUP}_members.csv
```

---

## Multi-Domain Operations

When a client has multiple Workspace domains:

```bash
# List all customer domains
~/bin/gam7/gam print channelcustomers fields name,domain

# Switch GAM context to a different domain (if configured)
# GAM typically needs separate project/credentials per domain
# For multi-domain clients, run commands per domain and merge results
```

---

## Incident Response Quick Commands

```bash
# 1. Check if specific IP has logged into any account
~/bin/gam7/gam report login start -180d filter "ipAddress=={ATTACKER_IP}" > {IP}_activity.csv

# 2. Force password reset for compromised user
~/bin/gam7/gam user {user@domain.com} update password random changepasswordatnextlogin

# 3. NUCLEAR OPTION: Revoke all tokens, backup codes, app passwords, and sign out
# This is the single best incident response command — does everything in one shot.
# Revokes: OAuth tokens (third-party), backup verification codes, app-specific passwords.
# Does NOT revoke: Google first-party tokens (Chrome, iOS Account Manager, Android device).
~/bin/gam7/gam user {user@domain.com} deprovision

# 4. Sign out all sessions for compromised user (if deprovision alone isn't enough)
~/bin/gam7/gam user {user@domain.com} signout

# 4a. Regenerate backup codes (after deprovision invalidated the compromised set)
~/bin/gam7/gam user {user@domain.com} update backupcodes

# 5. Check if user has forwarding rules
~/bin/gam7/gam user {user@domain.com} show forward
~/bin/gam7/gam user {user@domain.com} show filters

# 6. Disable forwarding
~/bin/gam7/gam user {user@domain.com} forward off

# 7. Enforce MFA for specific user
~/bin/gam7/gam user {user@domain.com} update is2svenforced true
```

---

## Output Format Notes

- GAM CSV output uses standard comma-separated format
- Timestamps are typically in UTC (ISO 8601)
- Large exports may take several minutes
- For Gmail/Drive with 100K+ events, add `maxresults` to limit or use date filters
