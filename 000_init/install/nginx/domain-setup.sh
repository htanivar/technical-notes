#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-config.env}"
LOG_FILE="./domain-setup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

fail() {
  log "[ERROR] $1"
  exit 1
}

log "==== DOMAIN SETUP START ===="

# -------------------------------
# Preconditions
# -------------------------------
if [[ $EUID -ne 0 ]]; then
  fail "Run as root (sudo)"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "Config file not found: $CONFIG_FILE"
fi

log "Loading config from $CONFIG_FILE"
source "$CONFIG_FILE"

: "${DOMAIN:?Missing DOMAIN}"
: "${EMAIL:?Missing EMAIL}"
: "${APP_PORT:?Missing APP_PORT}"

log "Config loaded: DOMAIN=$DOMAIN EMAIL=$EMAIL APP_PORT=$APP_PORT"

# -------------------------------
# Install dependencies
# -------------------------------
log "Installing dependencies (nginx, certbot)..."
apt update -y
apt install -y nginx certbot python3-certbot-nginx

# -------------------------------
# Clean conflicting configs
# -------------------------------
log "Removing default nginx site if exists..."
rm -f /etc/nginx/sites-enabled/default || true

# -------------------------------
# Create HTTP config
# -------------------------------
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

log "Creating HTTP nginx config: $NGINX_CONF"

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

log "Enabling site..."
ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"

# -------------------------------
# Websocket map
# -------------------------------
log "Ensuring websocket upgrade map exists..."
if ! grep -q "connection_upgrade" /etc/nginx/nginx.conf; then
  sed -i '/http {/a \
    map $http_upgrade $connection_upgrade {\n\
        default upgrade;\n\
        "" close;\n\
    }' /etc/nginx/nginx.conf
  log "connection_upgrade map added"
else
  log "connection_upgrade map already exists"
fi

# -------------------------------
# Reload nginx HTTP
# -------------------------------
log "Validating nginx config (HTTP phase)..."
nginx -t || fail "nginx config invalid"

log "Reloading nginx (HTTP)..."
systemctl reload nginx

# -------------------------------
# SSL certificate
# -------------------------------
log "Obtaining SSL certificate..."

certbot certonly \
  --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" || fail "Certbot failed"

CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

log "Verifying certificate files..."
ls -l "$CERT_PATH" || fail "Certificate path missing"

[[ -f "$CERT_PATH/fullchain.pem" ]] || fail "fullchain.pem missing"
[[ -f "$CERT_PATH/privkey.pem" ]] || fail "privkey.pem missing"

log "Certificate files verified"

# -------------------------------
# Create HTTPS config
# -------------------------------
log "Writing HTTPS nginx config..."

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# -------------------------------
# Reload nginx HTTPS
# -------------------------------
log "Validating nginx config (HTTPS phase)..."
nginx -t || fail "nginx config invalid after SSL"

log "Reloading nginx (HTTPS)..."
systemctl reload nginx

# -------------------------------
# Runtime validation
# -------------------------------
SERVER_IP=$(hostname -I | awk '{print $1}')

log "Checking SSL handshake (direct origin: $SERVER_IP)..."

if ! openssl s_client -connect "$SERVER_IP:443" -servername "$DOMAIN" </dev/null 2>/dev/null | grep -q "BEGIN CERTIFICATE"; then
  fail "SSL not served by nginx (origin check failed)"
fi

log "SSL handshake successful (origin)"

# -------------------------------
# Renewal test
# -------------------------------
log "Testing certificate renewal..."
certbot renew --dry-run || fail "Renewal test failed"

# -------------------------------
# Done
# -------------------------------
log "==== SUCCESS ===="
log "Deployment complete: https://$DOMAIN"
log "Logs saved to $LOG_FILE"