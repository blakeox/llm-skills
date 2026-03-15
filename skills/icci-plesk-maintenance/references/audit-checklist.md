# Plesk Server Audit Checklist

Complete checklist for auditing the Plesk server. Run commands from root SSH session on 54.208.34.75.

## WordPress Per-Site Checks

Run for each active instance ID: 10, 13, 14, 18, 28, 40, 41, 43, 44, 48

### wp-config Constants
```bash
for id in 10 13 14 18 28 40 41 43 44 48; do
    echo "=== Instance $id ==="
    plesk ext wp-toolkit --wp-cli -instance-id $id -- config list --fields=name,value --format=table 2>&1 | \
      grep -E "(DISALLOW_FILE_EDIT|WP_POST_REVISIONS|EMPTY_TRASH_DAYS|WP_MEMORY_LIMIT|DISABLE_WP_CRON|WP_DEBUG)"
    echo ""
done
```

Expected for each site:
- DISALLOW_FILE_EDIT = 1 (true)
- WP_POST_REVISIONS = 5
- EMPTY_TRASH_DAYS = 14
- WP_MEMORY_LIMIT = 256M
- DISABLE_WP_CRON = 1 (true)
- WP_DEBUG should NOT appear, or should be false/0

### Uploads Directory Ownership
```bash
DOMAINS="beardedlamb.com benkerner.com catalog.formtechinc.com dahlmannproperties.com tappanbands.org xanderjazz.com monarchchildcenter.com new25.beardedlamb.com icci.com memorial.salsitz.com"
CURRENT_MONTH=$(date +%Y/%m)
for d in $DOMAINS; do
    dir="/var/www/vhosts/$d/httpdocs/wp-content/uploads/$CURRENT_MONTH"
    if [ -d "$dir" ]; then
        owner=$(stat -c "%U:%G" "$dir")
        expected=$(stat -c "%U:%G" "/var/www/vhosts/$d/httpdocs/wp-content/uploads/")
        if [ "$owner" = "$expected" ]; then
            echo "OK:  $d ($owner)"
        else
            echo "BAD: $d (is $owner, should be $expected)"
        fi
    else
        echo "N/A: $d (no $CURRENT_MONTH directory)"
    fi
done
```

### wp-config-sample.php (should not exist)
```bash
for d in $DOMAINS; do
    ls /var/www/vhosts/$d/httpdocs/wp-config-sample.php 2>/dev/null && echo "FOUND on $d"
done
echo "If no output above, all clean."
```

### Active Plugins (check for redundant security plugins)
```bash
for id in 10 13 14 18 28 40 41 43 44 48; do
    echo "=== Instance $id ==="
    plesk ext wp-toolkit --wp-cli -instance-id $id -- plugin list --status=active --fields=name,version --format=table 2>&1
    echo ""
done
```
Flag: wordfence, all-in-one-wp-security*, sucuri* (redundant with CF WAF)

### WordPress Core Version
```bash
plesk ext wp-toolkit --list 2>/dev/null | grep -E "Working|Outdated"
```

## Server-Level Checks

### Disk Space
```bash
df -h /var/www/vhosts/ /mnt/plesk_backups/
```

### MariaDB Health
```bash
MYSQL_PWD=$(cat /etc/psa/.psa.shadow) mysql -u admin -e "
SHOW VARIABLES LIKE 'tmp_table_size';
SHOW VARIABLES LIKE 'max_heap_table_size';
SHOW GLOBAL STATUS LIKE 'Created_tmp%';
SHOW GLOBAL STATUS LIKE 'Uptime';
"
```
Expected: tmp_table_size >= 64M, max_heap_table_size >= 64M, disk_tables/total_tables ratio < 25%

### PHP-FPM pm.max_requests
```bash
echo "=== alt-php84 ==="
grep "pm.max_requests" /opt/alt/php84/etc/php-fpm.d/*.conf | grep -v default | grep -v "= 1"
echo "=== plesk-php84 ==="
grep "pm.max_requests" /opt/plesk/php/8.4/etc/php-fpm.d/*.conf | grep -v "= 1"
```
Expected: all = 500 (except plesk-service which is 1)

### PHP-FPM Service Status
```bash
systemctl is-active alt-php84-fpm plesk-php84-fpm httpd nginx
```

### Apache RemoteIP
```bash
echo "=== Override file ==="
cat /etc/httpd/conf.d/zzz-remoteip-fix.conf
echo ""
echo "=== Verify header ==="
curl -sI https://beardedlamb.com 2>/dev/null | grep -i "x-content-type\|strict-transport"
```

### Cron Schedule
```bash
crontab -l | grep -v "^#$" | grep -v "^$"
```
Check: no collisions at same time, wp-cron runs as site users (not root), DB optimize at 4am

### SSL Certificates
```bash
for d in $DOMAINS; do
    echo -n "$d: "
    openssl s_client -connect $d:443 -servername $d 2>/dev/null | openssl x509 -noout -issuer -dates 2>/dev/null | tr '\n' ' '
    echo ""
done
```

## Cloudflare Checks

### HSTS Verification (sample)
```bash
CF_TOKEN="$CF_API_TOKEN"
curl -s "https://api.cloudflare.com/client/v4/zones/bacb9ba3c07b9d8c33c9d10f84957070/settings/security_header" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json"
```

### Always Use HTTPS (all zones)
```bash
CF_TOKEN="$CF_API_TOKEN"
ZONES=$(curl -s "https://api.cloudflare.com/client/v4/zones?per_page=50" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
  | python3 -c "import json,sys; [print(z['id']+' '+z['name']) for z in json.load(sys.stdin)['result']]")

echo "$ZONES" | while read zid zname; do
    val=$(curl -s "https://api.cloudflare.com/client/v4/zones/$zid/settings/always_use_https" \
      -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
      | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['value'])")
    [ "$val" != "on" ] && echo "OFF: $zname"
done
echo "If no output, all zones have Always Use HTTPS enabled."
```

### Cache Rules (WP zones)
```bash
for zid in bacb9ba3c07b9d8c33c9d10f84957070 980592193a1b7f4c55c38fc5bdc602e3 b15dd443a7cfff0bb6ef958e97a309c6 ad07a0d3564851e8b30dc0108070f094 34a1e09221fdba6f90a5d65940cf8f61 752417bb4028b169564303b8cc505043 6c99660e133ffeb9b6b41b3ba2a1dccb 70cd4c120620126127de402339362de5; do
    result=$(curl -s "https://api.cloudflare.com/client/v4/zones/$zid/rulesets/phases/http_request_cache_settings/entrypoint" \
      -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
      | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('success') and d.get('result',{}).get('rules') else 'MISSING')")
    echo "$zid: $result"
done
```
