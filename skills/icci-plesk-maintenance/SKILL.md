---
name: icci-plesk-maintenance
license: Proprietary. ICCI LLC Internal Use Only. LICENSE.txt has complete terms.
description: "Manage ICCI's Plesk web hosting server — 10 active WordPress sites, 35 Cloudflare zones, MariaDB, PHP-FPM, Apache/Nginx, and server-level configuration on AWS EC2. Use this skill for WordPress troubleshooting, plugin management, PHP upgrades, Cloudflare API operations, server optimization, SSL certificate management, upload errors, permission issues, wp-config changes, cron management, and security hardening. Trigger when the user mentions Plesk, any of the hosted WordPress sites (beardedlamb.com, benkerner.com, catalog.formtechinc.com, dahlmannproperties.com, tappanbands.org, xanderjazz.com, monarchchildcenter.com, icci.com, memorial.salsitz.com, new25.beardedlamb.com), WordPress hosting issues, Cloudflare zone configuration, PHP-FPM tuning, or Apache/MariaDB config on the Plesk server. Also trigger for client support tickets about any hosted website. Do NOT use for pigboats.com (that has its own skill) or for AWS infrastructure (use icci-aws) or for PBXact/FreePBX systems (use icci-pbxact-maintenance)."
user-invocable: true
argument-hint: "[task description]"
---

# ICCI Plesk Server Maintenance Skill

You are managing ICCI's Plesk web hosting server — a Plesk Obsidian instance on AWS EC2 in us-east-1 (Virginia) hosting WordPress sites for ICCI clients. Owner: Aaron Salsitz, ICCI LLC (MSP, Ann Arbor/Brighton, Michigan). This skill gives you everything needed to maintain, troubleshoot, optimize, and monitor the server and all hosted sites.

> **This skill accesses API credentials from 1Password at runtime.** Do not commit to any public repository. Share directly with team members only.

## Cloudflare API Token

The Cloudflare API token is stored in 1Password (item `h5xgn6t3ihzebxfcic7b3iktka`, field `credential`, account `icci.1password.com`). Retrieve it at session start:

```bash
export CF_API_TOKEN=$(op item get h5xgn6t3ihzebxfcic7b3iktka --account icci.1password.com --fields "label=credential" --reveal)
```

The token works across all ICCI Cloudflare zones. If `op` is unavailable (e.g., no biometric), fall back to asking the user.

## Critical Rules

1. **ALWAYS run an incremental Plesk backup before making destructive changes.** For routine wp-config changes, plugin updates, or read-only diagnostics, a backup is not required. For anything that modifies server config files, database schemas, or SSL certificates — back up first.
2. **SSH via IP only** — the server hostname resolves through Cloudflare. Always use the IP address for SSH.
3. **Never modify Plesk auto-generated configs directly.** Files marked "DO NOT MODIFY" will be overwritten. Use override files or Plesk CLI instead.
4. **WP-CLI via Plesk wrapper** — always use `plesk ext wp-toolkit --wp-cli -instance-id <ID> -- <command>`. Never install or run a standalone wp-cli binary.
5. **MySQL access uses Plesk admin credentials** — `MYSQL_PWD=$(cat /etc/psa/.psa.shadow) mysql -u admin`. Root MySQL login is disabled.
6. **Log all changes** to `/root/claude-code/` with date-stamped markdown files. Always create an UNDO companion file.
7. **Verify after every change.** Check service status, run `curl -sI` through Cloudflare, confirm wp-config values with `wp config get`.
8. **Run cron jobs as the site's system user, not root.** Root-owned cron creates files with wrong ownership (learned the hard way — see Lessons Learned). Use `su -s /bin/bash <sysuser> -c "<command>"`.
9. **ALWAYS sync this skill to the GitHub repository** after any modifications. Copy updated files to `~/Documents/GitHub/icci-skills/skills/icci-plesk-maintenance/` so the repo always matches.

## Quick Reference

