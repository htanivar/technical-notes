#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi


# Variables
# Prompt for username
read -p "Enter the new domain: " DOMAIN
DOCUMENT_ROOT="/var/www/$DOMAIN/html"

# Create Document Root
sudo mkdir -p ${DOCUMENT_ROOT}

# Install Apache if not already installed
#sudo apt update

echo "<html><head><title>Welcome to ${DOMAIN}</title></head><body><h1>Hello from ${DOMAIN}!!!</h1></body></html>" > ${DOCUMENT_ROOT}/index.html

# Create Apache virtual host configuration
sudo bash -c "cat > /etc/apache2/sites-available/${DOMAIN}.conf" <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@${DOMAIN}
    ServerName ${DOMAIN}
    DocumentRoot ${DOCUMENT_ROOT}

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the virtual host
sudo a2ensite ${DOMAIN}.conf

# Reload Apache to apply the changes
sudo systemctl reload apache2

# Set permissions (adjust as needed)
sudo chown -R www-data:www-data ${DOCUMENT_ROOT}
sudo chmod -R 755 ${DOCUMENT_ROOT}

# Backup the original hosts file
cp /etc/hosts /etc/hosts.bak

# Add or update the entry in the hosts file
if grep -q "$DOMAIN" /etc/hosts; then
    sed -i "s/\(.*\)$DOMAIN/\1$DOMAIN/" /etc/hosts
else
    echo "127.0.0.1   $DOMAIN" >> /etc/hosts
fi

echo "Hosts file updated with the new domain: $DOMAIN"


# Display success message
echo "Domain ${DOMAIN} has been set up in Apache2."
