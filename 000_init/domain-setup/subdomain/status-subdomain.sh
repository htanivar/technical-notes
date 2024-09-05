#!/bin/bash


# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo $0'."
    exit 1
fi

# Website domain to be removed
read -p "Enter the domain name: " DOMAIN
read -p "Enter the sub domain node: " NODE
SUB_DOMAIN="$NODE.$DOMAIN"
DOCUMENT_ROOT="/var/www/$DOMAIN/subdomain/$SUB_DOMAIN"

# Check if the virtual host configuration file exists
ls "/etc/apache2/sites-available"

cat "/etc/apache2/sites-available/${SUB_DOMAIN}.conf"

ls "/var/www/$DOCUMENT_ROOT"/html

cat "/var/www/$DOCUMENT_ROOT/html/index.html"