| Item                 | Value                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| **Server IP**        | `54.208.34.75`                                                                                         |
| **SSH**              | `ssh root@54.208.34.75` (key: `~/.ssh/icciVirgina2020.pem`)                                            |
| **Plesk Panel**      | `https://web1.icciadmin.com:8443`                                                                      |
| **OS**               | CloudLinux 8.10 (RHEL-based)                                                                           |
| **Plesk Version**    | Obsidian 18.0.76                                                                                       |
| **Web Stack**        | Nginx 1.28 (reverse proxy) → Apache (backend)                                                          |
| **PHP**              | 8.4 (alt-php84 + plesk-php84), no system-level PHP installed                                           |
| **Database**         | MariaDB 10.11.10 (Plesk-managed)                                                                       |
| **Redis**            | 7.2.13 (Remi repo), 512MB maxmemory, allkeys-lru                                                       |
| **CF API Token**     | `$CF_API_TOKEN`                                                                                        |
| **Backup volume**    | `/mnt/plesk_backups/` (1.2 TB EBS, underscore not hyphen)                                              |
| **Backup cmd**       | `plesk bin pleskbackup --domains-name <subscription> -incremental -v -output-file /mnt/plesk_backups/` |
| **Server changelog** | `/root/claude-code/` (date-stamped .md files)                                                          |
| **Local reports**    | `~/Documents/claude-code/`                                                                             |

## Active WordPress Sites

| Domain                  | Instance ID | System User                 | PHP Pool Location | Notes                                         |
| ----------------------- | ----------- | --------------------------- | ----------------- | --------------------------------------------- |
| beardedlamb.com         | 10          | beardedweb23q               | alt-php84         | Divi theme, brewery                           |
| benkerner.com           | 13          | benkernweb                  | alt-php84         | Arbitration                                   |
| catalog.formtechinc.com | 14          | ft1c2rta                    | plesk-php84       | Product catalog, 1.77GB DB, NOT in Cloudflare |
| dahlmannproperties.com  | 18          | ddprop32a                   | plesk-php84       | Property management                           |
| tappanbands.org         | 28          | tappanbfilez                | alt-php84         | School band site                              |
| xanderjazz.com          | 40          | xj_293kx311dts              | alt-php84         | Personal/music                                |
| monarchchildcenter.com  | 41          | monapme_ewdogk23mve         | plesk-php84       | Child development center                      |
| new25.beardedlamb.com   | 43          | new25blbc_uwqbvuokjt        | alt-php84         | Bearded Lamb staging                          |
| icci.com                | 44          | dexter.icci.com_2nwvg5ucqpr | plesk-php84       | ICCI company site                             |
| memorial.salsitz.com    | 48          | salmemorial_mt0435p8lte     | alt-php84         | Memorial site                                 |

### Deactivated/Outdated Sites (DO NOT modify without owner approval)

| Domain                   | Instance ID | State    | Notes               |
| ------------------------ | ----------- | -------- | ------------------- |
| archive24.a2jazzfest.com | 1           | Outdated | Jazz fest archive   |
| oxfordcertification.com  | 21          | Outdated | Oxford Center group |
| oxfordvaccine.com        | 23          | Outdated | Oxford Center group |
| oxfordkidsfoundation.org | 24          | Outdated | Oxford Center group |
| theoxfordcenter.com      | 33          | Outdated | Oxford Center group |
| villageoftoc.com         | 39          | Outdated | Oxford Center group |

## Standard wp-config Constants (All Active Sites)

These constants are set on all 10 active sites. Verify and re-apply if missing:

```php
define('DISALLOW_FILE_EDIT', true);     // Prevent theme/plugin editor
define('WP_POST_REVISIONS', 5);         // Limit revision bloat
define('EMPTY_TRASH_DAYS', 14);         // Auto-empty trash
define('WP_MEMORY_LIMIT', '256M');      // PHP memory for WP
define('DISABLE_WP_CRON', true);        // System cron handles this
```

**WP-CLI syntax for setting constants:**

```bash
plesk ext wp-toolkit --wp-cli -instance-id <ID> -- config set <CONSTANT> <value> --raw
```

The `--raw` flag is required for boolean and numeric values. The Plesk wp-cli wrapper does NOT support `--type=boolean` or `--raw-type` flags — those will error.

## WP-Cron via System Cron

All 10 active sites use system cron instead of visitor-triggered wp-cron. The cron runs every 15 minutes as each site's system user:

