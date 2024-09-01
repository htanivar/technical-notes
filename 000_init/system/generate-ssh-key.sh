#!/bin/bash

# Default email
DEFAULT_EMAIL="raviregi@gmail.com"

# Function to generate SSH key
generate_ssh_key() {
    local key_name="$1"
    local email="$2"
    ssh-keygen -t rsa -b 4096 -C "$email" -f "$HOME/.ssh/$key_name"
}

# Default key name
KEY_NAME="id_rsa"

# Check if the default key file exists
if [ -f "$HOME/.ssh/$KEY_NAME" ]; then
    echo "The file $HOME/.ssh/$KEY_NAME already exists."
    read -p "Please enter a new name for the SSH key (without path): " NEW_KEY_NAME
    KEY_NAME="$NEW_KEY_NAME"
fi

# Ask if the user wants to update the email
read -p "The default email is $DEFAULT_EMAIL. Would you like to update it? (y/n): " update_email

if [[ "$update_email" == "y" || "$update_email" == "Y" ]]; then
    read -p "Please enter your email: " user_email
    DEFAULT_EMAIL="$user_email"
fi

# Generate the SSH key
generate_ssh_key "$KEY_NAME" "$DEFAULT_EMAIL"

# The content to be added to .bashrc
BASHRC_CONTENT="
# Start the SSH agent and add the SSH key
if [ -z \"\$SSH_AUTH_SOCK\" ]; then
    eval \"\$(ssh-agent -s)\"
    ssh-add $HOME/.ssh/$KEY_NAME
fi
"

# Check if the content is already in .bashrc
if ! grep -q "ssh-add $HOME/.ssh/$KEY_NAME" "$HOME/.bashrc"; then
    # Append the content to .bashrc
    echo "$BASHRC_CONTENT" >> "$HOME/.bashrc"
    echo "SSH identity has been added to .bashrc."
else
    echo "SSH identity is already present in .bashrc."
fi

# Source the .bashrc to apply changes
source "$HOME/.bashrc"

echo "Done. Please restart your terminal session or run 'source ~/.bashrc' to apply changes."
