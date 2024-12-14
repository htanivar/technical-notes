#!/bin/bash

# Website domain to be removed
read -p "Enter the domain that needs to be removed: " WEBSITE_DOMAIN

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo $0'."
    exit 1
fi


# Check if the virtual host configuration file exists
CONFIG_FILE="/etc/apache2/sites-available/${WEBSITE_DOMAIN}.conf"
if [ ! -e "$CONFIG_FILE" ]; then
    echo "Error: Virtual host configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Disable the site
a2dissite "$WEBSITE_DOMAIN"

# Reload Apache to apply the changes
systemctl reload apache2

# Optionally, you can delete the configuration file
# rm "$CONFIG_FILE"

rm $CONFIG_FILE
rm -rf /var/www/$WEBSITE_DOMAIN
echo "Website '$WEBSITE_DOMAIN' has been removed from Apache2."
