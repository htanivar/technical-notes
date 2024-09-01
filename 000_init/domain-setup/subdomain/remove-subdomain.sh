#!/bin/bash

# Website domain to be removed
read -p "Enter the domain name: " DOMAIN
read -p "Enter the sub domain node: " NODE
SUB_DOMAIN="$NODE.$DOMAIN"
DOCUMENT_ROOT="/var/www/$DOMAIN/subdomain/$SUB_DOMAIN"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo $0'."
    exit 1
fi


# Check if the virtual host configuration file exists
CONFIG_FILE="/etc/apache2/sites-available/${SUB_DOMAIN}.conf"
if [ ! -e "$CONFIG_FILE" ]; then
    echo "Error: Virtual host configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Disable the site
a2dissite "$SUB_DOMAIN"

# Reload Apache to apply the changes
systemctl reload apache2

# Optionally, you can delete the configuration file
# rm "$CONFIG_FILE"

rm $CONFIG_FILE
rm -rf $DOCUMENT_ROOT

echo "Website '$SUB_DOMAIN' has been removed from Apache2."

echo "Verify: $DOCUMENT_ROOT is deleted"
echo "Verify: /etc/apache2/sites-available/${SUB_DOMAIN}.conf is deleted"
