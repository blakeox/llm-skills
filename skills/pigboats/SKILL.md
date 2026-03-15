---
name: pigboats
license: Proprietary. ICCI LLC Internal Use Only. LICENSE.txt has complete terms.
description: "Manage the pigboats.com submarine history MediaWiki website. Use this skill whenever the user mentions pigboats, pigboats.com, Dave Johnston, the submarine wiki, or any server work on the pigboats server. Also trigger when the user asks about Plesk backups for pigboats, MediaWiki upgrades, Cloudflare changes, generating reports for the site owner, or checking for MW security updates. Do NOT use for general MediaWiki questions unrelated to pigboats.com."
user-invocable: true
argument-hint: "[task description]"
---

# PigBoats.COM Operations Skill

You are performing operations on **pigboats.com** — a submarine history MediaWiki wiki hosted on a Plesk-managed AWS EC2 instance behind Cloudflare. This skill gives you everything you need to manage the server, MediaWiki installation, Cloudflare CDN, and generate professional reports for the site owner.

> **This skill accesses API credentials from 1Password at runtime.** Do not commit this skill directory to any public repository. When distributing to team members, share directly — never through public channels.

## Cloudflare API Token

The Cloudflare API token is stored in 1Password (item `h5xgn6t3ihzebxfcic7b3iktka`, field `credential`, account `icci.1password.com`). Retrieve it at session start:

```bash
export CF_API_TOKEN=$(op item get h5xgn6t3ihzebxfcic7b3iktka --account icci.1password.com --fields "label=credential" --reveal)
```

The token works across all ICCI Cloudflare zones. If `op` is unavailable (e.g., no biometric), fall back to asking the user.

## Critical Rules

1. **ALWAYS run an incremental Plesk backup before making any changes.** No exceptions. Verify it completes before proceeding.
2. **ALWAYS run the 15-point verification suite after making changes.** If any test fails, stop and investigate.
3. **ALWAYS update the server changelog** after completing work (path in Quick Reference below).
4. **ALWAYS save a local copy** of the server changelog to `~/Documents/claude-code/pigboats.com-server-changes.md`.
5. **PHP CLI on this server is 7.2** — you MUST use `/opt/plesk/php/8.4/bin/php` for all MediaWiki maintenance scripts. Using bare `php` will fail silently or produce wrong results.
6. **SSH via IP only** — the domain is behind Cloudflare. Always SSH to the IP address, never the domain name.
7. **Offer a pre-work proposal PDF** before implementing any batch of changes. Get approval before proceeding.
8. **Generate a completion PDF** after all work is verified. Include test results.
9. **ALWAYS sync this skill to the GitHub repository** after any modifications. When you edit any file in this skill (SKILL.md or anything in `references/`), copy the updated files to `~/Documents/GitHub/icci-skills/skills/pigboats/` so the repository always contains the latest version. Both locations must stay identical.

## Quick Reference

