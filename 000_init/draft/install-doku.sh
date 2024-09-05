#!/bin/bash

# Update package lists
#sudo apt-get update

# Install dependencies
#sudo apt-get install -y apache2 php php-mbstring php-gd php-xml zip unzip

# Create DokuWiki directory
#sudo mkdir /var/www/subdomain/veda

# Download DokuWiki
#wget https://download.dokuwiki.org/stable/dokuwiki-latest.tgz

# Extract DokuWiki
tar -xvzf dokuwiki-latest.tgz -C /var/www/dokuwiki

# Set owner and permissions
sudo chown -R www-data:www-data /var/www/dokuwiki

# Enable mod_rewrite for Apache
sudo a2enmod rewrite

# Create an Apache virtual host configuration
sudo tee /etc/apache2/sites-available/dokuwiki.conf <<EOF
<VirtualHost *:80>
    ServerName dokuwiki.yourdomain.com
    DocumentRoot /var/www/dokuwiki
    <Directory /var/www/dokuwiki>
        Options FollowSymLinks Indexes MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable the virtual host and restart Apache
sudo a2ensite dokuwiki.conf
sudo systemctl restart apache2

# Access the DokuWiki installer through your web browser:
# http://dokuwiki.yourdomain.com/install.php
