#!/bin/bash

# Set certificate directory for local user
CERT_DIR="$HOME/.local/share/ca-certificates"

# Prompt for the certificate name
read -p "Enter the certificate name (without .crt extension) to remove: " cert_name

# Check if the certificate exists
if [ -f "$CERT_DIR/$cert_name.crt" ]; then
    # Remove the certificate file
    echo "Removing the certificate $cert_name.crt..."
    rm "$CERT_DIR/$cert_name.crt"

    # Update the certificate store
    echo "Updating the certificate store..."
    sudo update-ca-certificates --fresh

    echo "Certificate $cert_name removed and the certificate store updated."
else
    echo "Error: Certificate $cert_name.crt not found in $CERT_DIR."
fi
