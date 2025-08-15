#!/bin/bash


# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo $0'."
    exit 1
fi

# Website domain to be removed
read -p "Enter the domain to fetch status: " WEBSITE_DOMAIN

# Check if the virtual host configuration file exists
ls "/etc/apache2/sites-available"

cat "/etc/apache2/sites-available/${WEBSITE_DOMAIN}.conf"

ls "/var/www/$WEBSITE_DOMAIN"/html

cat "/var/www/$WEBSITE_DOMAIN/html/index.html"
