#!/bin/sh
sudo grep '^DocumentRoot' /etc/httpd/conf/httpd.conf
sudo ls /var/www/html
sudo cat /var/www/html/index.html
ps aux | grep httpd
sudo ls -l /var/www/
sudo ls -lZ /var/www

echo "Solved module called module-02" >> /tmp/progress.log
