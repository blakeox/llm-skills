# GAM Recipes — PFM-Level Tricks & Shortcuts

Cool shortcuts, time-savers, and logical command combinations that make GAM feel like Pure Fucking Magic.

## One-Liners That Save Hours

### "Who has no MFA?" (across all domains)
```bash
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent stpatschool stpaul stmary stjos okf; do
    echo "=== $section ==="
    ~/bin/gam7/gam select $section print users fields primaryEmail,isEnrolledIn2Sv query "isEnrolledIn2Sv=false" 2>/dev/null | tail -n +2
done
```

### "Show me every admin across all my domains"
```bash
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent stpatschool stpaul stmary stjos okf; do
    echo "=== $section ==="
    ~/bin/gam7/gam select $section print admins 2>/dev/null | tail -n +2
done
```

### "How many users per domain?"
```bash
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent stpatschool stpaul stmary stjos okf; do
    count=$(~/bin/gam7/gam select $section print users 2>/dev/null | tail -n +2 | wc -l)
    echo "$section: $count users"
done
```

### "Find all forwarding rules" (detect exfiltration)
```bash
~/bin/gam7/gam select $SECTION all users show forward 2>&1 | grep -v "^User\|^$\|^Getting\|^Got"
```

### "Nuke a compromised account" (full lockdown in one line)
```bash
~/bin/gam7/gam select $SECTION user COMPROMISED@domain.com deprovision popimap signout turnoff2sv && \
~/bin/gam7/gam select $SECTION update user COMPROMISED@domain.com password random changepasswordatnextlogin
```

### "Who logged in from outside the US?"
```bash
~/bin/gam7/gam select $SECTION report login start -30d todrive | \
    python3 -c "import csv,sys; [print(r) for r in csv.DictReader(sys.stdin) if r.get('networkInfo.regionCode.0','US') != 'US']"
```

## School PFM Recipes

### "Print student passwords for homeroom teachers"
After a bulk password reset, generate per-teacher password sheets:
```bash
# After running: gam csv students.csv gam update user "~email" password random logpassword all_passwords.csv
# Split by homeroom/teacher:
python3 -c "
import csv
from collections import defaultdict
teachers = defaultdict(list)
with open('all_passwords.csv') as f:
    for row in csv.DictReader(f):
        teachers[row['homeroom']].append(row)
for teacher, students in teachers.items():
    with open(f'passwords_{teacher}.csv', 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['name','email','password'])
        w.writeheader()
        w.writerows(students)
"
```

### "Which students haven't logged in this school year?"
```bash
~/bin/gam7/gam select stpatschool print users limittoou "/Students" \
    fields primaryEmail,name,lastLoginTime | \
    python3 -c "
import csv, sys
from datetime import datetime
for r in csv.DictReader(sys.stdin):
    login = r.get('lastLoginTime','')
    if not login or login < '2025-09-01':
        print(f\"{r['primaryEmail']}: last login {login or 'NEVER'}\")
"
```

### "Bulk create student accounts with firstname.lastname pattern"
```bash
# Input CSV: first,last,grade
# Output: firstlast@stu.stpatschool.org
python3 -c "
import csv
with open('sis_export.csv') as fin, open('gam_import.csv', 'w', newline='') as fout:
    w = csv.writer(fout)
    w.writerow(['email','first','last','grade','ou'])
    for r in csv.DictReader(fin):
        first = r['first'].lower().strip()
        last = r['last'].lower().strip()
        email = f'{first[0:2]}{last}@stu.stpatschool.org'
        w.writerow([email, r['first'], r['last'], r['grade'], f'/Students/Grade {r[\"grade\"]}'])
" && gam csv gam_import.csv gam create user "~email" firstname "~first" lastname "~last" \
    password random org "~ou" logpassword new_student_passwords.csv
```

## MSP PFM Recipes

### "License audit across all reseller customers"
```bash
~/bin/gam7/gam print resoldsubscriptions todrive
# This gives you every subscription, seat count, and status for all 24 reseller domains
```

### "Quick health check on any domain"
```bash
domain_check() {
    section=$1
    echo "=== $section ==="
    echo -n "Domain: "; ~/bin/gam7/gam select $section info domain 2>&1 | grep "Primary Domain:"
    echo -n "Users: "; ~/bin/gam7/gam select $section print users 2>/dev/null | tail -n +2 | wc -l
    echo -n "Groups: "; ~/bin/gam7/gam select $section print groups 2>/dev/null | tail -n +2 | wc -l
    echo -n "No MFA: "; ~/bin/gam7/gam select $section print users fields primaryEmail,isEnrolledIn2Sv query "isEnrolledIn2Sv=false" 2>/dev/null | tail -n +2 | wc -l
    echo "---"
}
```

### "Find shared/role accounts across all domains" (security risk)
```bash
# These are the accounts attackers love to target
for section in icci wvhcares pco iraniwise dahlmannproperties dahlmannhotels annarborregent; do
    echo "=== $section ==="
    ~/bin/gam7/gam select $section print users fields primaryEmail,name 2>/dev/null | \
        grep -iE "^(office|front|desk|reception|info|admin|sales|accounting|bookkeep|shared|general|main)@"
done
```

### "What third-party apps have access?" (OAuth audit)
```bash
~/bin/gam7/gam select $SECTION all users print tokens todrive
# Then sort by appname to find suspicious apps
```

### "Emergency: Suspend everyone in an OU and force signout"
```bash
~/bin/gam7/gam select $SECTION ou "/Compromised" suspend users
~/bin/gam7/gam select $SECTION ou "/Compromised" signout
```

## Report Generation Recipes

### "Generate user directory for client"
```bash
~/bin/gam7/gam select $SECTION print users fields primaryEmail,name.fullName,orgUnitPath,isAdmin,lastLoginTime \
    orderby familyname todrive tdtitle "User Directory - $(date +%Y-%m-%d)"
```

### "Monthly login summary"
```bash
~/bin/gam7/gam select $SECTION report login start -30d todrive \
    tdtitle "Login Report - $(date +%Y-%m)" \
    tdparent "1ABC..." # Google Drive folder ID
```

### "Storage hogs"
```bash
~/bin/gam7/gam select $SECTION report usage user services drive \
    fields accounts:drive_used_quota_in_mb todrive \
    tdtitle "Drive Usage Report"
```

## Cool GAM Config Tricks

### Auto-batch for speed
```ini
# In gam.cfg [DEFAULT] section:
auto_batch_min = 1
num_threads = 10
```
This parallelizes any multi-user command automatically.

### Redirect output to specific files
```bash
~/bin/gam7/gam redirect csv ./users.csv redirect stderr ./errors.log print users allfields
```

### todrive with specific folder
```bash
~/bin/gam7/gam print users allfields todrive tdparent "FOLDER_ID" tdtitle "Report Name"
```

## Things to Remember

- `gam all users` = all non-suspended users. Use `gam all users_ns` for same, `gam all users_susp` for suspended only
- `gam ou "/Path"` = direct members only. `gam ou_and_children "/Path"` = recursive
- `cros_sn SERIAL` lets you target Chrome devices by serial number (no deviceId lookup needed)
- `todrive` uploads CSV output directly to the authenticated user's Google Drive
- `addnumericsuffixonduplicate 3` on user creation auto-handles email conflicts (jsmith, jsmith2, jsmith3)
- Date filters use `start` and `end` for reports, `-Nd` for relative (e.g., `start -90d`)
