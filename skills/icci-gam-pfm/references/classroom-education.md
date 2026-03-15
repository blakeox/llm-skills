# Classroom & Education — GAM Reference

This is the school-focused reference for ICCI's K-8 school clients (stpatschool.org, stpaulannarbor.org, stmarypinckney.org). These workflows are designed for Catholic school environments with SIS integration (FACTS), student/staff OUs, and grade-based organization.

## Student Account Provisioning from SIS Export

### CSV Format (typical SIS export)
```
first,last,email,grade,gradyear,parent_email
John,Smith,jsmith@stu.stpatschool.org,5,2033,parent@gmail.com
```

### Bulk Create Students
```bash
# Create students from CSV with OU assignment by grade
gam csv students.csv gam create user "~email" \
    firstname "~first" lastname "~last" \
    password random org "/Students/Grade ~~grade~~" \
    notify admin@domain.org logpassword student_passwords.csv

# With custom schema for student metadata
gam csv students.csv gam create user "~email" \
    firstname "~first" lastname "~last" \
    password random org "/Students/Grade ~~grade~~" \
    StudentInfo.GradeLevel "~grade" StudentInfo.GraduationYear "~gradyear" \
    logpassword student_passwords.csv
```

### Bulk Password Reset (start of year or lost passwords)
```bash
# Reset all passwords in a grade
gam ou "/Students/Grade 5" update users password random \
    logpassword grade5_passwords.csv

# Reset from CSV with parent notification
gam csv reset_list.csv gam update user "~email" password random \
    notify "~parent_email" logpassword reset_passwords.csv

# Single student password reset
gam update user jsmith@stu.stpatschool.org password random \
    notify helpdesk@stpatschool.org
```

## Classroom Course Management

### Create Courses from SIS
```bash
# CSV: alias,name,section,teacher,room
# Example: math5a-2026,Math 5A,Fall 2026,teacher@stpatschool.org,Room 204
gam csv courses.csv gam create course alias "d:~alias" \
    name "~name" section "~section" teacher "~teacher" \
    room "~room" state ACTIVE

# Copy course with materials (for next semester/year)
gam create course alias "d:math5a-spring2027" copyfrom d:math5a-fall2026 \
    workstates PUBLISHED materialstates PUBLISHED members none
```

### Enroll Students
```bash
# Add single student
gam course d:math5a-2026 add students user student@stu.stpatschool.org

# Bulk enroll from CSV (course_alias,student_email)
gam csv enrollments.csv gam course "d:~~course_alias~~" \
    add students user "~student_email"

# Sync roster from CSV (adds missing, removes extras)
gam courses d:math5a-2026 sync students file math5a_students.txt

# Add-only sync (never removes — safer for mid-year)
gam courses d:math5a-2026 sync students addonly file math5a_students.txt
```

### Course Lifecycle
```bash
# List active courses
gam print courses states ACTIVE owneremail todrive

# Course info with participants
gam info course d:math5a-2026 show all

# Archive at end of semester
gam update course d:math5a-2026 state ARCHIVED

# Bulk archive from CSV
gam csv active_courses.csv gam update course "~alias" state ARCHIVED

# Print course participants
gam print course-participants todrive
```

## Guardian Management

Parents/guardians get email summaries of student Classroom activity.

```bash
# Invite guardian for student
gam user student@stu.stpatschool.org add guardian parent@gmail.com

# Bulk invite from SIS CSV (student_email,guardian_email)
gam csv guardians.csv gam user "~student_email" add guardian "~guardian_email"

# Check invitation status
gam print guardians invitations showstudentemails todrive

# Show accepted guardians
gam print guardians accepted todrive

# Delete guardian
gam user student@stu.stpatschool.org delete guardians parent@gmail.com
```

## Grade Promotion (End of Year)

This is the most critical annual operation for schools. Work BACKWARDS from highest grade to avoid collisions.