```cron
*/15 * * * * su -s /bin/bash <sysuser> -c "/opt/alt/php84/usr/bin/php -f /var/www/vhosts/<domain>/httpdocs/wp-cron.php" > /dev/null 2>&1
```

**Why `su` and not direct PHP?** Running wp-cron as root causes any directories it creates (e.g., monthly uploads folders like `uploads/2026/03/`) to be owned by root, which breaks WordPress uploads. Always run as the site's system user.

## PHP-FPM Configuration

Sites are split between two PHP-FPM services:

| Service         | Config Path                         | Sites                                                            |
| --------------- | ----------------------------------- | ---------------------------------------------------------------- |
| alt-php84-fpm   | `/opt/alt/php84/etc/php-fpm.d/`     | beardedlamb, benkerner, memorial, new25, tappanbands, xanderjazz |
| plesk-php84-fpm | `/opt/plesk/php/8.4/etc/php-fpm.d/` | catalog, dahlmann, icci, monarch, pigboats                       |

**Standard settings for all pools:**

- `pm.max_requests = 500` (prevents memory leaks from unbounded processes)
- Pool user/group matches the site's system user

**PHP overrides** go in `/var/www/vhosts/system/<domain>/conf/php.ini` with a `[php-fpm-pool-settings]` section (Plesk-safe). Never edit the pool `.conf` files directly unless Plesk will not overwrite them.

After changing FPM configs, restart both services:

```bash
systemctl restart alt-php84-fpm plesk-php84-fpm
```

## MariaDB

**Access:** `MYSQL_PWD=$(cat /etc/psa/.psa.shadow) mysql -u admin`

**Key settings in /etc/my.cnf:**

```ini
[mysqld]
tmp_table_size = 64M
max_heap_table_size = 64M
sql_mode=ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
bind-address = 127.0.0.1
local-infile=0
```

Plesk Performance Booster manages InnoDB settings in `/etc/db-performance.cnf` — do not conflict with those.

**Monthly DB optimization** runs at 4am on the 1st: `/usr/local/sbin/monthly-db-optimize.sh`

## Apache Configuration

Plesk uses Nginx (frontend reverse proxy on ports 80/443) → Apache (backend on 7080/7081).

**Key files:**

- `/etc/httpd/conf/plesk.conf.d/server.conf` — **AUTO-GENERATED, DO NOT EDIT.** Plesk overwrites on config rebuild.
- `/etc/httpd/conf.modules.d/00-remoteip.conf` — Cloudflare trusted proxies and CF-Connecting-IP header.
- `/etc/httpd/conf.d/zzz-remoteip-fix.conf` — Our override file. Loads after Plesk's server.conf to fix the RemoteIP header conflict and add X-Content-Type-Options.

**The RemoteIP story:** Plesk's auto-generated server.conf sets `RemoteIPHeader X-Forwarded-For` which overrides our correct `CF-Connecting-IP` from 00-remoteip.conf. We fix this with `zzz-remoteip-fix.conf` which loads last in the Apache include order. If Plesk regenerates configs, verify the override is still working.

To rebuild Plesk configs without losing overrides:

```bash
plesk repair web <domain> -n    # Regenerates Plesk configs, leaves conf.d/ untouched
apachectl configtest && systemctl restart httpd
```

## Cloudflare (35 Zones)

**API Token:** `$CF_API_TOKEN`

**List all zones:**

```bash
curl -s "https://api.cloudflare.com/client/v4/zones?per_page=50" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json"
```

**Standard settings across all zones:**

- HSTS: enabled, max-age=31536000, includeSubDomains, noSniff
- Always Use HTTPS: on
- 0-RTT: on
- Early Hints: on
- Browser Cache TTL: 14400 (4 hours)

**Active WP zones with cache rules** (edge TTL 30 days, browser TTL 7 days for static assets):
beardedlamb.com, benkerner.com, dahlmannproperties.com, tappanbands.org, xanderjazz.com, monarchchildcenter.com, icci.com, salsitz.com

**Note:** catalog.formtechinc.com is NOT behind Cloudflare. It uses a Let's Encrypt certificate managed by Plesk SSL It!.

See `references/cloudflare-zones.md` for the full zone ID list.

## SSL/TLS Configuration

