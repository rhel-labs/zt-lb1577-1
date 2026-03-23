#!/bin/bash
USER=rhel

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup vm control01" > /tmp/progress.log

chmod 666 /tmp/progress.log 

#dnf install -y nc


# Lab specific setup beyond this point


touch /root/thisthingworked


mkdir -p /var/www/html
cat << EOF > /var/www/html/index.html
<html>
<head>
<title>Super Business</title>
</head>
<body>
<h1>This is our super-businessy important web site</h1>
All the business comes here.<br>
<br>
Without it, we have no business!<br>
<br>
</body>
</html>
EOF

systemctl enable --now httpd
chcon -t default_t -R /var/www/html
chown -R 1002:1002 /var/www/html
