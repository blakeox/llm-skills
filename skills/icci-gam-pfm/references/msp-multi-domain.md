# MSP Multi-Domain Operations — GAM Reference

## Domain Switching

```bash
# Run command against specific domain
~/bin/gam7/gam select icci print users
~/bin/gam7/gam select stpatschool print users
~/bin/gam7/gam select dahlmannproperties info domain

# Set default context (persists across commands)
~/bin/gam7/gam select icci save
```

## ICCI Domain Architecture

Two types of managed domains:

### Reseller Domains (shared admin OAuth)
All 24 reseller customers use the shared `oauth2.txt` authenticated as an @icci.com admin. The reseller relationship grants admin API access.

### Non-Profit Domains (per-domain admin OAuth)
5 school/church domains each have their own `oauth2_*.txt` because they're not reseller customers. These tokens authenticate as each domain's super admin.

## Cross-Domain Reporting

```bash
# User counts across all domains
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent stpatschool stpaul stmary stjos okf; do
    count=$(~/bin/gam7/gam select $section print users 2>/dev/null | tail -n +2 | wc -l)
    echo "$section: $count users"
done

# MFA status sweep
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent stpatschool stpaul stmary stjos okf; do
    echo "=== $section ==="
    ~/bin/gam7/gam select $section print users fields primaryEmail,isEnrolledIn2Sv \
        query "isEnrolledIn2Sv=false" 2>/dev/null | tail -n +2
done

# Login reports for all clients
DATE=$(date +%Y-%m-%d)
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent; do
    ~/bin/gam7/gam select $section redirect csv "./${section}_login_${DATE}.csv" \
        report login start -30d 2>/dev/null
done
```

## Adding Reseller Domains to gam.cfg

Many reseller domains don't have gam.cfg sections yet. To add one:

```ini
# In ~/.gam/gam.cfg:
[sectionname]
domain = clientdomain.com
customer_id = C0xxxxxxx
```

Find customer IDs: `~/bin/gam7/gam print channelcustomers fields name,domain`

No additional OAuth setup needed — the shared `oauth2.txt` works via the reseller relationship. Just need DwD scopes authorized in their Admin Console.

## Adding Non-Profit Domains

See `references/team-setup.md` for full procedure. Summary:
1. Add section with `admin_email` and `oauth2_txt`
2. Authorize DwD scopes
3. Trust GAM OAuth app
4. Run `gam select section oauth create --no-browser`
5. Copy token to credentials/ and sync to GitHub

## Domain Permission Mapping (Cross-Domain Migration)

```bash
# When moving files across domains, map permissions
gam user admin@newdomain.com add drivefileacl id FILEID \
    user colleague@olddomain.com role writer \
    mappermissionsdomain olddomain.com newdomain.com
```