**All CF-proxied sites use Cloudflare Origin certificates** (15-year validity, Full Strict mode). This eliminates Let's Encrypt renewal failures and rate limit issues.

| Domain                  | Certificate Type | CF SSL Mode   | Notes                                          |
| ----------------------- | ---------------- | ------------- | ---------------------------------------------- |
| beardedlamb.com         | CF Origin (2041) | Full (Strict) | Covers \*.beardedlamb.com (new25 staging)      |
| benkerner.com           | CF Origin (2041) | Full (Strict) |                                                |
| dahlmannproperties.com  | CF Origin (2041) | Full (Strict) |                                                |
| tappanbands.org         | CF Origin (2041) | Full (Strict) |                                                |
| xanderjazz.com          | CF Origin (2041) | Full (Strict) |                                                |
| monarchchildcenter.com  | CF Origin (2041) | Full (Strict) |                                                |
| icci.com                | CF Origin (2041) | Full (Strict) | WP instance is legacy — live site is CF Worker |
| salsitz.com             | CF Origin (2041) | Full (Strict) | Covers memorial.salsitz.com                    |
| pigboats.com            | CF Origin (2041) | Full (Strict) | MediaWiki site (separate skill)                |
| catalog.formtechinc.com | Let's Encrypt    | N/A           | NOT behind Cloudflare                          |
| web1.icciadmin.com:8443 | CF Origin (2041) | Full (Strict) | Plesk panel itself                             |

**Origin cert installation (Plesk CLI):**

```bash
# Import cert via Plesk (assigns to both Apache and nginx)
plesk bin certificate --install <cert-name> -domain <domain> -key-file key.pem -cert-file cert.pem
# Or assign existing cert in Plesk DB to a domain:
plesk bin subscription --update <subscription> -certificate-name <cert-name>
```

**Plesk panel certificate** is at `/usr/local/psa/admin/conf/httpsd.pem` — must be manually built from key+cert PEM concatenation. SSL It! "Keep Plesk secured" must be disabled first: `plesk ext sslit --panel-keep-secured -disable`.

## Plesk Panel Behind Cloudflare

The Plesk panel at `web1.icciadmin.com:8443` is proxied through Cloudflare. This requires special configuration:

### Session IP Validation

Cloudflare rotates edge IPs between requests, which causes Plesk to invalidate sessions (user gets logged out and sent back to login). Fix:

```bash
# Disable Plesk's session-IP binding
plesk bin settings --set disable_check_session_ip=true

# Set session timeout (minutes) — default 30 is too short for admin work
plesk bin settings --set login_timeout=240
```

### Trusted Proxies (panel.ini)

The panel must know CF IPs to correctly resolve client IP. Create `/usr/local/psa/admin/conf/panel.ini`:

```ini
[webserver]
trustedProxies = 173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22
```

After editing panel.ini: `systemctl restart sw-cp-server`

### Panel SSL Certificate (httpsd.pem)

The panel cert is separate from site certs. To use a CF Origin cert:

1. Disable SSL It! panel management: `plesk ext sslit --panel-keep-secured -disable`
2. Extract cert from Plesk DB (values are URL-encoded): `plesk db -Ne "SELECT cert,pvt_key FROM certificates WHERE id=<id>"` then decode with `python3 -c 'import sys,urllib.parse; print(urllib.parse.unquote_plus(sys.stdin.read()))'`
3. Build the PEM: `cat origin_key.pem origin_cert.pem > /usr/local/psa/admin/conf/httpsd.pem`
4. Restart: `systemctl restart sw-cp-server`

Backup the old cert first: `cp httpsd.pem httpsd.pem.bak.le`

## Cron Schedule (Root Crontab)

| Schedule       | Job                    | Notes                                  |
| -------------- | ---------------------- | -------------------------------------- |
| `*/5 * * * *`  | netwatch_reboot.sh     | Server health watchdog                 |
| `0 3 * * *`    | update-cf-proxies.sh   | Update CF trusted proxy IPs            |
| `0 3 * * 0`    | MediaWiki sitemap      | pigboats.com sitemap generation        |
| `0 4 1 * *`    | monthly-db-optimize.sh | DB optimize (staggered from 3am)       |
| `*/15 * * * *` | WP-Cron (x10)          | One per active site, runs as site user |

