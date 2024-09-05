#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Update package list
apt update

# Install Apache
apt install -y apache2

# Install MySQL server
apt install -y mysql-server

# Secure MySQL installation
mysql_secure_installation

# Install PHP and required modules
apt install -y php libapache2-mod-php php-mysql
apt install php-xml
# Restart Apache to apply changes
systemctl restart apache2

echo "LAMP server installation completed."
#https://www.digitalocean.com/community/tutorials/how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-22-04
