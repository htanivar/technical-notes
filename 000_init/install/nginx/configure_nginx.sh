#!/bin/bash
# NGINX Configuration and Setup Script

LOG_FILE="$1"
# The current working directory where the installer was run (for README placement)
CWD=$(pwd)

HOST_NAME="nginx.localhost.com"
NGINX_CONF_DIR="/etc/nginx/conf.d"
NGINX_ROOT="/var/www/html/$HOST_NAME"
CERT_DIR="/etc/ssl/certs/nginx"
NGINX_MAIN_CONF="/etc/nginx/nginx.conf"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - (Config) $1" | tee -a "$LOG_FILE"
}

# --- Configuration Actions ---

# 1. Create Self-Signed Certificate
log "1. Creating private key and self-signed certificate..."
mkdir -p "$CERT_DIR"

if openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/nginx.key" \
    -out "$CERT_DIR/nginx.crt" \
    -subj "/C=US/ST=State/L=City/O=LocalHost/CN=$HOST_NAME" 2>/dev/null; then
    log "   ✅ Certificate and Key created successfully."
else
    log "   ❌ Failed to create SSL certificate/key."
    exit 1
fi

# 2. Add Host entry for local testing
log "2. Adding $HOST_NAME to /etc/hosts for local testing..."
if ! grep -q "127.0.0.1 $HOST_NAME" /etc/hosts; then
    echo "127.0.0.1 $HOST_NAME" >> /etc/hosts
    log "   ✅ Host entry added."
else
    log "   ✅ Host entry already present."
fi

# 3. Create NGINX Configuration File
log "3. Creating NGINX HTTPS site configuration for $HOST_NAME..."
mkdir -p "$NGINX_ROOT"

# Ensure /etc/nginx/nginx.conf includes the conf.d directory (standard for most installs)
# This check is mostly for verification
if ! grep -q "include /etc/nginx/conf.d/\*.conf;" "$NGINX_MAIN_CONF" 2>/dev/null; then
    log "   ⚠️ WARNING: Ensure $NGINX_MAIN_CONF includes the 'conf.d' directory."
fi

cat > "$NGINX_CONF_DIR/$HOST_NAME.conf" <<EOF
server {
    listen 80;
    server_name $HOST_NAME;
    # Redirect HTTP to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $HOST_NAME;

    # SSL Configuration (using the self-signed cert created)
    ssl_certificate $CERT_DIR/nginx.crt;
    ssl_certificate_key $CERT_DIR/nginx.key;

    # Basic security headers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root $NGINX_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Log file definitions
    access_log /var/log/nginx/$HOST_NAME.access.log;
    error_log /var/log/nginx/$HOST_NAME.error.log;
}
EOF
log "   ✅ NGINX site configuration created at $NGINX_CONF_DIR/$HOST_NAME.conf."

# 4. Create simple test page
log "4. Creating simple test HTML page..."
cat > "$NGINX_ROOT/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>NGINX Test Site</title>
</head>
<body>
    <h1>Welcome to HTTPS NGINX Test Page</h1>
    <p>If you see this, NGINX is installed, configured for HTTPS on $HOST_NAME, and running correctly.</p>
    <p>Configuration time: $(date)</p>
</body>
</html>
EOF
log "   ✅ Test page created."

# 5. Create comprehensive README.txt in the current directory
log "5. Creating README.txt with site configuration instructions in $CWD/README.txt..."

cat > "$CWD/README.txt" <<EOF
--- NGINX Installation and Configuration Summary ---

This guide details the steps to set up a new website (Virtual Host) on your NGINX server.

## I. Installed Test Site Details
1. **Test URL**: https://nginx.localhost.com/
2. **Configuration File**: $NGINX_CONF_DIR/$HOST_NAME.conf
3. **Document Root**: $NGINX_ROOT
4. **Self-Signed Certificate**: $CERT_DIR/nginx.crt
5. **Self-Signed Key**: $CERT_DIR/nginx.key

## II. How to Add a New Website (Virtual Host)

### 1. Create the Document Root
Create the directory that will hold your website files (HTML, CSS, etc.).

\$ sudo mkdir -p /var/www/html/mynewsite.com

### 2. Create the Configuration File
Create a new file in the conf.d directory. Use a descriptive name ending in .conf.

\$ sudo nano $NGINX_CONF_DIR/mynewsite.com.conf

### 3. Basic HTTP Configuration
Paste the following structure into the file, replacing 'mynewsite.com' with your actual domain:

server {
    listen 80;
    server_name mynewsite.com www.mynewsite.com;

    root /var/www/html/mynewsite.com;
    index index.html index.htm;

    # Standard location block
    location / {
        try_files \$uri \$uri/ =404;
    }
}

### 4. Optional: HTTPS (SSL) Configuration
For HTTPS, you will need a valid SSL certificate (e.g., from Let's Encrypt or a vendor).
A simple HTTPS block would look like this:

server {
    listen 443 ssl;
    server_name mynewsite.com;

    # IMPORTANT: Update these paths to your actual certificate files
    ssl_certificate /etc/ssl/certs/mynewsite.crt;
    ssl_certificate_key /etc/ssl/private/mynewsite.key;

    root /var/www/html/mynewsite.com;
    index index.html;

    # ... rest of location blocks ...
}

### 5. Final Steps: Test and Restart
After saving your new .conf file, you must check the syntax and reload NGINX.

* **Test Config Syntax**:
    \$ sudo nginx -t

* **Reload NGINX**:
    \$ sudo systemctl reload nginx

## III. Testing Commands
Use these commands to verify the installation:

* **Check the current test site**:
    \$ curl -s -k -H "Host: $HOST_NAME" https://127.0.0.1/

* **View the full installation log**:
    \$ cat $LOG_FILE
EOF
log "   ✅ README.txt created successfully in the current folder."

# 6. Start the NGINX Server
log "6. Testing configuration and starting NGINX..."

if ! nginx -t 2>&1 | tee -a "$LOG_FILE"; then
    log "   ❌ NGINX configuration test FAILED. Check syntax."
    exit 1
fi

systemctl enable nginx 2>/dev/null
if systemctl start nginx; then
    log "   ✅ NGINX service started successfully."
else
    log "   ❌ Failed to start NGINX service."
    exit 1
fi

exit 0 # Successful configuration