**Stagger rule:** Do not schedule new jobs at 3am — it's already crowded.

## Common Troubleshooting

### WordPress Upload Errors ("could not be moved to wp-content/uploads")

**Almost always a permissions issue.** Check:

1. Ownership of the uploads subdirectory: `ls -la .../wp-content/uploads/YYYY/MM/`
2. If owned by root:root, fix with: `chown <sysuser>:psacln <path>`
3. This happens when cron or CLI commands run as root and create the monthly directory

### Plesk WP-CLI Errors

- **"unknown --raw-type parameter"** — Use `--raw` not `--raw-type=constant`
- **"Invalid value specified for 'type'"** — The Plesk wp-cli wrapper doesn't support `--type=boolean`. Use `--raw` for booleans.
- **Plugin/theme operations** — Use `plesk ext wp-toolkit --wp-cli -instance-id <ID> -- plugin <action>`

### PHP-FPM Pool Not Found

Some sites use alt-php84, others use Plesk's built-in php8.4. If you can't find a pool config, check BOTH locations:

```bash
find /opt/alt/php84/etc/php-fpm.d/ /opt/plesk/php/8.4/etc/php-fpm.d/ -name "<domain>.conf"
```

### Apache/Nginx Config Issues

- `plesk repair web <domain> -n` — regenerates Plesk configs (dry-run with -n)
- `apachectl configtest` — always test before restarting
- `nginx -t` — test nginx config
- The "module remoteip_module is already loaded" warning is harmless (loaded in both 00-remoteip.conf and the module loader)

### Curling from Server Returns 403

Expected behavior — sites behind Cloudflare are configured to accept traffic only from CF IPs. To test from the server, either:

- Curl via Cloudflare: `curl -sI https://domain.com` (if DNS resolves to CF)
- Or test Apache directly: `curl -sI http://127.0.0.1:7080 -H "Host: domain.com"`

## Server Hardening (as of 2026-03-07)

| Item              | Setting                                                       | Notes                                                   |
| ----------------- | ------------------------------------------------------------- | ------------------------------------------------------- |
| SSH root login    | `PermitRootLogin prohibit-password`                           | Key-only, no password                                   |
| SSH password auth | `PasswordAuthentication no`                                   | Key-only                                                |
| X11 forwarding    | `X11Forwarding no`                                            | Disabled (not needed on headless server)                |
| ProFTPD           | Disabled in xinetd (`/etc/xinetd.d/ftp_psa`, `disable = yes`) | Can't remove via Plesk installer (core dependency)      |
| NFS/rpcbind       | `systemctl disable --now rpcbind rpcbind.socket`              | Not needed for EBS volumes                              |
| Panel nginx TLS   | `TLSv1.2 TLSv1.3` only                                        | `/etc/sw-cp-server/conf.d/ssl.conf` — was TLSv1/1.1/1.2 |
| Redis             | `bind 127.0.0.1`                                              | Localhost only                                          |
| MariaDB           | `bind-address = 127.0.0.1`, `local-infile=0`                  | Localhost only, no LOAD DATA LOCAL                      |
| Grafana           | Running (used by Plesk Monitoring extension UI)               | Do NOT disable                                          |

**Disabled services:** rpcbind, ProFTPD (xinetd), NFS
**Kept running:** Grafana (Plesk Monitoring), sw-cp-server (Plesk panel nginx), xinetd (for other Plesk services)

## Plesk CLI Tools Quick Reference

**Golden rule**: ALWAYS look up Plesk CLI usage on docs.plesk.com, talk.plesk.com, or support.plesk.com before running unfamiliar commands. The community sites are a treasure trove of real-world examples.

**Key docs:**

- Official CLI reference: `https://docs.plesk.com/en-US/obsidian/cli-linux/`
- Support KB: `https://support.plesk.com/hc/en-us/`
- Community forum: `https://talk.plesk.com/`

### pleskbackup / pleskrestore

