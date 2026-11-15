#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi


# Set the desired hostname and domain name
# Variables
read -p "Enter the new hostname: " HOSTNAME
read -p "Enter the Domain name: " DOMAIN


# Update the hostname
sudo hostnamectl set-hostname $HOSTNAME

# Update /etc/hosts
sudo sed -i "s/127.0.0.1.*$/127.0.0.1 $HOSTNAME $HOSTNAME.$DOMAIN localhost/" /etc/hosts

# Update /etc/cloud/cloud.cfg for cloud instances
sudo sed -i 's/^preserve_hostname:.*$/preserve_hostname: true/' /etc/cloud/cloud.cfg

# Update /etc/hostname
echo $HOSTNAME | sudo tee /etc/hostname

# Update /etc/resolv.conf with the domain name
echo "search $DOMAIN" | sudo tee -a /etc/resolv.conf

# Reboot the system
sudo reboot