### K-8 Promotion Workflow
```bash
# Step 1: Graduate 8th graders — suspend and move to alumni
gam ou "/Students/Grade 8" suspend users
gam update org "/Alumni/Class of 2026" add ou "/Students/Grade 8"

# Step 2: Promote each grade (work backwards!)
gam update org "/Students/Grade 8" add ou "/Students/Grade 7"
gam update org "/Students/Grade 7" add ou "/Students/Grade 6"
gam update org "/Students/Grade 6" add ou "/Students/Grade 5"
gam update org "/Students/Grade 5" add ou "/Students/Grade 4"
gam update org "/Students/Grade 4" add ou "/Students/Grade 3"
gam update org "/Students/Grade 3" add ou "/Students/Grade 2"
gam update org "/Students/Grade 2" add ou "/Students/Grade 1"
gam update org "/Students/Grade 1" add ou "/Students/Kindergarten"

# Step 3: Import incoming kindergarteners from SIS
gam csv incoming_K.csv gam create user "~email" \
    firstname "~first" lastname "~last" \
    password random org "/Students/Kindergarten" \
    logpassword new_K_passwords.csv

# Step 4: Update custom schemas if used
gam csv promotions.csv gam update user "~email" \
    StudentInfo.GradeLevel "~new_grade" org "/Students/Grade ~~new_grade~~"
```

### CSV-Driven Flexible Promotion (when SIS does the mapping)
```bash
# CSV: email,newOU,newGrade
# More flexible — handles transfers, grade retention, etc.
gam csv promotions.csv gam update user "~email" org "~newOU"
```

## School Year Operations

### Summer Prep (June)
```bash
# 1. Archive all courses
gam print courses states ACTIVE fields id,name > active_courses.csv
gam csv active_courses.csv gam update course "~id" state ARCHIVED

# 2. Powerwash Chrome devices (if school-owned)
gam cros_ou "/ChromeOS/Student Devices" issuecommand command remote_powerwash doit

# 3. Move devices to storage OU
gam update org "/ChromeOS/Summer Storage" add cros_ou "/ChromeOS/Student Carts"

# 4. Suspend graduated students
gam ou "/Alumni/Class of 2026" suspend users
```

### Fall Setup (August)
```bash
# 1. Create new students from SIS export
gam csv new_students.csv gam create user "~email" \
    firstname "~first" lastname "~last" \
    password random org "/Students/Grade ~~grade~~" \
    logpassword new_passwords.csv

# 2. Create courses from SIS schedule
gam csv courses.csv gam create course alias "d:~alias" \
    name "~name" section "~section" teacher "~teacher" state ACTIVE

# 3. Enroll students in courses
gam csv enrollments.csv gam course "d:~~course~~" add students user "~student"

# 4. Invite guardians
gam csv guardians.csv gam user "~student" add guardian "~guardian_email"

# 5. Move Chrome devices to student OUs
gam update org "/ChromeOS/Student Carts" add cros_ou "/ChromeOS/Summer Storage"

# 6. Assign devices to students
gam csv device_assignments.csv gam cros_sn "~serial" update \
    user "~student_email" ou "~device_ou"
```

### Mid-Year Transfer In
```bash
# Create new student
gam create user newstudent@stu.stpatschool.org firstname New lastname Student \
    password random org "/Students/Grade 5" \
    notify helpdesk@stpatschool.org logpassword transfer_passwords.csv

# Enroll in courses
gam course d:math5a-2026 add students user newstudent@stu.stpatschool.org
gam course d:science5a-2026 add students user newstudent@stu.stpatschool.org

# Invite guardian
gam user newstudent@stu.stpatschool.org add guardian parent@gmail.com
```

### Mid-Year Withdrawal
```bash
# Remove from all courses
gam user withdrawn@stu.stpatschool.org delete classroominvitations
# Suspend
gam suspend user withdrawn@stu.stpatschool.org
# Move to inactive
gam update user withdrawn@stu.stpatschool.org org "/Students/Withdrawn"
```

## Student Safety & Monitoring

```bash
# Find unauthorized third-party app tokens on student accounts
gam ou_and_children "/Students" print tokens todrive

# Revoke specific app from all students
gam ou_and_children "/Students" delete token clientid SUSPICIOUS_CLIENT_ID

# Force signout compromised student
gam user student@stu.stpatschool.org signout

# Reset locked-out student (lost 2SV)
gam user student@stu.stpatschool.org turnoff2sv
gam user student@stu.stpatschool.org update backupcodes
gam user student@stu.stpatschool.org password random notify helpdesk@stpatschool.org

# Check who's logging in from suspicious locations
gam select stpatschool report login events login_success start -7d todrive
```

## ICCI School Client Quick Reference

| Domain | Students OU | Staff OU | SIS | Notes |
|--------|-----------|---------|-----|-------|
| stpatschool.org | /Students (stu.stpatschool.org) | /Faculty | FACTS | 590 users, secondary domain selcs.org |
| stpaulannarbor.org | (TBD) | (TBD) | (TBD) | 675 users |
| stmarypinckney.org | /Students (stu.stmarypinckney.org) | (TBD) | (TBD) | 163 users |