```bash
# Backup a domain
plesk bin pleskbackup --domains-name <subscription> -incremental -v \
  -output-file /mnt/plesk_backups/ -d "description"

# Restore: Step 1 — inspect backup to get XML path
plesk bin pleskrestore --info /mnt/plesk_backups/backup_<domain>_YYMMDDHHMM.tar

# Restore: Step 2 — restore using the XML path
plesk bin pleskrestore --restore \
  /mnt/plesk_backups/clients/<client>/domains/<domain>/backup_info_YYMMDDHHMM.xml \
  -level domains -verbose
```

**GOTCHA**: Cannot pass .tar directly to `--restore`. Must run `--info` first (extracts the tar), then use the XML path. The `-filter` flag fails on domain-level backups — omit it.

### WP Toolkit CLI

```bash
plesk ext wp-toolkit --list [-format json]                    # List all instances
plesk ext wp-toolkit --info -instance-id <ID> [-format json]  # Instance details
plesk ext wp-toolkit --wp-cli -instance-id <ID> -- <command>  # Run WP-CLI
plesk ext wp-toolkit --clear-cache -instance-id <ID>          # Clear WP Toolkit cache
plesk ext wp-toolkit --detach -instance-id <ID>               # Remove from tracking (keeps files)
plesk ext wp-toolkit --remove -instance-id <ID>               # Delete files!
```

**WP Toolkit JSON notes:**

- `plugins` and `themes` are **dicts keyed by slug** (not arrays)
- Each plugin has: `name`, `status`, `version`, `title`, `update_version`, `autoUpdates`, `sourceId`
- **No CLI command for vulnerability scanning** — that's GUI-only

**WP Toolkit SQLite DB**: `/usr/local/psa/var/modules/wp-toolkit/wp-toolkit.sqlite3`

- Tables: `Instances`, `InstanceProperties`, `InstancesDomains`, `PluginsInstances`, `ThemesInstances`
- Always back up before manual edits: `cp wp-toolkit.sqlite3 wp-toolkit.sqlite3.bak.$(date +%Y%m%d)`

### Other Plesk CLI

```bash
plesk ext sslit --hsts -enable -domain <domain> -max-age 2years   # Enable HSTS
plesk bin settings --set disable_check_session_ip=true             # Disable session IP check
plesk bin settings --set login_timeout=240                         # Session timeout (minutes)
plesk repair web <domain> -n                                       # Regenerate configs (dry run)
plesk bin certificate --install <name> -domain <d> -key-file k -cert-file c  # Install cert
```

## Lessons Learned

These are hard-won lessons from real incidents. Read them before making changes.

### 1. System Cron Must Run as Site User, Not Root (2026-03-03)

**Incident:** All 10 sites lost the ability to upload images on March 1st. The `uploads/2026/03/` directory was created by root-owned cron and WordPress couldn't write to it.
**Fix:** Changed all wp-cron system crons to `su -s /bin/bash <sysuser> -c "..."`.
**Rule:** ANY cron job that touches site files must run as the site's system user.

### 2. Plesk WP-CLI Has a Non-Standard Flag Set (2026-02-27)

**Incident:** `wp config set` with `--type=boolean` and `--raw-type=constant` failed silently in the Plesk wrapper.
**Fix:** Use `--raw` flag only. No `--type` or `--raw-type`.
**Rule:** Always test wp-cli flag syntax on one site before batch-applying to all 10.

### 3. Plesk Auto-Generated Configs Will Overwrite Your Changes (2026-02-27)

**Incident:** Needed to fix Apache RemoteIP header but server.conf says "DO NOT MODIFY".
**Fix:** Created `/etc/httpd/conf.d/zzz-remoteip-fix.conf` which loads after Plesk includes.
**Rule:** For Apache, use `conf.d/zzz-*.conf` files to override Plesk. For PHP, use `/var/www/vhosts/system/<domain>/conf/php.ini`.

### 4. Verify wp-config Changes Actually Stuck (2026-02-27)

**Incident:** Round 1 optimization claimed wp-config constants were set, but Round 2 audit found most were missing.
**Rule:** Always verify with `wp config get` or `wp config list` after setting constants. Never trust the command's success message alone.

### 5. Two Separate PHP-FPM Services (2026-02-27)

