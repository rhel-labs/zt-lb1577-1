#!/bin/sh
echo "Starting module called module-01" >> /tmp/progress.log
dnf -y remove gitweb 
