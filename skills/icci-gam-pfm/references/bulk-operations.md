# Bulk Operations — GAM Reference

## CSV-Driven Commands

```bash
# Each CSV row runs a GAM command with field substitution
gam csv users.csv gam update user "~primaryEmail" org "~newOU"

# Field substitution in strings (double tilde for inline)
gam csv users.csv gam update user "~email" \
    address type work unstructured "~~street~~, ~~city~~, ~~state~~ ~~zip~~"

# Row filtering
gam csv users.csv matchfield department "Engineering" \
    gam update user "~primaryEmail" org "/Engineering"

# Skip rows
gam csv users.csv skipfield status "inactive" \
    gam update user "~primaryEmail" org "/Active"

# From Google Sheet
gam csv gsheet admin@domain.com SPREADSHEETID 0 \
    gam create user "~email" firstname "~first" lastname "~last" password random

# Limit rows
gam csv users.csv skiprows 0 maxrows 100 gam info user "~primaryEmail"
```

## Batch Processing

```bash
# Parallel execution
gam batch commands.txt

# Thread-based (supports CSV sub-commands)
gam tbatch commands.txt

# Show commands as they execute
gam batch commands.txt showcmds
```

Batch file format:
```
# Comment
gam create user user1@domain.com firstname User lastname One password random
gam create user user2@domain.com firstname User lastname Two password random
commit-batch
gam update group staff@domain.com add member user user1@domain.com
```

## Multiprocess CSV Output

```bash
# Parallel output from multiple users
gam redirect csv ./all_files.csv multiprocess csv users.csv \
    gam user "~primaryEmail" print filelist fields id,name,mimetype

# Auto-batch (automatic parallelism)
gam config auto_batch_min 1 redirect csv ./output.csv multiprocess \
    all users print filelist fields id,name,mimetype
```

## User Collections

| Syntax | Description |
|--------|-------------|
| `all users` | All non-suspended users |
| `all users_ns` | All non-suspended users (same) |
| `all users_susp` | All suspended users |
| `user email@domain.com` | Single user |
| `users email1,email2` | User list |
| `group group@domain.com` | Group members |
| `ou "/OU Path"` | Direct OU members |
| `ou_and_children "/OU"` | OU + all sub-OUs (recursive) |
| `query "orgUnitPath='/Students'"` | Query-based |
| `file users.txt` | From file (one per line) |
| `csvfile users.csv:email` | From CSV column |
| `courseparticipants COURSEID` | Course members |
| `license SKUID` | Users with specific license |

## Performance Config (gam.cfg)

```ini
[DEFAULT]
num_threads = 5          # Thread parallelism
num_tbatch_threads = 2   # tbatch thread count
auto_batch_min = 0       # 0=disabled, 1=always auto-batch
```

Set `auto_batch_min = 1` and `num_threads = 10` for maximum speed on bulk operations.
