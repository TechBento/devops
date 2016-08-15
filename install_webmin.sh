#!/bin/bash
# As-Is, no warranty. Use at your own risk.  Works only on Linux RedHat/CentOS.
# ----------------------------------
# $Id:$ 
# ----------------------------------
echo "================================================================="
echo "Install WebMin management GUI for administering the server."
sudo mkdir -P /usr/shared/techbento
sudo chmod 777 /usr/shared/techbento
wget -N  http://prdownloads.sourceforge.net/webadmin/webmin-1.801-1.noarch.rpm -P /usr/shared/techbento
sudo yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
sudo rpm -U /home/ec2-user/webmin-1.801-1.noarch.rpm
echo "Please specify WebMin root password:"
read varWebMinPassword
/usr/libexec/webmin/changepass.pl /etc/webmin root $varWebMinPassword
echo "Done. Be sure to update the console." 