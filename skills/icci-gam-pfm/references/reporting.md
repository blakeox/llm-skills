# Reporting — GAM Reference

## Activity Reports

```bash
# Login activity
gam report login todrive
gam report login start -30d todrive
gam report login user jsmith@domain.com todrive
gam report login events login_success,login_failure todrive
gam report login start -90d end -30d todrive

# Admin activity
gam report admin todrive
gam report admin start -90d todrive
gam report admin filter "event==CHANGE_PASSWORD" todrive

# Drive activity
gam report drive todrive
gam report drive user jsmith@domain.com start -30d todrive
gam report drive filter "event==change_user_access" todrive

# Gmail activity
gam report gmail todrive
gam report gmail user jsmith@domain.com start -30d todrive

# Chrome activity
gam report chrome todrive

# Calendar activity
gam report calendar todrive

# Token/OAuth activity
gam report tokens todrive

# SAML activity
gam report saml todrive

# Meet activity
gam report meet todrive
```

Available report types: access, admin, calendar, chat, chrome, devices, domain, drive, gcp, groups, login, meet, rules, saml, tokens, vault

## Usage Reports

```bash
# Customer-level usage
gam report customer todrive
gam report customer range 2026-02-01 2026-02-28 todrive
gam report customer services gmail,drive,calendar todrive

# User-level usage
gam report user todrive
gam report user user jsmith@domain.com todrive
gam report user orgunit "/Staff" todrive
gam report user services gmail,drive todrive

# Storage usage
gam report usage customer convertmbtogb todrive
gam report usage user todrive
```

## Output Options

```bash
# Direct to Google Drive
gam report login todrive tdtitle "Login Report" tdparent "FOLDER_ID"

# To local CSV with redirect
gam redirect csv ./login_report.csv report login start -30d

# To CSV with error logging
gam redirect csv ./report.csv redirect stderr ./errors.log report login

# Filter output columns
gam report login todrive fields actor.email,id.time,ipAddress,name,is_suspicious
```

## Cross-Domain Reporting Script

```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent; do
    echo "Pulling login report for $section..."
    ~/bin/gam7/gam select $section redirect csv "./${section}_login_${DATE}.csv" \
        report login start -30d
done
echo "Done. Reports saved to current directory."
```
