#!/bin/bash

# Set default certificate directory for local user
CERT_DIR="$HOME/self-signed-certs"
LOCAL_CERT_STORE="$HOME/.local/share/ca-certificates"
DAYS_VALID=365

# Create the certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Prompt for the certificate name
read -p "Enter the certificate name (e.g., my-cert): " cert_name

# Prompt for the Subject Alternative Name (SAN)
read -p "Enter the Subject Alternative Name (SAN) in format (e.g., DNS:localhost,IP:127.0.0.1): " san

# Ensure SAN is provided
if [ -z "$san" ]; then
  echo "Error: SAN must be provided in the correct format."
  exit 1
fi

# Generate a private key
echo "Generating private key for $cert_name..."
openssl genpkey -algorithm RSA -out "$CERT_DIR/$cert_name.key" -pkeyopt rsa_keygen_bits:2048

# Create a configuration file with the SAN
CONFIG_FILE="$CERT_DIR/openssl-san.cnf"
cat > "$CONFIG_FILE" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
CN = localhost

[req_ext]
subjectAltName = $san

[v3_ca]
subjectAltName = $san
EOF

# Generate the self-signed certificate with SAN
echo "Generating self-signed certificate for $cert_name..."
openssl req -x509 -nodes -days $DAYS_VALID -key "$CERT_DIR/$cert_name.key" -out "$CERT_DIR/$cert_name.crt" -config "$CONFIG_FILE"

# Check if the certificate was generated successfully
if [ ! -f "$CERT_DIR/$cert_name.crt" ]; then
  echo "Error: Failed to generate the certificate. Please check the SAN format and try again."
  exit 1
fi

# Install the certificate locally for the user
echo "Installing the certificate for the local user in $LOCAL_CERT_STORE..."
mkdir -p "$LOCAL_CERT_STORE"
cp "$CERT_DIR/$cert_name.crt" "$LOCAL_CERT_STORE/"

# Update the local certificate store
echo "Updating the local certificate store..."
update-ca-certificates --fresh --local

echo "Self-signed certificate $cert_name created and installed successfully in $LOCAL_CERT_STORE."