**Incident:** Fixed pm.max_requests in alt-php84 pools but missed 6 sites in Plesk's php8.4 pools.
**Rule:** ALWAYS check both `/opt/alt/php84/etc/php-fpm.d/` AND `/opt/plesk/php/8.4/etc/php-fpm.d/`. Restart both `alt-php84-fpm` and `plesk-php84-fpm`.

### 6. Client Preferences Override Technical Best Practice

**Incident:** Plan called for deleting inactive plugins/themes and wp-file-manager. Owner said no.
**Rule:** Always confirm with Aaron before deleting plugins, themes, or making changes clients might notice. Technical cleanliness is secondary to client comfort.

### 7. Redis Upgrade: Use Remi Repo on CloudLinux/RHEL8 (2026-03-07)

**Incident:** Server ran Redis 5.0.3 (EOL) from the default AppStream. Needed 7.x.
**Fix:** `dnf module reset redis && dnf module enable redis:remi-72 && dnf upgrade redis`. Config moves from `/etc/redis.conf` to `/etc/redis/redis.conf` (symlink preserved). Service name stays `redis`.
**Rule:** Remi repo is already installed on this server. Use `dnf module` to switch streams — don't install from source.

### 8. ProFTPD Cannot Be Removed via Plesk Installer (2026-03-07)

**Incident:** `plesk installer remove --components proftpd` fails — Plesk considers it a core dependency ("you also need to explicitly remove: Plesk (panel)").
**Fix:** Disable in xinetd: set `disable = yes` in `/etc/xinetd.d/ftp_psa`, then `systemctl restart xinetd`.
**Rule:** Some Plesk components can't be uninstalled even if unused. Disable at the service level instead.

### 9. Plesk panel.ini — Correct Parameter Names Matter (2026-03-07)

**Incident:** Tried `[login] allowIpChange = true` in panel.ini — this parameter does not exist (Plesk source is ioncube-encrypted, can't grep for it).
**Fix:** The correct approach is the CLI: `plesk bin settings --set disable_check_session_ip=true`. Panel.ini only handles `[webserver] trustedProxies`.
**Rule:** Don't guess panel.ini parameters. Use `plesk bin settings` for session/login config. Check Plesk docs for valid panel.ini sections.

### 10. Plesk httpsd.pem Must Be Manually Rebuilt (2026-03-07)

**Incident:** Assigned a CF Origin cert to the panel via Plesk DB, but `plesk repair web -y` and `systemctl restart sw-cp-server` did NOT regenerate `httpsd.pem`. SSL It!'s "Keep Plesk secured" feature was overriding.
**Fix:** 1) `plesk ext sslit --panel-keep-secured -disable`, 2) Extract cert+key from Plesk DB (URL-encoded — decode with `urllib.parse.unquote_plus`), 3) `cat key.pem cert.pem > /usr/local/psa/admin/conf/httpsd.pem`, 4) Restart sw-cp-server.
**Rule:** Panel cert changes require manual PEM file construction. The Plesk DB stores certs URL-encoded.

### 11. System-Level PHP Removal Is Safe on Plesk (2026-03-07)

**Incident:** Removed CloudLinux system PHP packages (`dnf module reset php`) leaving no system-level `php` binary. Concerned it would break something.
**Result:** Plesk and all sites work fine — they use alt-php84 and plesk-php84, not system PHP. The bare `php` command being missing is a non-issue.
**Rule:** Plesk uses its own PHP stacks. System PHP (from OS vendor) is unnecessary and can be safely removed/not installed.

### 12. Plesk Panel Session Timeout Behind Cloudflare (2026-03-07)

**Incident:** Admin sessions on web1.icciadmin.com:8443 expired after ~5 minutes despite 30-min timeout setting. Cloudflare edge IP rotation caused Plesk to invalidate sessions.
**Fix:** Three-part fix: 1) `plesk bin settings --set disable_check_session_ip=true`, 2) CF trusted proxies in panel.ini, 3) `login_timeout=240`.
**Rule:** Any Plesk panel behind a CDN/proxy needs session-IP checking disabled and trusted proxy configuration.

### 13. Bundled Theme Plugins Cannot Be Deactivated (2026-03-07)

