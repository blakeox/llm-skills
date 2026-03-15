# Group Management — GAM Reference

## Create / Update / Delete Groups

```bash
# Create group
gam create group staff@domain.com name "All Staff" description "All staff members"

# Create from template
gam create group newgroup@domain.com copyfrom template@domain.com

# Update group settings
gam update group staff@domain.com name "Staff Group" whoCanPostMessage ALL_IN_DOMAIN_CAN_POST

# Make security group
gam update group staff@domain.com makesecuritygroup

# Delete group
gam delete group oldgroup@domain.com
```

## Membership Operations

```bash
# Add member
gam update group staff@domain.com add member user jsmith@domain.com

# Add manager/owner
gam update group staff@domain.com add manager user jsmith@domain.com
gam update group staff@domain.com add owner user jsmith@domain.com

# Remove member
gam update group staff@domain.com remove member user jsmith@domain.com

# Sync members from CSV (adds missing, removes extras)
gam update group staff@domain.com sync member file members.csv

# Sync add-only (never removes — safe for manual additions)
gam update group staff@domain.com sync member addonly file members.csv

# Clear all members
gam update group staff@domain.com clear member

# Update delivery setting
gam update group staff@domain.com update member delivery nomail user jsmith@domain.com

# Remove user from ALL groups
gam user jsmith@domain.com delete groups
```

## Display Groups and Members

```bash
# All groups
gam print groups allfields todrive

# Groups with member counts
gam print groups memberscount managerscount ownerscount

# Group members
gam print group-members group staff@domain.com

# Recursive membership (expands nested groups)
gam print group-members group staff@domain.com recursive

# Group tree (nested)
gam show grouptree group staff@domain.com

# Groups a user belongs to
gam print groups member jsmith@domain.com

# All group memberships for all users
gam print group-members todrive
```

## Group Settings

Key settings you can modify:

| Setting | Values | Description |
|---------|--------|-------------|
| whoCanPostMessage | NONE_CAN_POST, ALL_MANAGERS_CAN_POST, ALL_MEMBERS_CAN_POST, ALL_IN_DOMAIN_CAN_POST, ANYONE_CAN_POST | Who can send to the group |
| whoCanViewMembership | ALL_IN_DOMAIN_CAN_VIEW, ALL_MEMBERS_CAN_VIEW, ALL_MANAGERS_CAN_VIEW | Who sees members |
| isArchived | true/false | Enable/disable conversation archive |
| allowExternalMembers | true/false | Allow non-domain members |
| messageModerationLevel | MODERATE_ALL_MESSAGES, MODERATE_NON_MEMBERS, MODERATE_NEW_MEMBERS, MODERATE_NONE | Moderation |
| spamModerationLevel | ALLOW, MODERATE, SILENTLY_MODERATE, REJECT | Spam handling |

```bash
# Example: Lock down group to managers only, no external
gam update group secure@domain.com \
    whoCanPostMessage ALL_MANAGERS_CAN_POST \
    allowExternalMembers false \
    messageModerationLevel MODERATE_NON_MEMBERS
```
