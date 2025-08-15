#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Update package list
apt update

# Install OpenJDK 17
apt install -y openjdk-17-jre

echo "Java Runtime Environment 17 installation completed."
