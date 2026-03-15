# Chrome Device Management — GAM Reference

## List and Query Devices

```bash
# All devices with all fields
gam print cros allfields todrive

# Specific fields
gam print cros fields deviceId,serialNumber,orgUnitPath,status,lastSync,osVersion,annotatedUser todrive

# Query by status
gam print cros query "status:provisioned" todrive

# Recent activity and users
gam print crosactivity recentusers both todrive

# Single device by serial
gam cros_sn SERIALNUMBER info allfields

# Devices not synced in 30 days
gam print cros query "sync:..2026-02-01" fields serialNumber,lastSync,orgUnitPath,annotatedUser todrive
```

## Update Devices

```bash
# Set asset tag
gam cros_sn SERIALNUMBER update assettag "ASSET-001"

# Add notes
gam cros_sn SERIALNUMBER update notes "Assigned to Room 101"

# Assign user
gam cros_sn SERIALNUMBER update user "student@domain.com"

# Move to OU
gam cros_sn SERIALNUMBER update ou "/ChromeOS/Lab Devices"

# Bulk move by OU
gam update org "/ChromeOS/Carts" add cros_ou "/ChromeOS/Staging"

# Bulk update from CSV (serial,user,ou)
gam csv device_assignments.csv gam cros_sn "~serial" update \
    user "~user" ou "~ou" notes "Assigned to ~~user~~"
```

## Device Actions

```bash
# Disable device
gam cros_sn SERIALNUMBER update action disable

# Re-enable device
gam cros_sn SERIALNUMBER update action reenable

# Deprovision (retiring device — frees license)
gam cros_sn SERIALNUMBER update action deprovision_retiring_device \
    acknowledge_device_touch_requirement

# Deprovision (same model replacement — keeps license)
gam cros_sn SERIALNUMBER update action deprovision_same_model_replace \
    acknowledge_device_touch_requirement

# Deprovision (upgrade transfer — moves license to new device)
gam cros_sn SERIALNUMBER update action deprovision_upgrade_transfer \
    acknowledge_device_touch_requirement

# Bulk deprovision from CSV
gam csv broken_devices.csv gam cros_sn "~serial" update \
    action deprovision_retiring_device acknowledge_device_touch_requirement
```

## Remote Commands

```bash
# Reboot
gam cros_sn SERIALNUMBER issuecommand command reboot doit

# Remote powerwash
gam cros_sn SERIALNUMBER issuecommand command remote_powerwash doit

# Wipe user profiles (keeps enrollment)
gam cros_sn SERIALNUMBER issuecommand command wipe_users doit

# Take screenshot
gam cros_sn SERIALNUMBER issuecommand command take_a_screenshot doit

# Bulk powerwash from OU
gam cros_ou "/ChromeOS/Summer Storage" issuecommand command remote_powerwash doit
```

## School Device Fleet Patterns

### Summer Storage
```bash
# Move all student devices to summer OU
gam update org "/ChromeOS/Summer Storage" add cros_ou "/ChromeOS/Student Carts"
# Powerwash all
gam cros_ou "/ChromeOS/Summer Storage" issuecommand command remote_powerwash doit
```

### Fall Deployment
```bash
# Move back to student OUs
gam update org "/ChromeOS/Student Carts" add cros_ou "/ChromeOS/Summer Storage"
# Assign to students from CSV
gam csv assignments.csv gam cros_sn "~serial" update user "~student" ou "~ou"
```

### Inventory Report
```bash
gam print cros fields serialNumber,status,orgUnitPath,lastSync,osVersion,annotatedUser,annotatedAssetId \
    todrive tdtitle "Chrome Device Inventory - $(date +%Y-%m-%d)"
```
