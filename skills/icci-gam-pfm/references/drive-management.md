# Drive Management — GAM Reference

## File Operations

```bash
# Upload file
gam user jsmith@domain.com create drivefile localfile report.pdf drivefilename "Q1 Report"

# Create folder
gam user jsmith@domain.com create drivefile drivefilename "Projects" mimetype gfolder

# Create folder path
gam user jsmith@domain.com create drivefolderpath fullpath "Projects/2026/Q1"

# Download file
gam user jsmith@domain.com get drivefile id FILEID targetfolder ./downloads/

# Trash / Purge
gam user jsmith@domain.com trash drivefile id FILEID
gam user jsmith@domain.com purge drivefile id FILEID
```

## Permissions/Sharing

```bash
# Share with user
gam user jsmith@domain.com add drivefileacl id FILEID user colleague@domain.com role writer

# Share with group
gam user jsmith@domain.com add drivefileacl id FILEID group team@domain.com role reader

# Link sharing (anyone with link)
gam user jsmith@domain.com add drivefileacl id FILEID anyone role reader withlink

# Remove sharing
gam user jsmith@domain.com delete drivefileacl id FILEID colleague@domain.com

# Print permissions
gam user jsmith@domain.com print drivefileacls id FILEID todrive
```

## File Listing and Search

```bash
# All files
gam user jsmith@domain.com print filelist allfields todrive

# Files shared externally
gam user jsmith@domain.com print filelist showownedby me \
    fields id,name,permissions pmtype anyone todrive

# File tree
gam user jsmith@domain.com show filetree

# Search by name
gam user jsmith@domain.com print filelist query "name contains 'Budget'" todrive

# Large files (>100MB)
gam user jsmith@domain.com print filelist minimumfilesize 100000000 fields id,name,size todrive

# By MIME type
gam user jsmith@domain.com print filelist showmimetype application/pdf todrive
```

## Drive Transfer

```bash
# Transfer all files
gam user departing@domain.com transfer drive manager@domain.com

# With retained access
gam user departing@domain.com transfer drive manager@domain.com retainrole reader

# Specific folder
gam user departing@domain.com transfer drive manager@domain.com \
    select id FOLDERID targetfoldername "Transferred Files"

# Preview (dry run)
gam user departing@domain.com transfer drive manager@domain.com preview
```

## Shared Drives

```bash
# Create
gam user admin@domain.com create teamdrive "Engineering Shared Drive"

# Print all (admin access)
gam print teamdrives adminaccess todrive

# Add member
gam user admin@domain.com add drivefileacl teamdriveid DRIVEID \
    user jsmith@domain.com role organizer

# Print all permissions
gam print teamdriveacls adminaccess todrive

# Delete (must be empty or use allowitemdeletion)
gam user admin@domain.com delete teamdrive id DRIVEID allowitemdeletion
```
