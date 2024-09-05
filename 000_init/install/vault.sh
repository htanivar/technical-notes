#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Define the environment variable name
env_var_name="VAULT_VERSION"

# Check if the environment variable is set and not empty
if [ -z "${!env_var_name}" ]; then
  # Prompt the user to enter the value for the environment variable
  read -p "Enter the value for $env_var_name: " env_var_value

  # Check if the user entered a value
  if [ -z "$env_var_value" ]; then
    export env_var_name="1.15.1"
  else
    export $env_var_name="$env_var_value"
  fi
else
  env_var_value="${!env_var_name}"
fi

# Display the environment variable value
echo "$env_var_name is set to: $env_var_value"

# Variables
VAULT_VERSION="1.15.1"
DOWNLOAD_URL="https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
INSTALL_DIR="/opt/vault"
VAULT_ZIP="$INSTALL_DIR/vault_${VAULT_VERSION}_linux_amd64.zip"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download Vault binary
echo "Downloading Vault version $VAULT_VERSION..."
curl -o "$VAULT_ZIP" "$DOWNLOAD_URL"

# Extract the binary
echo "Extracting Vault binary..."
unzip -d "$INSTALL_DIR" "$VAULT_ZIP"

# Clean up zip file
rm "$VAULT_ZIP"

# Make Vault binary executable
chmod +x "$INSTALL_DIR/vault"

## Add Vault to PATH
#echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.bashrc
#source ~/.bashrc

## Verify installation
#echo "Vault installation completed. Verifying..."
#vault version
#
#if [ $? -eq 0 ]; then
#    echo "Vault has been successfully installed and added to your PATH."
#else
#    echo "There was an issue installing Vault. Please check the output for errors."
#fi


echo "Vault installed successfully."
echo "**************************************************************************"
echo "update PATH in /etc/environment file with /opt/vault/"
echo "**************************************************************************"