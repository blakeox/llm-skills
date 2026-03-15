# User Management — GAM Reference

## Create User

```bash
# Basic creation
gam create user jsmith@domain.com firstname John lastname Smith password "Temp1234!" org "/Staff"

# With random password, notification, and group membership
gam create user jsmith@domain.com firstname John lastname Smith \
    password random notify admin@domain.com groups member staff@domain.com

# With license assignment
gam create user jsmith@domain.com firstname John lastname Smith \
    password random license 1010020020 org "/Staff"

# Log password to file (for bulk operations)
gam create user jsmith@domain.com firstname John lastname Smith \
    password random logpassword new_passwords.csv
```

## Update User

```bash
# Change password
gam update user jsmith@domain.com password "NewPassword123!"

# Random password with notification
gam update user jsmith@domain.com password random notify admin@domain.com

# Force password change at next login
gam update user jsmith@domain.com password random changepasswordatnextlogin

# Move to different OU
gam update user jsmith@domain.com org "/Former Staff"

# Update name
gam update user jsmith@domain.com firstname Jane lastname "Smith-Jones"

# Rename (change primary email)
gam update user jsmith@domain.com email jsjones@domain.com

# Add recovery email/phone
gam update user jsmith@domain.com recoveryemail personal@gmail.com recoveryphone "+15551234567"
```

## Suspend / Unsuspend / Delete

```bash
# Suspend user
gam suspend user jsmith@domain.com

# Unsuspend user
gam unsuspend user jsmith@domain.com

# Delete user (moves to trash, recoverable for 20 days)
gam delete user jsmith@domain.com

# Undelete user (within 20-day window)
gam undelete user jsmith@domain.com ou "/Staff"

# Bulk suspend OU
gam ou "/Departing" suspend users
```

## Query and List Users

```bash
# All users with all fields
gam print users allfields todrive

# Users in specific OU
gam print users limittoou "/Students" fields primaryEmail,name,orgUnitPath

# Suspended users
gam print users issuspended true fields primaryEmail,name,suspensionReason

# Count by OU
gam print usercountsbyorgunit

# Single user info
gam info user jsmith@domain.com

# Full info with groups and licenses
gam info user jsmith@domain.com groups licenses

# 2SV enrollment status
gam print users fields primaryEmail,isEnrolledIn2Sv,isEnforcedIn2Sv

# Users created in last 30 days
gam print users query "creationTime>=2026-02-01" fields primaryEmail,name,creationTime

# Admin users
gam print users query "isAdmin=true" fields primaryEmail,name,isAdmin,isDelegatedAdmin

# Never logged in
gam print users fields primaryEmail,name,lastLoginTime query "lastLoginTime=1970-01-01T00:00:00.000Z"
```

## Aliases

```bash
# Add alias
gam create alias jsmith@domain.com user janesmith@domain.com

# Delete alias
gam delete alias jsmith@domain.com

# Print all aliases
gam print aliases todrive
```

## Custom Schemas (for school metadata)

```bash
# Create schema for student info
gam create schema StudentInfo \
    field GradeLevel type string endfield \
    field GraduationYear type int64 endfield \
    field HomeRoom type string endfield \
    field StudentID type string indexed endfield

# Set custom attributes on user
gam update user student@domain.com StudentInfo.GradeLevel "9" \
    StudentInfo.GraduationYear 2030 StudentInfo.HomeRoom "Room 101"

# Print users with custom schema
gam print users schemas StudentInfo fields primaryEmail,name todrive
```

## Admin Role Management

```bash
# Print all admin role assignments
gam print admins

# Print available roles
gam print adminroles

# Assign role to user
gam create admin user jsmith@domain.com role _HELP_DESK_ADMIN_ROLE

# Remove admin role
gam delete admin user jsmith@domain.com role _HELP_DESK_ADMIN_ROLE
```
