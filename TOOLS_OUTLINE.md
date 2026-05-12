# Troubleshooting Tools - zt-lb1577-1 Lab (Web Server Permissions)

## Lab Overview
This lab teaches how to diagnose and fix web server problems caused by incorrect file ownership and SELinux context after restoring from backup.

## Key Concept
Understanding that Linux security involves multiple layers (DAC permissions AND MAC SELinux), and both must be correct for services to access files.

---

## Tools Used & Their Application

### 1. **grep** - Search Text Patterns
**Purpose:** Find configuration directives in Apache config files

**Usage in Lab:**
- Module 02: Find DocumentRoot in httpd configuration
  ```bash
  sudo grep '^DocumentRoot' /etc/httpd/conf/httpd.conf
  ```

**Slide Points:**
- Searches for text patterns in files
- `^` = anchor to beginning of line
  - `'^DocumentRoot'` = lines STARTING with DocumentRoot
  - Excludes commented lines (which start with #)
- Faster than manually opening and searching large config files
- Essential for finding specific directives in configuration files
- Can search multiple files: `grep pattern /etc/*.conf`

---

### 2. **ls** - List Directory Contents
**Purpose:** Inspect files, permissions, and SELinux contexts

**Usage in Lab:**
- Module 02: Check if files exist in web root
  ```bash
  sudo ls /var/www/html
  ```
- Module 02: View permissions (long format)
  ```bash
  sudo ls -l /var/www/
  ```
- Module 02: View SELinux contexts
  ```bash
  sudo ls -lZ /var/www/
  ```

**Slide Points:**
- Basic file listing and inspection tool
- **Key flags:**
  - `-l` = long format (shows permissions, owner, size, date)
  - `-Z` = show SELinux security contexts
  - `-a` = include hidden files (not used in this lab)
- **Long format columns:**
  ```
  drwxr-xr-x. 2 root root  24 Dec 10 00:00 html
  │           │ │    │     │  │             │
  │           │ │    │     │  │             └─ filename
  │           │ │    │     │  └─ timestamp
  │           │ │    │     └─ size
  │           │ │    └─ group owner
  │           │ └─ user owner
  │           └─ link count
  └─ permissions (d=directory, rwx=read/write/execute)
  ```
- **With -Z flag, adds SELinux context column:**
  ```
  drwxr-xr-x. 2 1002 1002 system_u:object_r:default_t:s0 24 Dec 10 html
                          └─── SELinux context ──────┘
  ```

---

### 3. **cat** - Display File Contents
**Purpose:** View web site content to verify restoration

**Usage in Lab:**
- Module 02: Check index.html content
  ```bash
  sudo cat /var/www/html/index.html
  ```

**Slide Points:**
- Displays entire file contents
- Used to verify:
  - File actually contains expected web page
  - Not corrupted during backup/restore
  - Content matches what should be served
- Simple verification tool
- For large files, use `less` instead

---

### 4. **ps** - Process Status
**Purpose:** Identify which user httpd processes run as

**Usage in Lab:**
- Module 02: Show httpd processes and their owners
  ```bash
  ps aux | grep [h]ttpd
  ```

**Slide Points:**
- Shows running processes and details
- `aux` = all users, user-oriented, include non-TTY processes
- **grep [h]ttpd trick:**
  - The brackets prevent grep from matching itself
  - Shows only actual httpd processes
  - Alternative: `ps aux | grep httpd | grep -v grep`
- **Key insight:** httpd has two user contexts
  - Main process runs as `root`
  - Worker processes run as `apache` user
  - Worker processes need file access (they serve content)
- Helps understand permission requirements

---

### 5. **chown** - Change File Ownership
**Purpose:** Fix incorrect file ownership from backup restore

**Usage in Lab:**
- Module 03: Correct ownership of web root
  ```bash
  sudo chown -R root:root /var/www/html
  ```

**Slide Points:**
- Changes user and/or group ownership
- **Syntax:** `chown user:group file`
- `-R` = recursive (apply to directory and all contents)
- **Why root:root?**
  - Default for /var/www/html
  - Works because apache user can read world-readable files
  - Could also use `apache:apache` but not standard
- **Problem in lab:** Backup restored as UID 1002
  - User doesn't exist on new system
  - httpd apache user can't access files
- **Common backup/restore issue:**
  - tar/rsync preserve numeric UIDs
  - UIDs may differ on different systems
  - Always verify/fix ownership after restore

---

### 6. **restorecon** - Restore SELinux Contexts
**Purpose:** Fix SELinux file contexts to correct labels

**Usage in Lab:**
- Module 03: Restore correct SELinux contexts
  ```bash
  sudo restorecon -Rv /var/www/html
  ```

**Slide Points:**
- Resets SELinux contexts to policy defaults
- **Flags:**
  - `-R` = recursive
  - `-v` = verbose (show what's being changed)
- **How it works:**
  - Reads SELinux policy rules
  - Applies correct context based on file location
  - Files in /var/www/html → httpd_sys_content_t
- **When to use:**
  - After copying/moving files
  - After restore from backup
  - After creating new files in service directories
  - When SELinux is denying access (check audit logs first)
- **Alternative:** `chcon` (manual context change)
  - `restorecon` is safer - uses policy rules
  - `chcon` requires knowing correct context

---

## SELinux Concepts

### What is SELinux?
- **Security-Enhanced Linux**
- **Mandatory Access Control (MAC)** layer
- Operates in addition to standard permissions (DAC)
- **Both layers must allow access:**
  - File permissions (chmod/chown) = DAC
  - SELinux contexts = MAC
- Default in RHEL - should NOT be disabled

### SELinux Context Format
```
system_u:object_r:httpd_sys_content_t:s0
└──┬───┘ └──┬───┘ └────────┬──────────┘└┬┘
   │        │               │            │
   user     role         type          level
```

**In practice, focus on the TYPE (third field):**
- `httpd_sys_content_t` = web content (correct for /var/www/html)
- `default_t` = default/unlabeled (incorrect - causes denials)
- Type enforces which processes can access which files

### Common Web Server Contexts
| Location | Correct Type | Purpose |
|----------|--------------|---------|
| /var/www/html | httpd_sys_content_t | Static content |
| /var/www/cgi-bin | httpd_sys_script_exec_t | CGI scripts |
| /var/www/html (writable) | httpd_sys_rw_content_t | Writable content (uploads) |

---

## Troubleshooting Flow

### Problem Statement
- Web server showing default page instead of actual web site
- Site was restored from backup after hardware failure

### Discovery Phase - Configuration
1. **grep DocumentRoot** → Find where httpd expects content
   - Result: `/var/www/html`
   
### Discovery Phase - Files
2. **ls /var/www/html** → Verify files exist
   - Result: `index.html` present
3. **cat /var/www/html/index.html** → Verify content
   - Result: Contains expected HTML

### Discovery Phase - Processes
4. **ps aux | grep httpd** → Understand process ownership
   - Main process: root
   - Workers: apache user
   - Workers need file access

### Discovery Phase - Permissions (DAC)
5. **ls -l /var/www/** → Check file ownership
   - Expected: `root:root`
   - Actual: `1002:1002` ← **PROBLEM #1**
   - UID 1002 doesn't exist on this system
   - apache user can't access these files

### Discovery Phase - Permissions (MAC)
6. **ls -lZ /var/www/** → Check SELinux contexts
   - Expected: `httpd_sys_content_t`
   - Actual: `default_t` ← **PROBLEM #2**
   - httpd process can't access files with default_t

### Resolution Phase
7. **chown -R root:root /var/www/html** → Fix ownership
8. **restorecon -Rv /var/www/html** → Fix SELinux contexts
9. **Verify** → Check website in browser (should work now)

---

## Key Teaching Points

### Two-Layer Security Model
```
Access Request
     ↓
┌─────────────────────┐
│ DAC (File Perms)    │ ← chown, chmod
│ user:group rwxrwxrwx│
└─────────────────────┘
     ↓ (if allowed)
┌─────────────────────┐
│ MAC (SELinux)       │ ← restorecon, chcon
│ type enforcement    │
└─────────────────────┘
     ↓ (if allowed)
  Access Granted
```

**Both must allow access!**

### Backup/Restore Gotchas
- **Permissions:**
  - tar/rsync preserve numeric UIDs/GIDs
  - User "bob" (UID 1000) on system A
  - May be "alice" (UID 1000) on system B
  - Files restore as UID 1000 (alice) not bob!
  - **Solution:** Restore, then fix ownership

- **SELinux Contexts:**
  - Usually NOT preserved in backups (depends on method)
  - tar without `--selinux` flag loses contexts
  - Restored files get `default_t` context
  - **Solution:** Run restorecon after restore

### Best Practice: Post-Restore Checklist
1. Verify files present and intact (ls, cat)
2. Check and fix ownership (ls -l, chown)
3. Check and fix SELinux contexts (ls -lZ, restorecon)
4. Test service functionality
5. Check logs for errors

### Why Not Just Disable SELinux?
- **Security in depth** - catches mistakes
- **Limits breach impact** - even if attacker gets in
- **Required for compliance** in many environments
- **Easy to fix** once you know the tools
- **setenforce 0** is temporary debugging only

### httpd User vs Root
- **Main process (root):**
  - Binds to port 80 (privileged port)
  - Spawns worker processes
  - Reads configuration
  
- **Worker processes (apache user):**
  - Handle HTTP requests
  - Read web content files
  - Need access to DocumentRoot
  
**Implication:** Files need to be readable by apache user or world-readable

---

## Slide Deck Suggestions

### Slide 1: The Problem
- Web server restored from backup
- Shows Apache default page, not actual website
- "It worked!" ≠ our business site

### Slide 2: Investigation - Configuration
```bash
grep '^DocumentRoot' /etc/httpd/conf/httpd.conf
  → DocumentRoot "/var/www/html"
```
httpd knows where to look ✓

### Slide 3: Investigation - Files
```bash
ls /var/www/html
  → index.html ✓

cat /var/www/html/index.html
  → <html>... Super Business site... ✓
```
Files are there, content is correct ✓

### Slide 4: Investigation - Process Ownership
```bash
ps aux | grep [h]ttpd
  root   15388  ... /usr/sbin/httpd
  apache 15389  ... /usr/sbin/httpd
  apache 15390  ... /usr/sbin/httpd
```
Workers run as `apache` user - they need file access

### Slide 5: Investigation - File Ownership
```bash
ls -l /var/www/
  drwxr-xr-x. 2 root root    cgi-bin
  drwxr-xr-x. 2 1002 1002    html  ← PROBLEM!
```
**UID 1002?** User doesn't exist!
apache user can't access files

### Slide 6: Investigation - SELinux Contexts
```bash
ls -lZ /var/www/
  system_u:object_r:httpd_sys_script_exec_t  cgi-bin ✓
  system_u:object_r:default_t                html    ✗
```
**default_t?** Wrong context!
httpd needs httpd_sys_content_t

### Slide 7: Root Cause Analysis
**Two problems found:**

1. **DAC (File Permissions):**
   - Owner: 1002:1002 (non-existent user)
   - Should be: root:root

2. **MAC (SELinux):**
   - Context: default_t
   - Should be: httpd_sys_content_t

**Backup restore didn't preserve proper security attributes**

### Slide 8: The Fix - Ownership
```bash
sudo chown -R root:root /var/www/html

ls -l /var/www/
  drwxr-xr-x. 2 root root    html  ✓
```
First layer fixed!

### Slide 9: The Fix - SELinux
```bash
sudo restorecon -Rv /var/www/html
  Relabeled /var/www/html from default_t to httpd_sys_content_t

ls -lZ /var/www/
  system_u:object_r:httpd_sys_content_t  html  ✓
```
Second layer fixed!

### Slide 10: Verification
- Reload website in browser
- Super Business site appears! ✓
- **Both security layers now allow access**

### Slide 11: Tool Summary
| Tool | Purpose | Key Usage |
|------|---------|-----------|
| grep | Search config | Find DocumentRoot |
| ls | List files | Check existence |
| ls -l | Check perms | Identify ownership issues |
| ls -lZ | Check SELinux | Identify context issues |
| cat | View content | Verify file contents |
| ps | Check processes | Understand user context |
| chown | Fix ownership | Restore proper owner:group |
| restorecon | Fix SELinux | Apply policy contexts |

### Slide 12: Best Practices
✓ Methodical investigation before making changes
✓ Check both DAC and MAC layers
✓ Understand process user context
✓ Post-restore security audit
✓ Keep SELinux enabled
✓ Use restorecon, not chcon
✓ Document backup/restore procedures

### Slide 13: Common Scenarios
**When to check ownership & SELinux:**
- After backup/restore operations
- After copying files between systems
- After manual file creation in service directories
- Service fails with "permission denied" errors
- Service works as root, fails as normal user
- Web server shows permission errors in logs

---

## Demo Script Notes

1. Show broken website (Apache default page)
2. grep DocumentRoot - show configuration is correct
3. ls /var/www/html - files exist
4. cat index.html - content is correct
5. "So what's wrong?"
6. ps aux | grep httpd - show apache workers
7. ls -l /var/www/ - AHA! UID 1002
8. Explain: backup preserved numeric UID, but user doesn't exist here
9. ls -lZ /var/www/ - ALSO wrong SELinux context
10. Explain: two-layer security model
11. chown -R root:root /var/www/html
12. ls -l - show it's fixed
13. restorecon -Rv /var/www/html
14. ls -lZ - show context fixed
15. Refresh browser - site works!
16. Emphasize: BOTH layers had to be fixed
17. Lesson: always audit security after restore