**Incident:** Deactivated 3 vulnerable Goodlayers plugins on dahlmannproperties.com. The Hotelmaster theme's `functions.php` does `include_once('plugins/masterslider.php')` and the CSS enqueuing chain requires all Goodlayers plugins active. Result: entire site lost all styling — rendered as raw unstyled HTML.
**Fix:** Restored from Plesk backup. Wrote security report recommending virtual patching instead.
**Rule:** NEVER deactivate plugins bundled with a commercial theme without first checking the theme's `functions.php` for direct `include` dependencies. If the theme loads plugin files directly, deactivation will break the site. Use virtual patching (Patchstack via WP Toolkit) or update via Envato license instead.

### 14. pleskrestore Cannot Use .tar Directly (2026-03-07)

**Incident:** `pleskrestore --restore backup.tar -level domains -filter domain.com` failed with "File is not readable: domain.com".
**Fix:** Must run `pleskrestore --info backup.tar` first (extracts the tar), then use the XML path from the output: `pleskrestore --restore .../backup_info_YYMMDDHHMM.xml -level domains -verbose`. Omit `-filter` for domain-level backups.
**Rule:** Always `--info` first, then `--restore` with the XML path. Never pass .tar to --restore.

### 15. Always Verify Backup Completes Before Making Changes (2026-03-07)

**Incident:** Started deactivating plugins before confirming the backup was done.
**Rule:** Run the backup, then `find /mnt/plesk_backups/ -name '*domain*' -mmin -10` to verify it landed. Only then proceed with changes. The few minutes of waiting is nothing compared to the cost of an unrecoverable mistake.

### 16. WP Fastest Cache — Clear File Cache AND Cloudflare (2026-03-07)

**Incident:** Changed homepage content but visitors still saw the old version.
**Fix:** Must clear BOTH: `rm -rf wp-content/cache/all/* wp-content/cache/wpfc-minified/*` AND Cloudflare API purge.
**Rule:** WordPress changes require clearing two cache layers: the local file cache plugin AND the Cloudflare edge cache. Missing either one means stale content persists.

### 17. Flush Rewrite Rules After Plugin Activation/Deactivation (2026-03-07)

**Incident:** Property-type pages returned 404 after plugin changes because stale rewrite rules from deactivated plugins interfered with URL resolution.
**Fix:** `plesk ext wp-toolkit --wp-cli -instance-id <ID> -- rewrite flush`
**Rule:** Always flush rewrite rules after activating or deactivating plugins that register custom post types or taxonomies.

## Audit & Optimization Checklist

When performing a server audit, check these items. See `references/audit-checklist.md` for the full checklist with commands.

**WordPress (per site):**

- [ ] wp-config constants present and correct
- [ ] WP_DEBUG disabled in production
- [ ] DISABLE_WP_CRON set, system cron active
- [ ] No wp-config-sample.php in httpdocs
- [ ] Uploads directory owned by site user (not root)
- [ ] No redundant security plugins (CF WAF handles this)
- [ ] WordPress core up to date

**Server:**

- [ ] MariaDB tmp_table_size >= 64M
- [ ] PHP-FPM pm.max_requests = 500 (both services)
- [ ] Apache RemoteIP using CF-Connecting-IP (check zzz-remoteip-fix.conf)
- [ ] All sites on PHP 8.4
- [ ] Cron jobs staggered (no collisions)
- [ ] Cron jobs run as correct user

**Cloudflare (per zone):**

- [ ] HSTS enabled (max-age 31536000, includeSubDomains)
- [ ] Always Use HTTPS on
- [ ] 0-RTT on
- [ ] Early Hints on
- [ ] Static asset cache rules in place (for WP zones)
- [ ] SSL mode: Full (Strict) for CF-proxied sites
- [ ] Origin certificate installed (not Let's Encrypt) for CF-proxied sites

**Server hardening:**

- [ ] SSH: PermitRootLogin prohibit-password, PasswordAuthentication no, X11Forwarding no
- [ ] Panel TLS: TLSv1.2 and TLSv1.3 only (no TLSv1/1.1)
- [ ] Redis: bind 127.0.0.1
- [ ] MariaDB: bind-address 127.0.0.1, local-infile=0
- [ ] Unnecessary services disabled (rpcbind, ProFTPD/xinetd)
- [ ] Panel behind CF: session IP check disabled, trusted proxies configured, timeout >= 240
