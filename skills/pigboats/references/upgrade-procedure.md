# MediaWiki Tarball Upgrade Procedure

Step-by-step procedure for upgrading PigBoats.COM's MediaWiki installation. This is a tarball-based install (NOT git). Do not skip steps.

## Pre-Upgrade Checklist

- [ ] Current version confirmed (check API: `?action=query&meta=siteinfo`)
- [ ] New version confirmed available at `releases.wikimedia.org/mediawiki/1.43/`
- [ ] Release notes reviewed for breaking changes
- [ ] Pre-work proposal PDF generated and approved by Aaron
- [ ] Helpdesk ticket created

## Phase 0 — Pre-flight

### 1. Incremental Plesk Backup

```bash
ssh root@54.208.34.75 "plesk bin pleskbackup --domains-name a-gang.pigboats.com -incremental -v -output-file /mnt/plesk_backups/ -d 'Pre-upgrade MW <OLD> to <NEW> backup'"
```

Verify: `ssh root@54.208.34.75 "find /mnt/plesk_backups/ -name '*pigboats*' -mmin -10"`

### 2. Database Dump

```bash
ssh root@54.208.34.75 "mysqldump -u pbc_belikekelp -p'KRb-oRqMFGjzJELFuAkr6_VXt2' pigboats_32a8Pa9avV | gzip > /root/migration/db-pre-upgrade-\$(date +%Y%m%d).sql.gz"
```

### 3. Enable Read-Only Mode

Add to `LocalSettings.php`:
```php
$wgReadOnly = 'Site is being upgraded. Please try again in a few minutes.';
```

```bash
ssh root@54.208.34.75 "echo '\$wgReadOnly = \"Site is being upgraded. Please try again in a few minutes.\";' >> /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/LocalSettings.php"
```

## Phase 1 — Core Upgrade

### 4. Download New Tarball

```bash
ssh root@54.208.34.75 "cd /tmp && wget https://releases.wikimedia.org/mediawiki/1.43/mediawiki-<VERSION>.tar.gz"
```

### 5. Extract

```bash
ssh root@54.208.34.75 "cd /tmp && tar xzf mediawiki-<VERSION>.tar.gz"
```

### 6. Rsync With Exclusions

This is the most critical step. The `--delete` flag removes files not in the new tarball — custom files MUST be excluded.

```bash
ssh root@54.208.34.75 "rsync -av --delete \
  --exclude='LocalSettings.php' \
  --exclude='images/' \
  --exclude='.htaccess' \
  --exclude='includes/CloudflareTrustedProxies.php' \
  --exclude='extensions/EmbedVideo/' \
  --exclude='extensions/MsUpload/' \
  --exclude='extensions/RandomSelection/' \
  [EXCLUDE OTHER CUSTOM EXTENSIONS - identify by running: ls extensions/ and comparing to tarball] \
  [EXCLUDE CUSTOM SKINS - identify by running: ls skins/ and comparing to tarball] \
  /tmp/mediawiki-<VERSION>/ \
  /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/"
```

**CRITICAL**: Before running rsync, list the custom extensions and skins:
```bash
# List what's installed
ssh root@54.208.34.75 "ls /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/"
# List what's in the new tarball
ssh root@54.208.34.75 "ls /tmp/mediawiki-<VERSION>/extensions/"
# Anything installed but NOT in the tarball is custom and needs exclusion
```

Known custom items to ALWAYS exclude:
- `includes/CloudflareTrustedProxies.php` — custom CF proxy detection (IN THE CORE TREE!)
- `extensions/EmbedVideo/` — git-managed
- `extensions/MsUpload/` — git-managed
- `extensions/RandomSelection/` — git-managed
- 5 additional custom extensions (identify from `ls` comparison)
- 3 custom skin directories (identify from `ls` comparison)

### 7. Fix Ownership

```bash
ssh root@54.208.34.75 "chown -R dbf_ec8f863yusu:psacln /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/"
```

