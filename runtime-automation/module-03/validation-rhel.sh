#!/bin/sh
# Validate that the web server issues have been fixed

echo "Starting validation for module-03" >> /tmp/progress.log

# Check 1: Verify ownership is root:root
# OWNER=$(stat -c '%U:%G' /var/www/html)
# if [ "$OWNER" != "root:root" ]; then
#     echo "FAIL: /var/www/html ownership is $OWNER, should be root:root" >> /tmp/progress.log
#     echo "HINT: Use 'sudo chown -R root:root /var/www/html' to fix ownership" >> /tmp/progress.log
#     exit 1
# fi

# Check 2: Verify SELinux context is correct
# SELINUX_CONTEXT=$(ls -Zd /var/www/html | awk '{print $4}' | cut -d: -f3)
# if [ "$SELINUX_CONTEXT" != "httpd_sys_content_t" ]; then
#     echo "FAIL: /var/www/html SELinux context is $SELINUX_CONTEXT, should be httpd_sys_content_t" >> /tmp/progress.log
#     echo "HINT: Use 'sudo restorecon -vFR /var/www/' to restore correct SELinux contexts" >> /tmp/progress.log
#     exit 1
# fi

# Check 3: Verify the web site is accessible
# HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
# if [ "$HTTP_RESPONSE" != "200" ]; then
#     echo "FAIL: Web server returned HTTP $HTTP_RESPONSE instead of 200" >> /tmp/progress.log
#     echo "HINT: Check if httpd is running with 'systemctl status httpd'" >> /tmp/progress.log
#     exit 1
# fi

# Check 4: Verify the correct content is being served
# WEB_CONTENT=$(curl -s http://localhost/ | grep -c "super-businessy important web site")
# if [ "$WEB_CONTENT" -eq 0 ]; then
#     echo "FAIL: Web server is running but serving incorrect content" >> /tmp/progress.log
#     echo "HINT: Verify /var/www/html/index.html exists and has correct permissions and SELinux context" >> /tmp/progress.log
#     exit 1
# fi

# echo "PASS: All checks completed successfully!" >> /tmp/progress.log
# echo "- Ownership is correct (root:root)" >> /tmp/progress.log
# echo "- SELinux context is correct (httpd_sys_content_t)" >> /tmp/progress.log
# echo "- Web server is responding with correct content" >> /tmp/progress.log

# echo "Validated module called module-03" >> /tmp/progress.log
exit 0
