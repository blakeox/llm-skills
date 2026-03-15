# Offboarding & Account Lifecycle — GAM Reference

## Full Employee Offboarding Workflow

Run these in order for a departing employee:

```bash
DOMAIN="domain.com"
USER="departing@$DOMAIN"
MANAGER="manager@$DOMAIN"
SECTION="sectionname"

# 1. Transfer Drive ownership to manager
~/bin/gam7/gam select $SECTION user $USER transfer drive $MANAGER

# 2. Set vacation responder
~/bin/gam7/gam select $SECTION user $USER vacation true \
    subject "No Longer With Company" \
    message "This person is no longer with the company. Please contact reception@$DOMAIN."

# 3. Set email forwarding to manager
~/bin/gam7/gam select $SECTION user $USER forward true keep $MANAGER

# 4. Deprovision (revoke tokens, app passwords, backup codes, disable POP/IMAP, signout)
~/bin/gam7/gam select $SECTION user $USER deprovision popimap signout turnoff2sv

# 5. Remove from all groups
~/bin/gam7/gam select $SECTION user $USER delete groups

# 6. Suspend
~/bin/gam7/gam select $SECTION suspend user $USER

# 7. Move to departing OU
~/bin/gam7/gam select $SECTION update user $USER org "/Former Employees"

# 8. Remove licenses (optional, saves cost)
~/bin/gam7/gam select $SECTION user $USER delete license allskus
```

## Data Transfer API

```bash
# Transfer Drive files via admin API
gam create datatransfer departing@domain.com drive manager@domain.com all

# Transfer Calendar
gam create datatransfer departing@domain.com calendar manager@domain.com

# Both with wait (checks every 10s, up to 5 times)
gam create datatransfer departing@domain.com drive,calendar manager@domain.com all wait 10 5

# Check transfer status
gam info datatransfer TRANSFERID

# List all transfers
gam print datatransfers todrive
```

## School Student Exit

```bash
# Remove from courses
gam user student@stu.domain.org delete classroominvitations

# Remove guardians
gam user student@stu.domain.org delete guardians

# Suspend
gam suspend user student@stu.domain.org

# Move to withdrawn OU
gam update user student@stu.domain.org org "/Students/Withdrawn"
```

## Account Reactivation

```bash
# Unsuspend
gam unsuspend user jsmith@domain.com

# Move back to active OU
gam update user jsmith@domain.com org "/Staff"

# Reset password
gam update user jsmith@domain.com password random notify admin@domain.com changepasswordatnextlogin

# Re-add to groups
gam update group staff@domain.com add member user jsmith@domain.com
```

## Account Deletion (permanent)

```bash
# Delete user (20-day recovery window)
gam delete user jsmith@domain.com

# Undelete within 20 days
gam undelete user jsmith@domain.com ou "/Staff"

# After 20 days: gone forever
```

## License Management During Lifecycle

```bash
# Show all license counts
gam show licenses

# Print license assignments
gam print licenses todrive

# Assign license
gam user jsmith@domain.com add license 1010020020

# Remove license
gam user jsmith@domain.com delete license 1010020020

# Change license (upgrade/downgrade)
gam user jsmith@domain.com update license NEWSKU from OLDSKU
```
