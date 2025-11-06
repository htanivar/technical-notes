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
# The SAN must be in a format like 'DNS:myhost.com' or 'IP:192.168.1.1' or combined.
echo "---"
echo "ℹ️ Subject Alternative Name (SAN) Format Guide:"
echo "   - Single Domain:   DNS:mobi.localhost.com"
echo "   - Single IP:       IP:127.0.0.1"
echo "   - Multiple:        DNS:localhost,DNS:mobi.local,IP:127.0.0.1"
echo "   - Your previous failure was because you provided 'mobi.localhost.com' instead of 'DNS:mobi.localhost.com'."
echo "---"
read -p "Enter the Subject Alternative Name (SAN) in the required format (e.g., DNS:localhost,IP:127.0.0.1): " san

# Ensure SAN is provided
if [ -z "$san" ]; then
  echo "Error: SAN must be provided."
  exit 1
fi

# --- FIX IMPLEMENTATION: Automatically prepend 'DNS:' if it's missing and doesn't look like a complex SAN ---
# This is a common point of failure and makes the script more user-friendly.
# Check if the SAN string contains 'DNS:' or 'IP:' (case-insensitive for robustness)
if [[ ! "$san" =~ (DNS|IP|URI): ]]; then
    # If no recognized prefix is found, assume it's a simple hostname and prepend 'DNS:'
    echo "⚠️ SAN value **'$san'** doesn't contain a prefix like 'DNS:' or 'IP:'. Automatically prepending 'DNS:'."
    san="DNS:$san"
fi
# ---------------------------------------------------------------------------------------------------------

echo "Using final SAN value: **$san**"
echo "---"

# Generate a private key
echo "🔑 Generating private key for $cert_name..."
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
# CN (Common Name) is required, but SAN is what browsers trust
CN = localhost

[req_ext]
subjectAltName = $san

[v3_ca]
subjectAltName = $san
EOF

# Generate the self-signed certificate with SAN
echo "📜 Generating self-signed certificate for $cert_name (Valid for $DAYS_VALID days)..."
# Adding -sha256 for a more modern digest algorithm
openssl req -x509 -nodes -days $DAYS_VALID -key "$CERT_DIR/$cert_name.key" -out "$CERT_DIR/$cert_name.crt" -config "$CONFIG_FILE" -sha256

# Check if the certificate was generated successfully
if [ ! -f "$CERT_DIR/$cert_name.crt" ]; then
  # This specific error message is better for the user
  echo "❌ Error: Failed to generate the certificate."
  echo "   - **Common Issue**: Check that the SAN is in the correct format (e.g., DNS:myhost.com, IP:127.0.0.1)."
  echo "   - **Attempted SAN**: $san"
  exit 1
fi

# Install the certificate locally for the user
echo "✅ Certificate generated successfully."
echo "📦 Installing the certificate for the local user in $LOCAL_CERT_STORE..."
mkdir -p "$LOCAL_CERT_STORE"
cp "$CERT_DIR/$cert_name.crt" "$LOCAL_CERT_STORE/"

# Update the local certificate store
echo "🔄 Updating the local certificate store (requires root permissions on some systems)..."
update-ca-certificates --fresh --local

echo "---"
echo "🎉 Self-signed certificate **$cert_name** created and installed successfully."
echo "   - **Key File**:    $CERT_DIR/$cert_name.key"
echo "   - **Cert File**:   $CERT_DIR/$cert_name.crt"
echo "   - **Installed At**: $LOCAL_CERT_STORE/$cert_name.crt"
echo "---"