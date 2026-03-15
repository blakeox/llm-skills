# PigBoats.COM Server Reference

Complete server configuration reference for pigboats.com. This file supplements the Quick Reference in SKILL.md with detailed configuration values and architecture notes.

## Server Architecture

- **Host**: AWS EC2 instance at `54.208.34.75`
- **OS**: Amazon Linux (Plesk-managed)
- **Stack**: nginx (reverse proxy) → Apache (backend) → PHP 8.4 FPM → MariaDB/MySQL
- **Plesk subscription name**: `a-gang.pigboats.com` (does NOT match the domain `pigboats.com`)
- **Document root**: `/var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/`
- **File owner**: `dbf_ec8f863yusu:psacln`

## MediaWiki Installation

- **Version**: 1.43.6 LTS (tarball-based, NOT git)
- **Skin**: Timeless 0.9.1
- **34 active extensions**: 8 custom (not from MW tarball), 3 git-managed
- **Git-managed extensions**: EmbedVideo, MsUpload, RandomSelection
- **Config**: `LocalSettings.php` in document root
- **Images**: `images/` directory in document root

### Key LocalSettings.php Values (as of 2026-02-28)

```php
$wgVerifyMimeType = true;        // Enforces file type checking on uploads
$wgAllowJavaUploads = false;     // Blocks Java applet uploads
$wgSessionCacheType = "redis";     // Sessions in Redis (fixed 2026-03-06; was CACHE_ACCEL which silently broke sessions because APCu is not installed)
$wgJobRunRate = 0;               // Jobs run via cron, not on page loads
```

### Custom Files in Core Tree (DANGER during upgrades)

- `includes/CloudflareTrustedProxies.php` — sets `$wgCdnServersNoPurge` with Cloudflare IP ranges
  - MUST be excluded from `rsync --delete` during upgrades
  - Was accidentally deleted during the 1.43.6 upgrade, caused ~2 min of 500 errors
  - Consider moving to a directory outside core tree in the future

## PHP Configuration

- **Runtime**: PHP 8.4 FPM (Plesk-managed pool)
- **CLI**: `/opt/plesk/php/8.4/bin/php` (system default `php` is 7.2 — NEVER use bare `php`)
- **MW maintenance syntax**: `/opt/plesk/php/8.4/bin/php .../maintenance/run.php <scriptname>`

### PHP-FPM Pool Settings

Persisted in Plesk-safe location: `/var/www/vhosts/system/pigboats.com/conf/php.ini`

```ini
[opcache]
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 60
opcache.memory_consumption = 192

[php-fpm-pool-settings]
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 4
pm.max_requests = 500
```

The `[php-fpm-pool-settings]` section name is required — Plesk reads this section for FPM pool configuration.

### PHP Error Log

```
/var/log/alt-php84-error.log
```

Also check: `/var/www/vhosts/system/a-gang.pigboats.com/logs/error_log`

## Caching Architecture

- **Redis**: Handles main cache, parser cache, message cache (`$wgMainCacheType = "redis"`) AND session cache (`$wgSessionCacheType = "redis"`)
- **APCu**: NOT installed on PHP 8.4 — do NOT use `CACHE_ACCEL` for anything (it resolves to `EmptyBagOStuff` and silently discards data)
- **OPcache**: 192 MB, 20000 max files, 60s revalidation
- **Cloudflare**: Edge cache for static assets (1 year) and wiki pages (1 hour)
- **$wgJobRunRate = 0**: Jobs run via cron every 5 minutes, NOT on page loads

### Cron Job (user: `dbf_ec8f863yusu`)

```
*/5 * * * * /opt/plesk/php/8.4/bin/php /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/maintenance/run.php runJobs --maxtime=60 >> /dev/null 2>&1
```

Note: The command is `run.php runJobs` — NOT `run.php maintenance/runJobs.php` (that doubles the path and fails).

## nginx Configuration

- **Plesk-generated** (DO NOT EDIT): `/var/www/vhosts/system/pigboats.com/conf/nginx.conf`
- **Custom overrides**: `/var/www/vhosts/system/pigboats.com/conf/vhost_nginx.conf`