### 8. Run update.php

```bash
ssh root@54.208.34.75 "/opt/plesk/php/8.4/bin/php /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/maintenance/run.php update --quick"
```

### 9. Remove Read-Only Mode

Remove the `$wgReadOnly` line from `LocalSettings.php`:
```bash
ssh root@54.208.34.75 "sed -i '/wgReadOnly/d' /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/LocalSettings.php"
```

## Phase 2 — Extension Updates

### 10. Update Git-Managed Extensions

```bash
ssh root@54.208.34.75 "cd /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/EmbedVideo && git pull"
ssh root@54.208.34.75 "cd /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/MsUpload && git pull"
ssh root@54.208.34.75 "cd /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/RandomSelection && git pull"
```

### 11. Fix Ownership on Updated Extensions

```bash
ssh root@54.208.34.75 "chown -R dbf_ec8f863yusu:psacln /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/EmbedVideo /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/MsUpload /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/RandomSelection"
```

## Phase 3 — Verify and Clean Up

### 12. Run 15-Point Verification Suite

Run the full verification suite from SKILL.md. All 15 tests must pass.

### 13. Purge Cloudflare Edge Cache

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/884ceccb78f467243a69036f00318da5/purge_cache" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

### 14. Update Server Changelog

Append to `/var/www/vhosts/a-gang.pigboats.com/pigboats.com/docs/server-changes.md`

Best method (avoids shell escaping issues):
1. Write the changelog entry to a local temp file
2. `scp` the file to the server
3. `ssh root@54.208.34.75 "cat /tmp/changelog-entry.md >> /var/www/vhosts/a-gang.pigboats.com/pigboats.com/docs/server-changes.md"`

### 15. Save Local Copy

```bash
scp root@54.208.34.75:/var/www/vhosts/a-gang.pigboats.com/pigboats.com/docs/server-changes.md ~/Documents/claude-code/pigboats.com-server-changes.md
```

### 16. Clean Up

```bash
ssh root@54.208.34.75 "rm -rf /tmp/mediawiki-<VERSION> /tmp/mediawiki-<VERSION>.tar.gz"
```

### 17. Keep Database Dump

Keep `/root/migration/db-pre-upgrade-*.sql.gz` on the server for at least 30 days.

## Phase 4 — Reports

Generate the 4-document reporting cycle (see SKILL.md and `pdf-design-system.md`):

1. **Pre-work proposal PDF** — should have been generated and approved before Phase 0
2. **Helpdesk ticket** — should have been created before Phase 0
3. **Completion PDF** — generate now with test results
4. **Closing helpdesk response** — generate now

## Rollback Plan

If something goes wrong at any phase:

### Phase 1 Rollback (Core Upgrade Failed)
1. Restore `LocalSettings.php` from backup
2. Re-rsync from the backup (or restore the Plesk backup)
3. Restore database from the pre-upgrade dump:
   ```bash
   ssh root@54.208.34.75 "gunzip -c /root/migration/db-pre-upgrade-*.sql.gz | mysql -u pbc_belikekelp -p'KRb-oRqMFGjzJELFuAkr6_VXt2' pigboats_32a8Pa9avV"
   ```

### Phase 2 Rollback (Extension Update Failed)
1. `git checkout <previous-commit>` on the affected extension
2. Fix ownership

### Nuclear Option
Full Plesk restore:
```bash
ssh root@54.208.34.75 "plesk bin pleskrestore --from-file /mnt/plesk_backups/backup_a-gang.pigboats.com_YYMMDDHHMM.tar -level domains -filter a-gang.pigboats.com"
```

## LTS Branch Lifecycle

MediaWiki 1.43 is an LTS release supported through **December 2027**. Only security patches (1.43.x) are released — no feature changes. When 1.43 reaches end-of-life, plan a major version upgrade to the next LTS branch. Major version upgrades are significantly more complex and may require extension compatibility testing.
