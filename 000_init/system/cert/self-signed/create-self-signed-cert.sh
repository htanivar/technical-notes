#!/bin/bash

# Configuration Variables (Defaults, potentially overridden by config file location)
DAYS_VALID=365
# Default installation path for system CAs
LOCAL_CERT_STORE="$HOME/.local/share/ca-certificates"

# --- Function to extract certificate name from config path ---
# Assumes the filename without extension is the cert name (e.g., /path/to/mobi.cnf -> mobi)
function get_cert_name_from_config() {
    local config_path="$1"
    # Get the basename (e.g., mobi.cnf)
    local filename=$(basename "$config_path")
    # Remove the extension (.cnf)
    echo "${filename%.*}"
}


# --- MAIN SCRIPT EXECUTION ---

# 1. Check for Config File Argument ($1)
CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
    echo "======================================================================"
    echo "❌ ERROR: Configuration file not provided."
    echo ""
    echo "USAGE: ./create-self-signed-cert.sh <path/to/config.cnf>"
    echo ""
    echo "ACTION REQUIRED:"
    echo "1. Generate your configuration file first."
    echo "   We recommend using your **san-generation.sh** script:"
    echo "   **./san-generation.sh**"
    echo "2. Pass the resulting .cnf file path to this script."
    echo "   Example: **./create-self-signed-cert.sh $HOME/self-signed-certs/mobi.cnf**"
    echo "======================================================================"
    exit 1
fi

# 2. Validate Config File
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found at path: $CONFIG_FILE"
    exit 1
fi

# 3. Determine Certificate Name and Directory
CERT_NAME=$(get_cert_name_from_config "$CONFIG_FILE")
# Use the directory of the config file as the working directory for output
CERT_DIR=$(dirname "$CONFIG_FILE")

echo "---"
echo "✅ Configuration found for certificate: **$CERT_NAME**"
echo "   - Config File: **$CONFIG_FILE**"
echo "   - Key Output:  **$CERT_DIR/$CERT_NAME.key**"
echo "   - Cert Output: **$CERT_DIR/$CERT_NAME.crt**"
echo "---"

# Create the certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# 4. Generate a private key
echo "🔑 Generating private key for $CERT_NAME..."
KEY_FILE="$CERT_DIR/$CERT_NAME.key"

# Check if key already exists to avoid accidental overwriting
if [ -f "$KEY_FILE" ]; then
    read -r -p "⚠️ Private key already exists at $KEY_FILE. Overwrite? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Skipping key generation. Using existing key."
    else
        openssl genpkey -algorithm RSA -out "$KEY_FILE" -pkeyopt rsa_keygen_bits:2048
    fi
else
    openssl genpkey -algorithm RSA -out "$KEY_FILE" -pkeyopt rsa_keygen_bits:2048
fi


# 5. Generate the self-signed certificate with SAN
CERT_FILE="$CERT_DIR/$CERT_NAME.crt"
echo "📜 Generating self-signed certificate for $CERT_NAME (Valid for $DAYS_VALID days)..."
# Adding -sha256 for a more modern digest algorithm
openssl req -x509 -nodes -days $DAYS_VALID -key "$KEY_FILE" -out "$CERT_FILE" -config "$CONFIG_FILE" -sha256

# 6. Check for success
if [ ! -f "$CERT_FILE" ]; then
  echo "❌ Error: Failed to generate the certificate."
  echo "   - **Issue**: Review the contents of **$CONFIG_FILE** for syntax errors."
  exit 1
fi

# 7. Install the certificate locally for the user
echo "✅ Certificate generated successfully."
echo "📦 Installing the certificate for the local user in $LOCAL_CERT_STORE..."
mkdir -p "$LOCAL_CERT_STORE"
cp "$CERT_FILE" "$LOCAL_CERT_STORE/"

# Update the local certificate store (OS specific)
echo "🔄 Updating the local certificate store..."
if command -v update-ca-certificates &> /dev/null
then
    update-ca-certificates --fresh --local
else
    echo "Note: 'update-ca-certificates' not found. You may need to manually install the certificate in your OS/browser."
fi

echo "---"
echo "🎉 Self-signed certificate **$CERT_NAME** created and installed successfully."
echo "   - **Key File**:    $KEY_FILE"
echo "   - **Cert File**:   $CERT_FILE"
echo "   - **Installed At**: $LOCAL_CERT_STORE/$CERT_NAME.crt"
echo "---"