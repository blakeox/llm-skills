# Security & MFA — GAM Reference

## 2SV/MFA Status

```bash
# Print enrollment status for all users
gam print users fields primaryEmail,isEnrolledIn2Sv,isEnforcedIn2Sv todrive

# Specific OU
gam print users limittoou "/Staff" fields primaryEmail,isEnrolledIn2Sv,isEnforcedIn2Sv

# Users NOT enrolled
gam print users fields primaryEmail,name query "isEnrolledIn2Sv=false"
```

## Backup Codes

```bash
# Generate new backup codes
gam user jsmith@domain.com update backupcodes

# Show backup codes
gam user jsmith@domain.com show backupcodes

# Delete backup codes
gam user jsmith@domain.com delete backupcodes

# Bulk generate for OU
gam ou "/Staff" update backupcodes
```

## Signout and 2SV Reset

```bash
# Force signout all sessions
gam user jsmith@domain.com signout

# Turn off 2SV (removes all second factors)
gam user jsmith@domain.com turnoff2sv

# Bulk signout for OU
gam ou "/Compromised" signout
```

## Application-Specific Passwords (ASPs)

```bash
# List ASPs for a user
gam user jsmith@domain.com show asps

# Delete a specific ASP by codeId
gam user jsmith@domain.com delete asp CODEID
```

**GAM CANNOT create app passwords.** Google's Directory API only supports `list` and `delete`
for ASPs — there is no `create` endpoint. App passwords must be generated interactively by
logging into the user's account at https://myaccount.google.com/apppasswords.

**Prerequisites for app passwords:**
- 2SV must be enrolled and enforced on the account
- If 2SV was turned off during incident response (`deprovision` includes `turnoff2sv`),
  it must be re-enabled before app passwords can be created

**Post-incident app password recovery workflow:**
1. Verify 2SV is still enrolled: `gam print users query "email:user@domain.com" fields isEnrolledIn2Sv,isEnforcedIn2Sv`
2. If 2SV was disabled, user must re-enroll before creating app passwords
3. Log into the account (directly or via remote access like ScreenConnect) and create the app password at myaccount.google.com/apppasswords
4. Store the generated password in 1Password

## Full Deprovision (Security Lockdown)

```bash
# Delete app passwords, backup codes, tokens, disable POP/IMAP, signout, turn off 2SV
gam user jsmith@domain.com deprovision popimap signout turnoff2sv
```

**Note:** `deprovision` deletes all ASPs. If the account uses app passwords for legacy systems
(e.g., ImproMed, old copier/scanners), you will need to regenerate them manually after
the incident is resolved. Document which services use app passwords BEFORE deprovisioning.

## OAuth Token Management

```bash
# Show all third-party tokens for user
gam user jsmith@domain.com show tokens

# All users' tokens to CSV
gam all users print tokens todrive

# Aggregate by app name
gam all users print tokens aggregateusersby appname todrive

# Delete specific app token
gam user jsmith@domain.com delete token clientid CLIENTID

# Token counts per user
gam all users print tokens usertokencounts todrive
```

## Incident Response Combo

```bash
# Full lockdown of compromised account
gam user COMPROMISED@domain.com deprovision popimap signout turnoff2sv && \
gam update user COMPROMISED@domain.com password random changepasswordatnextlogin && \
gam user COMPROMISED@domain.com forward false
```
