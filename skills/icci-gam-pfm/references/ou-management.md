# Organizational Unit Management — GAM Reference

## Create / Update / Delete OUs

```bash
# Create OU
gam create org "/Students/Grade 9" description "9th Grade Students"

# Auto-create parent path
gam create org "/Students/2026/Grade 9" buildpath

# Update OU
gam update org "/Students/Grade 9" name "Grade 10" description "10th Grade"

# Move OU under different parent
gam update org "/Students/Grade 9" parent "/Archive"

# Delete OU (must be empty)
gam delete org "/Archive/Old OU"
```

## Move Users Between OUs

```bash
# Single user
gam update org "/Staff" add user jsmith@domain.com

# From CSV
gam csv students.csv gam update user "~email" org "~newOU"

# All users from one OU to another
gam update org "/New OU" add ou "/Old OU"

# Sync OU (move extras to specified OU)
gam update org "/Active Students" sync file active_students.txt removetoou "/Inactive"
```

## Display OUs

```bash
# Full OU tree
gam show orgtree

# Print all OUs to CSV
gam print orgs allfields todrive

# Info on specific OU
gam info org "/Students/Grade 9"

# Without user list
gam info org "/Students" nousers children
```

## School Grade Promotion

See `references/classroom-education.md` for the full K-8 promotion workflow. Key principle: **work backwards from highest grade to lowest** to avoid overwriting.
