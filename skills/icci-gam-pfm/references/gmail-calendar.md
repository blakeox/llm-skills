# Gmail & Calendar — GAM Reference

## Gmail Forwarding

```bash
# Add forwarding address (requires verification)
gam user jsmith@domain.com add forwardingaddress backup@domain.com

# Enable forwarding (keep copy in inbox)
gam user jsmith@domain.com forward true keep backup@domain.com

# Enable forwarding (archive original)
gam user jsmith@domain.com forward true archive backup@domain.com

# Disable forwarding
gam user jsmith@domain.com forward false

# Show forwarding settings
gam user jsmith@domain.com show forward

# All users' forwarding (enabled only)
gam all users print forward enabledonly todrive
```

## Gmail Delegates

```bash
# Add delegate (assistant can read/send as exec)
gam user exec@domain.com add delegate assistant@domain.com

# Remove delegate
gam user exec@domain.com delete delegate assistant@domain.com

# Show delegates
gam user exec@domain.com show delegates shownames

# All users' delegates
gam all users print delegates shownames todrive
```

## Gmail Filters

```bash
# Label incoming from specific sender
gam user jsmith@domain.com create filter from alerts@company.com label "Alerts"

# Auto-trash
gam user jsmith@domain.com create filter from noreply@spam.com trash

# Show all filters
gam user jsmith@domain.com show filters

# Print filters to CSV
gam user jsmith@domain.com print filters todrive

# Delete filter
gam user jsmith@domain.com delete filters FILTERID
```

## Gmail Signatures

```bash
# Set HTML signature
gam user jsmith@domain.com signature "<b>John Smith</b><br>IT Director<br>ACME Corp"

# From file with tag replacement
gam user jsmith@domain.com signature file sig_template.html html \
    replace "#name#" "John Smith" replace "#title#" "IT Director"

# All users from template with auto-substitution
gam all users signature file sig_template.html html \
    replace "#email#" user replace "#name#" user

# Show signature
gam user jsmith@domain.com show signature format

# Clear signature
gam user jsmith@domain.com signature ""
```

## Vacation / Out-of-Office

```bash
# Enable
gam user jsmith@domain.com vacation true subject "Out of Office" \
    message "I am out of the office until March 15." \
    start 2026-03-01 end 2026-03-15

# Disable
gam user jsmith@domain.com vacation false

# Show
gam user jsmith@domain.com show vacation
```

## Send-As Addresses

```bash
# Add send-as
gam user jsmith@domain.com create sendas sales@domain.com name "Sales Team" treatasalias true

# Delete send-as
gam user jsmith@domain.com delete sendas sales@domain.com

# Show all send-as
gam user jsmith@domain.com show sendas
```

## IMAP/POP Settings

```bash
# Enable/disable IMAP
gam user jsmith@domain.com imap true
gam user jsmith@domain.com imap false

# Enable/disable POP
gam user jsmith@domain.com pop true for newmail action keep
gam user jsmith@domain.com pop false

# Show settings
gam user jsmith@domain.com show imap
gam user jsmith@domain.com show pop
```

## Calendar ACLs

```bash
# Add read access to resource calendar
gam calendar room101@resource.calendar.google.com add acl reader user jsmith@domain.com

# Add write access for group
gam calendar room101@resource.calendar.google.com add acl writer group staff@domain.com

# Domain-wide freebusy
gam calendar room101@resource.calendar.google.com add acl freebusyreader domain domain.com

# Remove access
gam calendar room101@resource.calendar.google.com delete acl reader user jsmith@domain.com

# Show calendar ACLs
gam calendar room101@resource.calendar.google.com show acls
```

## Calendar Events

```bash
# Create event
gam user jsmith@domain.com add event primary summary "Team Meeting" \
    start "2026-03-15T10:00:00" end "2026-03-15T11:00:00" \
    attendee staff@domain.com

# Delete events by query
gam user jsmith@domain.com delete events primary matchfield summary "Cancelled" doit

# Print events in date range
gam user jsmith@domain.com print events primary \
    timemin 2026-03-01T00:00:00 timemax 2026-03-31T23:59:59 todrive

# Wipe all events
gam user jsmith@domain.com wipe events primary
```

## User Calendar Management

```bash
# List user's calendars
gam user jsmith@domain.com show calendars

# Add calendar to user
gam user jsmith@domain.com add calendars room101@resource.calendar.google.com

# Remove calendar
gam user jsmith@domain.com remove calendars room101@resource.calendar.google.com
```

## Resources (Buildings/Rooms)

```bash
# Create building
gam create building "Main Building" id MAIN address "123 School St" floors "1,2,3"

# Create room
gam create resource ROOM101 "Room 101" building MAIN floor 1 capacity 30 type "Classroom"

# Print all resources
gam print resources allfields todrive

# Print buildings
gam print buildings allfields todrive
```
