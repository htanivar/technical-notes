#!/bin/bash

# Default values
DEFAULT_NAME="Ravi J"
DEFAULT_EMAIL="raviregi@gmail.com"

echo "Current default Git config:"
echo "  Name : $DEFAULT_NAME"
echo "  Email: $DEFAULT_EMAIL"
read -p "Do you want to use these values? (y/n): " use_defaults

if [[ "$use_defaults" == "y" || "$use_defaults" == "Y" ]]; then
    GIT_NAME="$DEFAULT_NAME"
    GIT_EMAIL="$DEFAULT_EMAIL"
else
    read -p "Enter your Git username: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL
fi

# Apply Git config
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Confirm
echo -e "\n✅ Git config set successfully:"
git config --global --list