### Critical nginx Pattern

Static asset location blocks MUST include `try_files $uri @rewrite;` — without it, MediaWiki clean URLs like `/File:Photo.jpg` and `/MediaWiki:Common.css` get intercepted as static files and return 404 instead of being processed by MediaWiki.

The `@rewrite` block: `rewrite ^/(.*)$ /index.php?title=$1&$args;`

### HSTS

HSTS is controlled by the **Plesk SSL It! extension**, not by editing nginx config files directly:

```bash
plesk ext sslit --hsts -enable -domain pigboats.com -max-age 2years -include-subdomains
```

Current setting: `max-age=63072000` (2 years).

## Cloudflare Configuration

- **Zone ID**: `884ceccb78f467243a69036f00318da5`
- **API Token**: `$CF_API_TOKEN`
- **Cache ruleset ID**: `bf567d50659f4984be9b6c6c2ca8cbc2`

### Cache Rules (4 rules)

1. **Bypass logged-in users**: Cookie match for MediaWiki session cookies
2. **Bypass API/Special/edit**: URL path matching for dynamic wiki pages
3. **Cache static assets 1 year**: `.jpg`, `.png`, `.gif`, `.css`, `.js`, etc. — with `status_code_ttl: 0` for 4xx/5xx (errors never cached)
4. **Cache wiki pages 1 hour**: Everything else — with `status_code_ttl: 0` for 4xx/5xx

### DNS Records

- Main domain: proxied through Cloudflare (orange cloud)
- Microsoft records set to **DNS-only** (gray cloud):
  - `autodiscover.pigboats.com` (record ID: `88aaec71da0b49e2ab307e174e33e881`)
  - `enterpriseenrollment.pigboats.com` (record ID: `8e4a94549578b79bd3afe039c6f31b40`)
  - `enterpriseregistration.pigboats.com` (record ID: `9eca21d0aa3975e776d8ad4acc58bac4`)

### Cloudflare Cache Purge

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/884ceccb78f467243a69036f00318da5/purge_cache" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

Note: Cloudflare automatically prepends AI-bot blocking rules to `robots.txt`.

## Security Settings (as of 2026-02-28)

- `$wgVerifyMimeType = true` (was false — fixed)
- `$wgAllowJavaUploads = false` (was true — fixed)
- HSTS: `max-age=63072000` (2 years) via Plesk SSL It!
- `robots.txt`: Blocks `Special:`, `action=edit/history`, `oldid=` from crawlers
- Sessions stored in Redis (moved from database)
- Background jobs via cron, not on page loads

### robots.txt (at document root)

```
# robots.txt for PigBoats.COM (MediaWiki 1.43)
User-agent: *
Disallow: /Special:
Disallow: /index.php?
Disallow: /w/
Disallow: /*action=edit
Disallow: /*action=history
Disallow: /*oldid=
Sitemap: https://pigboats.com/sitemap.xml
```

Note: Cloudflare prepends its own AI-bot rules above this content.

## Backup Architecture

### Layer 1: Plesk Incremental Backups

```bash
plesk bin pleskbackup --domains-name a-gang.pigboats.com -incremental -v -output-file /mnt/plesk_backups/ -d "description"
```

- Volume: `/mnt/plesk_backups/` (1.2 TB EBS — note: underscore, not hyphen)
- Files: `backup_a-gang.pigboats.com_YYMMDDHHMM.tar`
- WARNING: `/var/lib/psa/dumps/` is empty — all backups go to the `/mnt/` volume

### Layer 2: AWS EC2 Instance Snapshots

Full machine-level snapshots managed through AWS console.

### Layer 3: Cloudflare Edge Cache

Not a true backup, but provides CDN resilience — cached pages continue serving even if origin is temporarily down.

## Custom CSS (Dorado Pages)

