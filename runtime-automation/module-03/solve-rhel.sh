#!/bin/sh
restorecon -vFR /var/www/
chown -R root:root /var/www/html
echo "Solved module called module-03" >> /tmp/progress.log
