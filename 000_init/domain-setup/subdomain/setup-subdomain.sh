#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi


# Variables
read -p "Enter the new domain: " DOMAIN
read -p "Enter the sub domain node: " NODE

SUBDOMAIN="$NODE.$DOMAIN"
DOCUMENT_ROOT="/var/www/$DOMAIN/subdomain/$SUBDOMAIN"

# Create Document Root
sudo mkdir -p ${DOCUMENT_ROOT}

echo "<html><head><title>Welcome to ${SUBDOMAIN}</title></head><body><h1>Hello from ${SUBDOMAIN}!!!</h1></body></html>" > ${DOCUMENT_ROOT}/index.html

# Install Apache if not already installed
#sudo apt update

# Create Apache virtual host configuration
sudo bash -c "cat > /etc/apache2/sites-available/${SUBDOMAIN}.conf" <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@${DOMAIN}
    ServerName ${SUBDOMAIN}
    DocumentRoot ${DOCUMENT_ROOT}

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the virtual host
sudo a2ensite ${SUBDOMAIN}.conf

# Reload Apache to apply the changes
sudo systemctl reload apache2

# Set permissions (adjust as needed)
sudo chown -R www-data:www-data ${DOCUMENT_ROOT}
sudo chmod -R 755 ${DOCUMENT_ROOT}

# Display success message
echo "Subdomain ${SUBDOMAIN} has been set up in Apache2."