- CSS lives in `MediaWiki:Common.css` (applies to all skins)
- Page-specific targeting uses `body.page-Page_Name` selector
- Dorado Myths has custom khaki yellow background (#f0e68c), dark blue text, custom TOC styling
- Dave has a CSS tutorial at `~/Documents/claude-code/pigboats-mediawiki-css-guide.md` (and `.pdf`)

## Deferred Items (evaluated, intentionally skipped)

| Item | Reason Skipped |
|------|---------------|
| Content-Security-Policy header | Too fragile with MW inline scripts, VisualEditor, extensions |
| Cloudflare Always Online | Bad for wikis — serves stale content to visitors |
| OPcache JIT | Stability risk not worth marginal performance gain |
| DB OPTIMIZE/compression | DB is healthy, 99.99% buffer pool hit ratio |
| Sitemap generation | Would be nice but not urgent |
| Favicon | Missing (generates 404 noise in logs) but cosmetic |

## Local Files Index

Reports and documentation stored on the operator's machine:

| File | Purpose |
|------|---------|
| `~/Documents/claude-code/pigboats-404-fix-2026-02-28.md` | nginx 404 issue report |
| `~/Documents/claude-code/pigboats-mediawiki-css-guide.md` + `.pdf` | CSS tutorial for Dave |
| `~/Documents/claude-code/pigboats-update-report-2026-02-28.pdf` | Pre-upgrade risk assessment |
| `~/Documents/claude-code/pigboats-upgrade-log-2026-02-28.md` | Technical upgrade log |
| `~/Documents/claude-code/pigboats-upgrade-complete-2026-02-28.pdf` | Upgrade completion (for Dave) |
| `~/Documents/claude-code/pigboats-optimization-plan-2026-02-28.pdf` | Optimization plan (for Dave) |
| `~/Documents/claude-code/pigboats-optimization-complete-2026-02-28.pdf` | Optimization completion (for Dave) |
| `~/Documents/claude-code/pigboats-optimization-ticket-2026-02-28.txt` | Helpdesk ticket summary |
| `~/Documents/claude-code/pigboats-ticket-closing-response-2026-02-28.txt` | Closing response for Dave |
| `~/Documents/claude-code/pigboats.com-server-changes.md` | Local copy of server changelog |
| `~/Documents/claude-code/pigboats.com/pigboats-csrf-fix-2026-03-06.md` | CSRF/session fix technical tracking |
| `~/Documents/claude-code/pigboats.com/pigboats-csrf-fix-complete-2026-03-06.pdf` | CSRF fix completion report (for Dave) |
| `~/Documents/claude-code/pigboats.com/pigboats-csrf-fix-closing-2026-03-06.txt` | CSRF fix closing response for Dave |

## Lessons Learned

- `rsync --delete` wipes custom files in core MW directories — always exclude or move them
- Plesk subscription names don't always match domain names (`a-gang.pigboats.com` not `pigboats.com`)
- Plesk backup dumps dir (`/var/lib/psa/dumps/`) is empty; actual backups go to `/mnt/plesk_backups/`
- Plesk-generated `nginx.conf` and php-fpm configs get overwritten — use designated override files
- HSTS is controlled by Plesk SSL It! extension CLI, not by editing nginx.conf directly
- `maintenance/run.php runJobs` (not `run.php maintenance/runJobs.php`) — don't double the path
- Cloudflare "Always Online" is bad for wikis (serves stale cached content)
- CSP headers are too fragile for MediaWiki (inline scripts, VisualEditor, extensions)
- OPcache JIT: stability risk not worth marginal gain on a site that's already fast
- Shell heredocs over SSH mangle backticks/special chars — use scp + cat instead
- WeasyPrint venv IS `/tmp/pdfgen/` itself — `source /tmp/pdfgen/bin/activate`, not `source venv/bin/activate`
- **`CACHE_ACCEL` ≠ Redis** — `CACHE_ACCEL` maps to APCu, NOT Redis. The correct Redis value is the string `"redis"` (matching the `$wgObjectCaches` key). APCu is not installed on this server; using `CACHE_ACCEL` silently falls back to `EmptyBagOStuff` (a no-op cache that discards all data). This caused a 6-day session outage in March 2026.
- **The 15-point verification suite doesn't test authenticated sessions** — anonymous API checks pass even when sessions are broken. Consider testing a login+token flow when session config changes are made.