| Item                     | Value                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------ |
| **Server**               | `54.208.34.75` (user: `root`, SSH via IP — port 22 is not proxied through CF)              |
| **Plesk subscription**   | `a-gang.pigboats.com` (NOT `pigboats.com` — subscriptions don't always match domain names) |
| **Document root**        | `/var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/`                               |
| **MediaWiki**            | 1.43.6 LTS, Timeless skin 0.9.1                                                            |
| **PHP**                  | 8.4 FPM — CLI: `/opt/plesk/php/8.4/bin/php`                                                |
| **File owner**           | `dbf_ec8f863yusu:psacln`                                                                   |
| **Database**             | Name: `pigboats_32a8Pa9avV`, User: `pbc_belikekelp`, Pass: `KRb-oRqMFGjzJELFuAkr6_VXt2`    |
| **CF Zone ID**           | `884ceccb78f467243a69036f00318da5`                                                         |
| **CF API Token**         | `$CF_API_TOKEN`                                                                            |
| **CF Cache Ruleset**     | `bf567d50659f4984be9b6c6c2ca8cbc2`                                                         |
| **Backup volume**        | `/mnt/plesk_backups/` (1.2 TB EBS)                                                         |
| **Server changelog**     | `/var/www/vhosts/a-gang.pigboats.com/pigboats.com/docs/server-changes.md`                  |
| **Local reports**        | `~/Documents/claude-code/pigboats-*`                                                       |
| **MW maintenance**       | `/opt/plesk/php/8.4/bin/php .../maintenance/run.php <command>`                             |
| **Cron jobs user**       | `dbf_ec8f863yusu`                                                                          |
| **34 active extensions** | 8 custom (not from MW tarball), 3 git-managed: EmbedVideo, MsUpload, RandomSelection       |

## Mandatory Pre-Change: Incremental Backup

Run before ANY server or configuration changes:

```bash
ssh root@54.208.34.75 "plesk bin pleskbackup --domains-name a-gang.pigboats.com -incremental -v -output-file /mnt/plesk_backups/ -d 'Pre-[topic] backup YYYY-MM-DD'"
```

Verify completion:

```bash
ssh root@54.208.34.75 "find /mnt/plesk_backups/ -name '*pigboats*' -mmin -10"
```

Backups land as: `/mnt/plesk_backups/backup_a-gang.pigboats.com_YYMMDDHHMM.tar`

## 15-Point Verification Suite

Run after every change. All must return 200 (Main Page returns 301→200 redirect to trailing slash, which is normal):

| #   | Test              | Command                                                                                                                              |
| --- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Main Page         | `curl -s -o /dev/null -w "%{http_code}" https://pigboats.com/`                                                                       |
| 2   | Dorado Myths      | `curl -s -o /dev/null -w "%{http_code}" https://pigboats.com/Dorado_Myths`                                                           |
| 3   | Common.css        | `curl -s -o /dev/null -w "%{http_code}" https://pigboats.com/MediaWiki:Common.css`                                                   |
| 4   | Special:ListFiles | `curl -s -o /dev/null -w "%{http_code}" https://pigboats.com/Special:ListFiles`                                                      |
| 5   | Search            | `curl -s -o /dev/null -w "%{http_code}" "https://pigboats.com/index.php?search=submarine&title=Special%3ASearch"`                    |
| 6   | API version       | `curl -s "https://pigboats.com/api.php?action=query&meta=siteinfo&format=json"` (check generator)                                    |
| 7   | VisualEditor      | `curl -s -o /dev/null -w "%{http_code}" "https://pigboats.com/api.php?action=visualeditor&page=Main_Page&paction=parse&format=json"` |
| 8   | Edit token        | `curl -s -o /dev/null -w "%{http_code}" "https://pigboats.com/api.php?action=query&meta=tokens&type=csrf&format=json"`               |
| 9   | File page         | Test a `/File:*.jpg` page loads (200)                                                                                                |
| 10  | robots.txt        | `curl -s -o /dev/null -w "%{http_code}" https://pigboats.com/robots.txt`                                                             |
| 11  | HSTS header       | `curl -sI https://pigboats.com/ \| grep -i strict-transport`                                                                         |
| 12  | CF-Cache-Status   | `curl -sI https://pigboats.com/Dorado_Myths \| grep -i cf-cache-status`                                                              |
| 13  | DNS resolves      | `dig +short pigboats.com`                                                                                                            |
| 14  | Image thumbnails  | Test an image URL returns 200 with correct content-type                                                                              |
| 15  | PHP error log     | `ssh root@54.208.34.75 "tail -5 /var/log/alt-php84-error.log"`                                                                       |

## Cloudflare Operations

**Purge entire cache:**

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/884ceccb78f467243a69036f00318da5/purge_cache" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

**4 cache rules** (ruleset `bf567d50659f4984be9b6c6c2ca8cbc2`):

1. Bypass cache for logged-in users (cookie match)
2. Bypass cache for API/Special/edit pages
3. Cache static assets 1 year (`status_code_ttl: 0` for 4xx/5xx)
4. Cache wiki pages 1 hour (`status_code_ttl: 0` for 4xx/5xx)

**Rate limiting** (ruleset `aa5b3b1a6c864a6db1b79e0f64673318`, deployed 2026-03-08):

1. `/index.php` — 30 req/min per IP per colo, managed_challenge, 10min mitigation timeout
   - Rule ID: `3875b2b44d4945b6b6c6ae31632e8a9f`
   - Deployed to counter Singapore botnet (186K bot requests, 59K 504 timeouts)
   - Normal browsing uses clean URLs (not `/index.php`), so real visitors are unaffected

**CF Rate Limiting API notes:**

- Endpoint: `PUT /zones/{zone_id}/rulesets/phases/http_ratelimit/entrypoint`
- Body: only `name`, `description`, `rules` — do NOT include `kind` or `phase` fields
- `cf.colo.id` is REQUIRED in `ratelimit.characteristics` — rate limiting is processed per-colocation
- CF GraphQL analytics: the old REST `/analytics/dashboard` endpoint is sunset — use GraphQL at `/graphql`

## MediaWiki Release Monitoring

PigBoats.COM runs on the **MediaWiki 1.43 LTS branch** (supported through December 2027).

**Check what's installed:**

```bash
curl -s "https://pigboats.com/api.php?action=query&meta=siteinfo&format=json" | python3 -c "import sys,json; print(json.load(sys.stdin)['query']['general']['generator'])"
```

**Check what's available:**

```bash
curl -s https://releases.wikimedia.org/mediawiki/1.43/ | python3 -c "import sys,re; versions=re.findall(r'mediawiki-(1\.43\.\d+)\.tar\.gz', sys.stdin.read()); print(sorted(versions, key=lambda v: list(map(int,v.split('.'))))[-1] if versions else 'No releases found')"
```

**Check security announcements:** Web search for `mediawiki 1.43 security release site:mediawiki.org` or fetch `https://www.mediawiki.org/wiki/Release_notes/1.43`

**Check git-managed extensions:**

```bash
ssh root@54.208.34.75 "for ext in EmbedVideo MsUpload RandomSelection; do echo \"=== \$ext ===\"; cd /var/www/vhosts/a-gang.pigboats.com/pigboats.com/httpdocs/extensions/\$ext && git log --oneline -1 && git fetch --dry-run 2>&1; cd /; done"
```

Present findings to the user with a risk assessment before proceeding with any upgrade. For the full step-by-step upgrade procedure, read: `references/upgrade-procedure.md`

## Key Gotchas

- **Custom file in core tree**: `includes/CloudflareTrustedProxies.php` — MUST be excluded from `rsync --delete` during upgrades or it gets wiped, causing 500 errors
- **nginx static asset blocks**: Location blocks in `vhost_nginx.conf` for `.jpg`, `.css`, `.woff` etc. MUST have `try_files $uri @rewrite;` — without it, MW clean URLs like `/File:Photo.jpg` and `/MediaWiki:Common.css` get intercepted as static files and return 404
- **Plesk auto-generates config files**: `nginx.conf` and php-fpm pool configs get overwritten — use override files:
  - nginx: `/var/www/vhosts/system/pigboats.com/conf/vhost_nginx.conf`
  - PHP: `/var/www/vhosts/system/pigboats.com/conf/php.ini` with `[php-fpm-pool-settings]` section
- **HSTS**: Controlled by Plesk SSL It! extension, NOT nginx config: `plesk ext sslit --hsts -enable -domain pigboats.com -max-age 2years`
- **MW maintenance/run.php**: Use `run.php runJobs` NOT `run.php maintenance/runJobs.php` (don't double the path)
- **Cloudflare Always Online**: BAD for wikis — serves stale cached content. Never enable.
- **CSP headers**: Too fragile for MediaWiki — inline scripts, VisualEditor, extensions all break. Don't add.
- **Plesk backup path**: Backups go to `/mnt/plesk_backups/` (underscore, not hyphen). The default `/var/lib/psa/dumps/` directory is empty.
- **Shell heredocs over SSH**: Backticks and special chars get mangled. Write to local temp file, scp to server, then `cat >>` to append.
- **`CACHE_ACCEL` ≠ Redis**: APCu is NOT installed on PHP 8.4. `CACHE_ACCEL` resolves to `EmptyBagOStuff` (silent no-op). Always use the string `"redis"` for Redis-backed caches. This caused a 6-day session outage (2026-02-28 to 2026-03-06).

## Client Context

- **Client**: Dave Johnston — retired Navy chief, webmaster since January 2026. Non-technical but passionate about the site. Reports should be professional, plain-English, navy-themed.
- **Founder**: Ric Hedman — built pigboats.com in 1999, maintained it 25+ years, died January 31, 2026. Always credit Ric when discussing the site's history or mission.
- **The Dorado Project**: Dave, Thad, and Steve researching USS Dorado (lost WWII submarine).
- **Reporting style**: Submarine/navy analogies (watertight integrity, defense in depth), game-theory framing (dominant strategy, compounding returns). Keep the tone appropriate to the scope — a quick fix doesn't need the same weight as a major upgrade.
- **"Preserving the Mission" section**: Reserve for milestone reports (major upgrades, annual anniversary of Ric's passing). Do NOT include in routine fix or minor maintenance reports — it's too heavy for everyday work.

## Reporting Workflow

Every batch of changes follows a **four-document reporting cycle**. The reports ARE the deliverable as much as the technical work itself. Generate PDFs using the **ICCI Report Branding** system at `~/Documents/GitHub/icci-report-branding/` (Python API: `python/icci_report.py`, ICCIReport class). Always include the standard ICCI closing callout (`ICCIReport.icci_closing_callout()`) at the end of every report. For the legacy design system reference, see `references/pdf-design-system.md`.

### Document 1: Pre-Work Proposal PDF (for Dave)

- **Filename**: `~/Documents/claude-code/pigboats-<topic>-proposal-<date>.pdf`
- **Theme**: Blue (#3b82f6/#60a5fa), badge "Proposed Maintenance"
- **Content**: What we found, what needs to be done, risk level, test plan, deferred items, "Preserving the Mission"
- **Key rule**: "Nothing about your content or appearance will change" callout on page 1

### Document 2: Pre-Work Helpdesk Ticket (for Aaron)

- **Filename**: `~/Documents/claude-code/pigboats-<topic>-ticket-<date>.txt`
- **Format**: Plain text work order with phases, exact commands, test steps, rollback plan
- **Text formatting**: No hard wraps mid-sentence. Paragraphs flow naturally and only break at actual paragraph boundaries. Must paste cleanly into any helpdesk system or email client.

### Document 3: Completion PDF (for Dave)

- **Filename**: `~/Documents/claude-code/pigboats-<topic>-complete-<date>.pdf`
- **Theme**: Green (#16a34a/#4ade80), badge "Mission Complete"
- **Content**: What was done, test results scoreboard, win cards, defense in depth table, "Preserving the Mission"

### Document 4: Closing Helpdesk Response (for Aaron)

- **Filename**: `~/Documents/claude-code/pigboats-<topic>-closing-<date>.txt`
- **Format**: Short friendly message for Dave. Summary, heads-up, "open a ticket if anything seems off"
- **Text formatting**: No hard wraps mid-sentence. Paragraphs flow naturally and only break at actual paragraph boundaries. Must paste cleanly into any helpdesk system or email client.

### Tone Guidelines for Dave's Reports

- **Plain English only** — "We tightened the security settings" not "We set $wgVerifyMimeType = true"
- **Submarine/navy analogies** — watertight integrity, hull plates, damage control, standing watch
- **Game theory framing** — dominant strategy, compounding returns
- **Reassurance first** — lead with "nothing about your content changed", end with "open a ticket if anything"
- **Positive framing** — "8 improvements deployed" not "8 problems fixed"

For the complete PDF design system including full CSS, HTML component patterns, and color tokens, read: `references/pdf-design-system.md`

## Reference Files

Read these on demand when you need deeper detail:

| File                              | When to Read                                                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `references/server-reference.md`  | Detailed server config: nginx, PHP-FPM, caching, security settings, custom files, Cloudflare rules, deferred items |
| `references/upgrade-procedure.md` | Step-by-step MediaWiki tarball upgrade procedure with rsync exclusions, phase breakdown, and rollback plan         |
| `references/pdf-design-system.md` | Full CSS/HTML design system for generating proposal and completion PDFs with WeasyPrint                            |

## Task: $ARGUMENTS
