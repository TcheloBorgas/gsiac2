#!/bin/bash
    
echo "Update with latest packages"
yum update -y
    
echo "Install Apache"
yum install -y httpd git
    
echo "Enable Apache service to start after reboot"
systemctl enable httpd
    
echo "Install application"
cd /tmp
git clone https://github.com/TcheloBorgas/gsiac2.git
if [ ! -d "/var/www/html" ]; then
    mkdir /var/www/html
fi
cp /tmp/gs/app/*.html /var/www/html

echo "Start Apache service"
systemctl restart httpd
