#!/bin/bash

# Configuration Variables
CERT_DIR="$HOME/self-signed-certs"
DAYS_VALID=365 # Default validity period

# --- Function to prompt for SAN details and generate the config file ---
# Arguments:
#   $1: cert_name (The name of the certificate, e.g., 'mobi')
#   $2: cert_dir (The base directory for certificate files)
#   $3: dn_subject (The Distinguished Name subject string generated earlier)
# Returns: The path to the generated config file.
function generate_san_config() {
    local cert_name="$1"
    local CERT_DIR="$2"
    local DN_SUBJECT="$3"
    local SAN_LIST=""
    local DNS_ENTRIES=""
    local IP_ENTRIES=""
    # CONFIG_FILE uses the cert_name for a unique filename
    local CONFIG_FILE="$CERT_DIR/$cert_name.cnf"

    echo "---"
    echo "📜 SAN Configuration Generator for '$cert_name'"
    echo "This script will create the OpenSSL configuration file only."

    # --- 1. Get Domain Names (DNS entries) ---
    echo "---"
    echo "1. Enter Domain/Hostnames (e.g., mobi.localhost.com, myapp.local):"
    echo "   (Leave blank to finish entering domains)"
    while true; do
        read -r -p "   > DNS Entry: " domain_input
        if [ -z "$domain_input" ]; then
            break
        fi

        # Auto-correction for the common error of missing the 'DNS:' prefix
        if [[ ! "$domain_input" =~ ^(DNS|dns|IP|ip|URI|uri): ]]; then
            DNS_ENTRIES+="DNS:$domain_input,"
            echo "     * Added: DNS:$domain_input (Auto-corrected)"
        else
            DNS_ENTRIES+="${domain_input},"
            echo "     * Added: $domain_input"
        fi
    done

    # --- 2. Get IP Addresses (IP entries) ---
    echo "---"
    echo "2. Enter IP Addresses (e.g., 127.0.0.1, 192.168.1.10):"
    echo "   (Leave blank to finish entering IPs)"
    while true; do
        read -r -p "   > IP Entry: " ip_input
        if [ -z "$ip_input" ]; then
            break
        fi

        # Ensure 'IP:' prefix is used
        if [[ ! "$ip_input" =~ ^(IP|ip): ]]; then
            IP_ENTRIES+="IP:$ip_input,"
            echo "     * Added: IP:$ip_input (Auto-corrected)"
        else
            IP_ENTRIES+="${ip_input},"
            echo "     * Added: $ip_input"
        fi
    done

    # Combine and trim the trailing comma
    SAN_LIST=$(echo "$DNS_ENTRIES$IP_ENTRIES" | sed 's/,$//')

    if [ -z "$SAN_LIST" ]; then
        echo "---"
        echo "❌ WARNING: No SAN values were provided. Defaulting to 'DNS:localhost'."
        SAN_LIST="DNS:localhost"
    fi

    echo "---"
    echo "✅ Final Subject Alternative Name (SAN) List: **$SAN_LIST**"
    echo "---"

    # --- 3. Create the openssl configuration file with the commented command ---

    cat > "$CONFIG_FILE" <<EOF
# ----------------------------------------------------------------------
# OPENSSL CONFIGURATION FILE: $cert_name.cnf
#
# Use the following command to generate the key and self-signed certificate:
# openssl req -x509 -nodes -days $DAYS_VALID -newkey rsa:2048 \
#     -keyout "$CERT_DIR/$cert_name.key" -out "$CERT_DIR/$cert_name.crt" \
#     -config "$CONFIG_FILE" -sha256
# ----------------------------------------------------------------------

[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
# Distinguished Name Fields (Owner Details)
$DN_SUBJECT

# SAN Extensions
[req_ext]
subjectAltName = $SAN_LIST

[v3_ca]
subjectAltName = $SAN_LIST
EOF

    echo "Configuration file **$CONFIG_FILE** created successfully."
    echo "The certificate's Common Name (CN) is set to: **$cert_name**"
    echo "$CONFIG_FILE" # Return the config file path for verification
}


# --- MAIN SCRIPT EXECUTION ---

# Create the certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"
echo "Certificate directory: $CERT_DIR"

# Prompt for the certificate name (CN) with new default
read -p "Enter the desired Common Name (CN) for the certificate (default: self-cert): " cert_name
# Set the default if input is empty
CERT_NAME=${cert_name:-self-cert}

echo "---"
echo "➡️ Please provide the organization details for the certificate owner (press Enter for defaults):"

# Prompt for Distinguished Name (DN) Fields with new defaults
read -r -p "Country Name (C) [IN]: " c_input
C_NAME=${c_input:-IN}

read -r -p "State or Province Name (ST) [Tamil Nadu]: " st_input
ST_NAME=${st_input:-Tamil Nadu}

read -r -p "Locality Name (L) [Salem]: " l_input
L_NAME=${l_input:-Salem}

read -r -p "Organization Name (O) [Ravi Jaganathan]: " o_input
O_NAME=${o_input:-Ravi Jaganathan}

read -r -p "Organizational Unit Name (OU) [Self]: " ou_input
OU_NAME=${ou_input:-Self}

# Build the DN subject string for the config file
DN_SUBJECT="C = $C_NAME
ST = $ST_NAME
L = $L_NAME
O = $O_NAME
OU = $OU_NAME
CN = $CERT_NAME" # Use the potentially defaulted name

# Generate the SAN configuration file
CONFIG_FILE=$(generate_san_config "$CERT_NAME" "$CERT_DIR" "$DN_SUBJECT")

echo "---"
echo "Task complete. The configuration file is ready."
echo "File location: **$CONFIG_FILE**"
echo "You can view the contents or run the commented command inside the file to proceed."