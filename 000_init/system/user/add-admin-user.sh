#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Prompt for username
read -p "Enter the username for the new admin user: " username

# Prompt for password
read -s -p "Enter the password for the new admin user: " password
echo

# Create the user
useradd -m -s /bin/bash "$username"

# Set the password for the user
echo "$username:$password" | chpasswd

# Add the user to the sudo group
usermod -aG sudo "$username"

echo "User '$username' has been created and added to the sudo group."

# Optional: Set up SSH key for the user (uncomment and customize as needed)
# mkdir -p /home/$username/.ssh
# cp /your/local/public_key.pub /home/$username/.ssh/authorized_keys
# chown -R $username:$username /home/$username/.ssh
# chmod 700 /home/$username/.ssh
# chmod 600 /home/$username/.ssh/authorized_keys

echo "Setup complete for user '$username'."
