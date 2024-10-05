#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Prompt for username
read -p "Enter the username for the new user: " username

# Check if the user exists
if id "$username" &>/dev/null; then
    # Remove the user, home directory, and mailbox
    sudo userdel -r "$username"
    echo "User '$username' has been removed."
else
    echo "User '$username' does not exist."
fi
