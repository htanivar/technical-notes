#!/usr/bin/env bash
#
# configure_nginx.sh — Interactive Production-Grade NGINX Site Configurator
#
# Usage:
#   Interactive mode : sudo ./configure_nginx.sh
#   Installer mode   : sudo ./configure_nginx.sh /var/log/nginx_install.log
#   Non-interactive  : sudo ./configure_nginx.sh -y --domain app.example.com --mode proxy --app-port 3000
#
# Features:
#   - Interactive wizard with sensible defaults (supports both Static Sites & Reverse Proxy with WebSockets)
#   - Production-grade TLS 1.2/1.3, Mozilla Intermediate AEAD ciphers, HSTS & OWASP security headers
#   - Request rate limiting (limit_req_zone / limit_req), dotfile (.git/.env) & backup file blocking
#   - Works across systemd, SysVinit, OpenRC, and direct daemon environments
#   - Generates comprehensive site README (README-<servername>.md and README.txt) with URLs, ports, logs, SSL certs, and commands

set -euo pipefail
export LC_ALL=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

CWD="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# Defaults
LOG_FILE=""
NON_INTERACTIVE=0
HOST_NAME="nginx.localhost.com"
SERVER_ALIASES=""
SITE_MODE="static"             # static | proxy
NGINX_ROOT=""                  # defaults to /var/www/html/$HOST_NAME
BACKEND_HOST="127.0.0.1"
BACKEND_PORT="3000"
HTTP_PORT="80"
HTTPS_PORT="443"
SSL_MODE="self-signed"         # self-signed | letsencrypt | custom | none
LE_EMAIL="admin@localhost"
CUSTOM_CERT=""
CUSTOM_KEY=""
CLIENT_MAX_BODY="25m"
RATE_LIMIT="20r/s"
RATE_BURST="40"
ADD_HOSTS_ENTRY="auto"         # auto | yes | no

NGINX_MAIN_CONF="/etc/nginx/nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d"
CERT_BASE_DIR="/etc/ssl/certs/nginx"

########################
# Colors & Helpers
########################
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'; C_RED=$'\e[31m'; C_CYAN=$'\e[36m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""
fi

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") [LOG_FILE] [OPTIONS]

Options:
  -y, --non-interactive       Use defaults / CLI flags without interactive prompts
  -d, --domain <name>         Primary server_name / domain (default: nginx.localhost.com)
  -a, --aliases <list>        Space-separated server_name aliases (e.g. "www.example.com")
  -m, --mode <static|proxy>   Site mode: 'static' web root or 'proxy' reverse proxy (default: static)
  -r, --root <path>           Document root for static mode (default: /var/www/html/<domain>)
  -b, --backend-host <host>   Upstream host for proxy mode (default: 127.0.0.1)
  -p, --app-port <port>       Upstream port for proxy mode (default: 3000)
      --http-port <port>      HTTP listen port (default: 80)
      --https-port <port>     HTTPS listen port (default: 443)
  -s, --ssl <mode>            SSL mode: self-signed | letsencrypt | custom | none (default: self-signed)
  -e, --email <email>         Email for Let's Encrypt registration
      --cert <path>           Custom SSL certificate path (for --ssl custom)
      --key <path>            Custom SSL private key path (for --ssl custom)
      --max-body <size>       client_max_body_size (default: 25m)
      --rate-limit <rate>     Per-IP rate limit (default: 20r/s)
      --add-hosts <yes|no>    Add 127.0.0.1 entry to /etc/hosts (default: auto)
  -l, --log-file <path>       Log file path
  -h, --help                  Show this help message
EOF
}

# Parse positional log file if first arg is not a flag (backwards-compatible with install_nginx.sh)
if [[ $# -gt 0 && "${1:-}" != -* ]]; then
  LOG_FILE="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--non-interactive) NON_INTERACTIVE=1; shift ;;
    -d|--domain)          HOST_NAME="$2"; shift 2 ;;
    -a|--aliases)         SERVER_ALIASES="$2"; shift 2 ;;
    -m|--mode)            SITE_MODE="$2"; shift 2 ;;
    -r|--root)            NGINX_ROOT="$2"; shift 2 ;;
    -b|--backend-host)    BACKEND_HOST="$2"; shift 2 ;;
    -p|--app-port)        BACKEND_PORT="$2"; shift 2 ;;
    --http-port)          HTTP_PORT="$2"; shift 2 ;;
    --https-port)         HTTPS_PORT="$2"; shift 2 ;;
    -s|--ssl)             SSL_MODE="$2"; shift 2 ;;
    -e|--email)           LE_EMAIL="$2"; shift 2 ;;
    --cert)               CUSTOM_CERT="$2"; shift 2 ;;
    --key)                CUSTOM_KEY="$2"; shift 2 ;;
    --max-body)           CLIENT_MAX_BODY="$2"; shift 2 ;;
    --rate-limit)         RATE_LIMIT="$2"; shift 2 ;;
    --add-hosts)          ADD_HOSTS_ENTRY="$2"; shift 2 ;;
    -l|--log-file)        LOG_FILE="$2"; shift 2 ;;
    -h|--help)            usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$LOG_FILE" ]]; then
  LOG_FILE="/var/log/nginx_configure_${TS}.log"
  touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/nginx_configure_${TS}.log"
else
  touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/$(basename "$LOG_FILE")"
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - (Config) $1" | tee -a "$LOG_FILE"
}

prompt_val() {
  local prompt_text="$1"
  local default_val="$2"
  local reply=""
  read -r -p "  ${prompt_text} [${default_val}]: " reply || true
  if [[ -n "$reply" ]]; then
    echo "$reply"
  else
    echo "$default_val"
  fi
}

########################
# Pre-Flight Root & Binary Check
########################
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "${C_RED}[FATAL] configure_nginx.sh must be run as root (use: sudo $0)${C_RESET}" >&2
  exit 1
fi

NGINX_BIN="$(command -v nginx || true)"
if [[ -z "$NGINX_BIN" ]]; then
  for p in /usr/sbin/nginx /usr/local/sbin/nginx /usr/local/nginx/sbin/nginx; do
    [[ -x "$p" ]] && NGINX_BIN="$p" && break
  done
fi
if [[ -z "$NGINX_BIN" ]]; then
  log "❌ NGINX binary not found. Run install_nginx.sh first."
  exit 1
fi

########################
# Interactive Wizard (when terminal attached & not -y)
########################
if (( NON_INTERACTIVE == 0 )) && [[ -t 0 && -t 1 ]]; then
  printf "\n${C_BOLD}====================================================================${C_RESET}\n"
  printf "${C_CYAN}${C_BOLD}        NGINX PRODUCTION SITE CONFIGURATION WIZARD                  ${C_RESET}\n"
  printf "${C_BOLD}====================================================================${C_RESET}\n"
  printf "Press Enter at any prompt to accept the default value in [brackets].\n\n"

  HOST_NAME="$(prompt_val "1. Primary Server Name / Domain" "$HOST_NAME")"
  SERVER_ALIASES="$(prompt_val "2. Optional Domain Aliases (space-separated, or leave blank)" "$SERVER_ALIASES")"

  printf "\n  3. Select Site Mode:\n"
  printf "     1) static  — Serve static files (HTML/JS/CSS/SPA) from a document root\n"
  printf "     2) proxy   — Reverse proxy to an upstream backend application (Node/Python/Go/Docker)\n"
  mode_choice="$(prompt_val "   Choose mode (1/static or 2/proxy)" "1")"
  case "$mode_choice" in
    2|proxy|reverse-proxy) SITE_MODE="proxy" ;;
    *)                     SITE_MODE="static" ;;
  esac

  if [[ "$SITE_MODE" == "proxy" ]]; then
    BACKEND_HOST="$(prompt_val "   Upstream Backend Host/IP" "$BACKEND_HOST")"
    BACKEND_PORT="$(prompt_val "   Upstream Backend Port" "$BACKEND_PORT")"
  else
    default_root="${NGINX_ROOT:-/var/www/html/${HOST_NAME}}"
    NGINX_ROOT="$(prompt_val "   Document Root Directory" "$default_root")"
  fi

  HTTP_PORT="$(prompt_val "4. HTTP Listen Port" "$HTTP_PORT")"
  HTTPS_PORT="$(prompt_val "5. HTTPS Listen Port" "$HTTPS_PORT")"

  printf "\n  6. Select SSL / TLS Certificate Mode:\n"
  printf "     1) self-signed  — Auto-generate X.509 v3 SAN self-signed cert & 600 key\n"
  printf "     2) letsencrypt  — Request/use Let's Encrypt certificate via Certbot\n"
  printf "     3) custom       — Provide existing SSL certificate and private key paths\n"
  printf "     4) none         — HTTP only (no SSL/TLS)\n"
  ssl_choice="$(prompt_val "   Choose SSL mode (1-4)" "1")"
  case "$ssl_choice" in
    2|letsencrypt|le) SSL_MODE="letsencrypt" ;;
    3|custom)         SSL_MODE="custom" ;;
    4|none|http)      SSL_MODE="none" ;;
    *)                SSL_MODE="self-signed" ;;
  esac

  if [[ "$SSL_MODE" == "letsencrypt" ]]; then
    LE_EMAIL="$(prompt_val "   Let's Encrypt notification email" "$LE_EMAIL")"
  elif [[ "$SSL_MODE" == "custom" ]]; then
    CUSTOM_CERT="$(prompt_val "   Path to SSL Certificate (.crt/.pem)" "/etc/ssl/certs/${HOST_NAME}.crt")"
    CUSTOM_KEY="$(prompt_val "   Path to SSL Private Key (.key)" "/etc/ssl/private/${HOST_NAME}.key")"
  fi

  CLIENT_MAX_BODY="$(prompt_val "7. Max Upload Body Size (client_max_body_size)" "$CLIENT_MAX_BODY")"
  RATE_LIMIT="$(prompt_val "8. Per-IP Request Rate Limit (e.g. 20r/s)" "$RATE_LIMIT")"
  ADD_HOSTS_ENTRY="$(prompt_val "9. Add '127.0.0.1 ${HOST_NAME}' to /etc/hosts? (yes/no)" "yes")"
  echo
fi

[[ -z "$NGINX_ROOT" ]] && NGINX_ROOT="/var/www/html/${HOST_NAME}"
if [[ "$ADD_HOSTS_ENTRY" == "auto" ]]; then
  if [[ "$HOST_NAME" =~ \.(localhost|local|test|vdev\.com)$ || "$HOST_NAME" == "nginx.localhost.com" ]]; then
    ADD_HOSTS_ENTRY="yes"
  else
    ADD_HOSTS_ENTRY="no"
  fi
fi

SERVER_NAME_DIRECTIVE="$HOST_NAME"
[[ -n "$SERVER_ALIASES" ]] && SERVER_NAME_DIRECTIVE="${HOST_NAME} ${SERVER_ALIASES}"

ACCESS_LOG_PATH="/var/log/nginx/${HOST_NAME}.access.log"
ERROR_LOG_PATH="/var/log/nginx/${HOST_NAME}.error.log"
SITE_CONF_PATH="${NGINX_CONF_DIR}/${HOST_NAME}.conf"

log "Starting production configuration for '${HOST_NAME}' (mode=${SITE_MODE}, ssl=${SSL_MODE}, http=${HTTP_PORT}, https=${HTTPS_PORT})"

########################
# Step 1: Backup & Harden Global /etc/nginx/nginx.conf
########################
log "1. Applying production baseline hardening to ${NGINX_MAIN_CONF}..."
mkdir -p "$NGINX_CONF_DIR" /var/log/nginx

BACKUP_DIR="/tmp/nginx_conf_backup_${TS}"
mkdir -p "$BACKUP_DIR"
cp -a "$NGINX_MAIN_CONF" "$BACKUP_DIR/nginx.conf.bak" 2>/dev/null || true
[[ -f "$SITE_CONF_PATH" ]] && cp -a "$SITE_CONF_PATH" "$BACKUP_DIR/site.conf.bak" 2>/dev/null || true

if [[ -f "$NGINX_MAIN_CONF" ]]; then
  # 1a. Enable server_tokens off;
  if grep -qE '^\s*#\s*server_tokens\s+off;' "$NGINX_MAIN_CONF"; then
    sed -i -E 's/^\s*#\s*server_tokens\s+off;/\tserver_tokens off;/' "$NGINX_MAIN_CONF"
  elif ! grep -qE '^\s*server_tokens\s+off;' "$NGINX_MAIN_CONF"; then
    sed -i '/http\s*{/a \	server_tokens off;' "$NGINX_MAIN_CONF"
  fi

  # 1b. Enforce modern TLSv1.2 and TLSv1.3 only in nginx.conf
  if grep -qE '^\s*ssl_protocols\s+' "$NGINX_MAIN_CONF"; then
    sed -i -E 's/^\s*ssl_protocols\s+.*;/\tssl_protocols TLSv1.2 TLSv1.3;/' "$NGINX_MAIN_CONF"
  fi

  # 1c. Add shared SSL session cache, tickets off, rate limit zone, and WebSocket upgrade map inside http {}
  SNIPPET_CONF="${NGINX_CONF_DIR}/00-production-hardening.conf"
  cat > "$SNIPPET_CONF" <<EOF
# Managed by configure_nginx.sh — Global Production Hardening & Shared Zones
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# Global per-IP request rate limiting zone
limit_req_zone \$binary_remote_addr zone=prod_req_limit:10m rate=${RATE_LIMIT};

# WebSocket connection upgrade mapping
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}
EOF
  chmod 644 "$SNIPPET_CONF"

  # Remove any duplicate default ssl_session_cache / map if already in nginx.conf to prevent directive clashes
  if grep -qE '^\s*ssl_session_cache\s+' "$NGINX_MAIN_CONF"; then
    sed -i -E '/^ssl_session_cache/d; /^ssl_session_timeout/d; /^ssl_session_tickets/d' "$SNIPPET_CONF"
  fi
  if grep -q "connection_upgrade" "$NGINX_MAIN_CONF"; then
    sed -i '/^map \$http_upgrade/,/^}/d' "$SNIPPET_CONF"
  fi
  if grep -q "prod_req_limit" "$NGINX_MAIN_CONF"; then
    sed -i '/^limit_req_zone.*prod_req_limit/d' "$SNIPPET_CONF"
  fi

  # Ensure nginx.conf includes /etc/nginx/conf.d/*.conf
  if ! grep -qE 'include\s+/etc/nginx/conf\.d/\*\.conf;' "$NGINX_MAIN_CONF"; then
    log "   ⚠️ Adding 'include /etc/nginx/conf.d/*.conf;' to ${NGINX_MAIN_CONF}"
    sed -i '/http\s*{/a \	include /etc/nginx/conf.d/*.conf;' "$NGINX_MAIN_CONF"
  fi
  log "   ✅ Global production settings verified ($SNIPPET_CONF)."
fi

########################
# Step 2: SSL / TLS Certificate Provisioning
########################
SSL_CERT_FILE=""
SSL_KEY_FILE=""
CERT_EXPIRY_DATE="N/A (HTTP-only)"
CERT_ISSUER="N/A"

if [[ "$SSL_MODE" == "self-signed" ]]; then
  log "2. Generating self-signed X.509 v3 SAN certificate for ${HOST_NAME}..."
  mkdir -p "$CERT_BASE_DIR"
  chmod 755 "$CERT_BASE_DIR"

  if [[ "$HOST_NAME" == "nginx.localhost.com" ]]; then
    SSL_CERT_FILE="${CERT_BASE_DIR}/nginx.crt"
    SSL_KEY_FILE="${CERT_BASE_DIR}/nginx.key"
  else
    SSL_CERT_FILE="${CERT_BASE_DIR}/${HOST_NAME}.crt"
    SSL_KEY_FILE="${CERT_BASE_DIR}/${HOST_NAME}.key"
  fi

  SAN_LIST="DNS:${HOST_NAME},DNS:localhost,IP:127.0.0.1"
  for al in $SERVER_ALIASES; do
    SAN_LIST="${SAN_LIST},DNS:${al}"
  done

  OPENSSL_CNF="$(mktemp)"
  cat > "$OPENSSL_CNF" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = US
ST = State
L = City
O = ProductionNginx
CN = ${HOST_NAME}

[v3_req]
subjectAltName = ${SAN_LIST}
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

  if openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$SSL_KEY_FILE" \
      -out "$SSL_CERT_FILE" \
      -config "$OPENSSL_CNF" 2>/dev/null; then
    rm -f "$OPENSSL_CNF"
    chmod 600 "$SSL_KEY_FILE"
    chmod 644 "$SSL_CERT_FILE"
    chown root:root "$SSL_KEY_FILE" "$SSL_CERT_FILE" 2>/dev/null || true
    log "   ✅ Self-signed certificate created: ${SSL_CERT_FILE} (key mode 600: ${SSL_KEY_FILE})"
  else
    rm -f "$OPENSSL_CNF"
    log "   ❌ Failed to generate SSL certificate."
    exit 1
  fi
elif [[ "$SSL_MODE" == "letsencrypt" ]]; then
  log "2. Setting up Let's Encrypt certificate for ${HOST_NAME}..."
  if command -v certbot >/dev/null 2>&1; then
    if certbot certonly --nginx -d "$HOST_NAME" --non-interactive --agree-tos --email "$LE_EMAIL"; then
      SSL_CERT_FILE="/etc/letsencrypt/live/${HOST_NAME}/fullchain.pem"
      SSL_KEY_FILE="/etc/letsencrypt/live/${HOST_NAME}/privkey.pem"
      log "   ✅ Let's Encrypt certificate obtained: ${SSL_CERT_FILE}"
    else
      log "   ⚠️ Certbot failed (domain may not point to this host yet); falling back to self-signed certificate..."
      SSL_MODE="self-signed"
      mkdir -p "$CERT_BASE_DIR"
      SSL_CERT_FILE="${CERT_BASE_DIR}/${HOST_NAME}.crt"
      SSL_KEY_FILE="${CERT_BASE_DIR}/${HOST_NAME}.key"
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_KEY_FILE" -out "$SSL_CERT_FILE" \
        -subj "/C=US/ST=State/L=City/O=LocalHost/CN=${HOST_NAME}" 2>/dev/null
      chmod 600 "$SSL_KEY_FILE"
      chmod 644 "$SSL_CERT_FILE"
    fi
  else
    log "   ❌ certbot is not installed. Run with --ssl self-signed or install certbot."
    exit 1
  fi
elif [[ "$SSL_MODE" == "custom" ]]; then
  log "2. Validating custom SSL certificate and private key..."
  if [[ ! -r "$CUSTOM_CERT" || ! -r "$CUSTOM_KEY" ]]; then
    log "   ❌ Custom certificate ($CUSTOM_CERT) or key ($CUSTOM_KEY) not found or unreadable."
    exit 1
  fi
  SSL_CERT_FILE="$CUSTOM_CERT"
  SSL_KEY_FILE="$CUSTOM_KEY"
  chmod 600 "$SSL_KEY_FILE" 2>/dev/null || true
  log "   ✅ Custom certificate validated: ${SSL_CERT_FILE}"
else
  log "2. Skipping SSL certificate creation (HTTP-only mode)."
fi

if [[ -n "$SSL_CERT_FILE" && -r "$SSL_CERT_FILE" ]] && command -v openssl >/dev/null 2>&1; then
  CERT_EXPIRY_DATE="$(openssl x509 -in "$SSL_CERT_FILE" -noout -enddate 2>/dev/null | cut -d= -f2 || echo 'Unknown')"
  CERT_ISSUER="$(openssl x509 -in "$SSL_CERT_FILE" -noout -issuer 2>/dev/null | sed 's/issuer=//' || echo 'Self-Signed')"
fi

########################
# Step 3: Optional /etc/hosts Entry
########################
if [[ "$ADD_HOSTS_ENTRY" =~ ^(yes|y|true|1)$ ]]; then
  log "3. Ensuring ${HOST_NAME} is present in /etc/hosts..."
  if ! grep -qE "^127\.0\.0\.1[[:space:]].*\b${HOST_NAME}\b" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 ${HOST_NAME}" >> /etc/hosts
    log "   ✅ Added '127.0.0.1 ${HOST_NAME}' to /etc/hosts."
  else
    log "   ✅ Host entry for ${HOST_NAME} already exists in /etc/hosts."
  fi
else
  log "3. Skipping /etc/hosts modification (ADD_HOSTS_ENTRY=${ADD_HOSTS_ENTRY})."
fi

########################
# Step 4: Prepare Document Root & Default Page (Static Mode)
########################
if [[ "$SITE_MODE" == "static" ]]; then
  log "4. Preparing document root at ${NGINX_ROOT}..."
  mkdir -p "$NGINX_ROOT"
  chmod 755 "$NGINX_ROOT"

  if [[ ! -f "${NGINX_ROOT}/index.html" || "$HOST_NAME" == "nginx.localhost.com" ]]; then
    cat > "${NGINX_ROOT}/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to ${HOST_NAME} — NGINX Test Site</title>
</head>
<body>
    <h1>Welcome to HTTPS NGINX Test Page</h1>
    <p>If you see this, NGINX is installed, configured for HTTPS on <strong>${HOST_NAME}</strong>, and running correctly.</p>
    <ul>
        <li><strong>Server Name:</strong> ${SERVER_NAME_DIRECTIVE}</li>
        <li><strong>Mode:</strong> Static Site (${NGINX_ROOT})</li>
        <li><strong>HTTP / HTTPS Ports:</strong> ${HTTP_PORT} / ${HTTPS_PORT}</li>
        <li><strong>Configured At:</strong> $(date '+%Y-%m-%d %H:%M:%S %Z')</li>
    </ul>
</body>
</html>
EOF
  fi
  chown -R www-data:www-data "$NGINX_ROOT" 2>/dev/null || chown -R nginx:nginx "$NGINX_ROOT" 2>/dev/null || true
  log "   ✅ Document root ready at ${NGINX_ROOT}."
else
  log "4. Reverse proxy mode selected -> forwarding to http://${BACKEND_HOST}:${BACKEND_PORT}"
fi

########################
# Step 5: Write Production-Grade Virtual Host Configuration
########################
log "5. Writing production NGINX virtual host config to ${SITE_CONF_PATH}..."

# Check if nginx supports 'http2 on;' directive (>= 1.25.1) vs 'listen 443 ssl http2;'
HTTP2_LISTEN_OPT="http2"
if [[ "$SSL_MODE" == "none" ]]; then
  HTTP2_LISTEN_OPT=""
fi

# Build location block based on static vs reverse-proxy mode
if [[ "$SITE_MODE" == "proxy" ]]; then
  LOCATION_BODY=$(cat <<EOF
    # Reverse Proxy to upstream application (${BACKEND_HOST}:${BACKEND_PORT})
    location / {
        limit_req zone=prod_req_limit burst=${RATE_BURST} nodelay;

        proxy_pass http://${BACKEND_HOST}:${BACKEND_PORT};
        proxy_http_version 1.1;

        # WebSocket & Keepalive headers
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        # Standard client forwarding headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;

        # Upstream timeouts & buffer hardening
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_hide_header X-Powered-By;
    }
EOF
)
else
  LOCATION_BODY=$(cat <<EOF
    root ${NGINX_ROOT};
    index index.html index.htm;

    location / {
        limit_req zone=prod_req_limit burst=${RATE_BURST} nodelay;
        try_files \$uri \$uri/ =404;
    }

    # Long-lived browser caching for static assets
    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|webp|woff2?|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
EOF
)
fi

if [[ "$SSL_MODE" != "none" ]]; then
  REDIRECT_PORT_SUFFIX=""
  [[ "$HTTPS_PORT" != "443" ]] && REDIRECT_PORT_SUFFIX=":${HTTPS_PORT}"

  cat > "$SITE_CONF_PATH" <<EOF
# =====================================================================
# Production Virtual Host Configuration for: ${HOST_NAME}
# Generated by configure_nginx.sh on $(date '+%Y-%m-%d %H:%M:%S %Z')
# Mode: ${SITE_MODE} | HTTP Port: ${HTTP_PORT} | HTTPS Port: ${HTTPS_PORT}
# =====================================================================

server {
    listen ${HTTP_PORT};
    listen [::]:${HTTP_PORT};
    server_name ${SERVER_NAME_DIRECTIVE};

    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$host${REDIRECT_PORT_SUFFIX}\$request_uri;
}

server {
    listen ${HTTPS_PORT} ssl ${HTTP2_LISTEN_OPT};
    listen [::]:${HTTPS_PORT} ssl ${HTTP2_LISTEN_OPT};
    server_name ${SERVER_NAME_DIRECTIVE};

    # --- SSL / TLS Certificates & Modern Cipher Suite ---
    ssl_certificate ${SSL_CERT_FILE};
    ssl_certificate_key ${SSL_KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # --- OWASP Production Security Headers ---
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' data: https:;" always;

    # --- Request Size & Timeout Hardening ---
    client_max_body_size ${CLIENT_MAX_BODY};
    client_body_timeout 30s;
    client_header_timeout 30s;
    send_timeout 30s;

    # --- Dedicated Site Logs ---
    access_log ${ACCESS_LOG_PATH};
    error_log ${ERROR_LOG_PATH} warn;

    # --- Health Check Endpoint ---
    location = /healthz {
        access_log off;
        default_type text/plain;
        return 200 "OK\n";
    }

${LOCATION_BODY}

    # --- Block Hidden Dotfiles (.git, .env, .htpasswd) ---
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    # --- Block Backup, SQL & Temp Artifacts ---
    location ~* \.(?:bak|sql|old|swp|orig|save|env)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
else
  cat > "$SITE_CONF_PATH" <<EOF
# =====================================================================
# Production HTTP Virtual Host Configuration for: ${HOST_NAME}
# Generated by configure_nginx.sh on $(date '+%Y-%m-%d %H:%M:%S %Z')
# Mode: ${SITE_MODE} | HTTP Port: ${HTTP_PORT} (SSL disabled)
# =====================================================================

server {
    listen ${HTTP_PORT};
    listen [::]:${HTTP_PORT};
    server_name ${SERVER_NAME_DIRECTIVE};

    # --- OWASP Production Security Headers ---
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' data: http: https:;" always;

    client_max_body_size ${CLIENT_MAX_BODY};
    access_log ${ACCESS_LOG_PATH};
    error_log ${ERROR_LOG_PATH} warn;

    location = /healthz {
        access_log off;
        default_type text/plain;
        return 200 "OK\n";
    }

${LOCATION_BODY}

    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* \.(?:bak|sql|old|swp|orig|save|env)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
fi

chmod 644 "$SITE_CONF_PATH"
log "   ✅ Site configuration created at ${SITE_CONF_PATH}."

########################
# Step 6: Validate Config & Start/Reload NGINX Across Init Systems
########################
log "6. Validating NGINX configuration and starting/reloading service..."

if ! "$NGINX_BIN" -t 2>&1 | tee -a "$LOG_FILE"; then
  log "   ❌ NGINX configuration test FAILED! Restoring previous configuration backup..."
  [[ -f "$BACKUP_DIR/nginx.conf.bak" ]] && cp -a "$BACKUP_DIR/nginx.conf.bak" "$NGINX_MAIN_CONF"
  if [[ -f "$BACKUP_DIR/site.conf.bak" ]]; then
    cp -a "$BACKUP_DIR/site.conf.bak" "$SITE_CONF_PATH"
  else
    rm -f "$SITE_CONF_PATH"
  fi
  rm -rf "$BACKUP_DIR"
  exit 1
fi
rm -rf "$BACKUP_DIR"

start_or_reload_nginx() {
  # Enable at boot best-effort
  if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl enable nginx 2>/dev/null || true
    if systemctl is-active --quiet nginx; then
      systemctl reload nginx || systemctl restart nginx
    else
      systemctl start nginx
    fi
    return $?
  fi

  if command -v update-rc.d >/dev/null 2>&1; then
    update-rc.d nginx defaults >/dev/null 2>&1 || true
  elif command -v chkconfig >/dev/null 2>&1; then
    chkconfig nginx on >/dev/null 2>&1 || true
  elif command -v rc-update >/dev/null 2>&1; then
    rc-update add nginx default >/dev/null 2>&1 || true
  fi

  if pgrep -x nginx >/dev/null 2>&1; then
    service nginx reload 2>/dev/null || rc-service nginx reload 2>/dev/null || "$NGINX_BIN" -s reload
  else
    service nginx start 2>/dev/null || rc-service nginx start 2>/dev/null || "$NGINX_BIN"
  fi
}

if start_or_reload_nginx; then
  log "   ✅ NGINX service is active and serving ${HOST_NAME}."
else
  log "   ❌ Failed to start or reload NGINX service."
  exit 1
fi

########################
# Step 7: Generate Comprehensive Site README (README-<servername>.md & README.txt)
########################
SERVER_IP="$(ip -br addr 2>/dev/null | awk '$1 != "lo" && $2 == "UP" {sub(/\/.*/, "", $3); print $3; exit}' || true)"
[[ -z "$SERVER_IP" ]] && SERVER_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo '127.0.0.1')"
[[ -z "$SERVER_IP" ]] && SERVER_IP="127.0.0.1"

if [[ "$SSL_MODE" != "none" ]]; then
  PRIMARY_URL="https://${HOST_NAME}$( [[ "$HTTPS_PORT" != "443" ]] && echo ":${HTTPS_PORT}" || true )/"
  HEALTH_URL="https://${HOST_NAME}$( [[ "$HTTPS_PORT" != "443" ]] && echo ":${HTTPS_PORT}" || true )/healthz"
  CURL_TEST_CMD="curl -k -i --resolve ${HOST_NAME}:${HTTPS_PORT}:127.0.0.1 ${PRIMARY_URL}"
  CURL_HEADER_CMD="curl -s -k -H \"Host: ${HOST_NAME}\" https://127.0.0.1:$( [[ "$HTTPS_PORT" != "443" ]] && echo "${HTTPS_PORT}" || echo "443" )/"
else
  PRIMARY_URL="http://${HOST_NAME}$( [[ "$HTTP_PORT" != "80" ]] && echo ":${HTTP_PORT}" || true )/"
  HEALTH_URL="http://${HOST_NAME}$( [[ "$HTTP_PORT" != "80" ]] && echo ":${HTTP_PORT}" || true )/healthz"
  CURL_TEST_CMD="curl -i --resolve ${HOST_NAME}:${HTTP_PORT}:127.0.0.1 ${PRIMARY_URL}"
  CURL_HEADER_CMD="curl -s -H \"Host: ${HOST_NAME}\" http://127.0.0.1:${HTTP_PORT}/"
fi

HTTP_ENTRY_URL="http://${HOST_NAME}$( [[ "$HTTP_PORT" != "80" ]] && echo ":${HTTP_PORT}" || true )/"
SITE_README_MD="${CWD}/README-${HOST_NAME}.md"
LEGACY_README_TXT="${CWD}/README.txt"

if [[ "$SITE_MODE" == "proxy" ]]; then
  TARGET_DESC="Reverse Proxy -> http://${BACKEND_HOST}:${BACKEND_PORT} (WebSocket enabled)"
else
  TARGET_DESC="Static Document Root -> ${NGINX_ROOT}"
fi

log "7. Generating site documentation at ${SITE_README_MD} and ${LEGACY_README_TXT}..."

generate_readme_content() {
  cat <<EOF
# NGINX Production Site Summary — ${HOST_NAME}

Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')

## I. Site Overview & Connection Details

| Property | Value |
| :--- | :--- |
| **Server Name (Domain)** | \`${HOST_NAME}\` ${SERVER_ALIASES:+(Aliases: \`${SERVER_ALIASES}\`)} |
| **Site Mode** | \`${SITE_MODE}\` (${TARGET_DESC}) |
| **Primary App URL** | ${PRIMARY_URL} |
| **HTTP Entry URL** | ${HTTP_ENTRY_URL} $( [[ "$SSL_MODE" != "none" ]] && echo "(301 Redirects to HTTPS)" || true ) |
| **Healthcheck URL** | ${HEALTH_URL} |
| **Host / LAN IP** | \`${SERVER_IP}\` |
| **HTTP Listen Port** | \`${HTTP_PORT}\` |
| **HTTPS Listen Port** | \`$( [[ "$SSL_MODE" != "none" ]] && echo "$HTTPS_PORT" || echo "Disabled" )\` |
| **Backend App Port** | \`$( [[ "$SITE_MODE" == "proxy" ]] && echo "${BACKEND_HOST}:${BACKEND_PORT}" || echo "N/A (Static Site)" )\` |

---

## II. File Locations (Config, Logs, Web Root & SSL Certificates)

| Resource | Path / Location |
| :--- | :--- |
| **Virtual Host Config** | \`${SITE_CONF_PATH}\` |
| **Global Hardening Config** | \`${NGINX_CONF_DIR}/00-production-hardening.conf\` |
| **Main NGINX Config** | \`${NGINX_MAIN_CONF}\` |
| **Document Root / Upstream** | \`$( [[ "$SITE_MODE" == "static" ]] && echo "$NGINX_ROOT" || echo "http://${BACKEND_HOST}:${BACKEND_PORT}" )\` |
| **Access Log** | \`${ACCESS_LOG_PATH}\` |
| **Error Log** | \`${ERROR_LOG_PATH}\` |
| **Configuration Run Log** | \`${LOG_FILE}\` |
| **SSL Mode** | \`${SSL_MODE}\` |
| **SSL Certificate** | \`${SSL_CERT_FILE:-N/A}\` |
| **SSL Private Key** | \`${SSL_KEY_FILE:-N/A}\` (Permissions: \`600\`) |
| **SSL Issuer & Expiry** | ${CERT_ISSUER} — Expires: \`${CERT_EXPIRY_DATE}\` |

---

## III. Verification & Testing Commands

1. **Test the site locally via Host header**:
   \`\`\`bash
   ${CURL_HEADER_CMD}
   \`\`\`

2. **Test the site & inspect security headers via DNS override**:
   \`\`\`bash
   ${CURL_TEST_CMD}
   \`\`\`

3. **Check the healthcheck endpoint**:
   \`\`\`bash
   curl -s -k -H "Host: ${HOST_NAME}" https://127.0.0.1:${HTTPS_PORT}/healthz
   \`\`\`

4. **Test NGINX configuration syntax**:
   \`\`\`bash
   sudo nginx -t
   \`\`\`

---

## IV. Log Monitoring & Day-to-Day Operations

- **Tail site access & error logs in real time**:
  \`\`\`bash
  sudo tail -f ${ACCESS_LOG_PATH} ${ERROR_LOG_PATH}
  # Or using nginx-ops.sh:
  ${SCRIPT_DIR}/nginx-ops.sh logs --domain ${HOST_NAME} --follow
  \`\`\`

- **Check service status, reload, or restart NGINX**:
  \`\`\`bash
  ${SCRIPT_DIR}/nginx-ops.sh status
  sudo ${SCRIPT_DIR}/nginx-ops.sh reload
  sudo ${SCRIPT_DIR}/nginx-ops.sh restart
  \`\`\`

- **Run full security & configuration audit**:
  \`\`\`bash
  sudo ${SCRIPT_DIR}/status_nginx.sh
  \`\`\`

---

## V. Production Hardening Applied

- **TLS 1.2 & TLS 1.3 Only**: Legacy \`SSLv3\`, \`TLSv1\`, and \`TLSv1.1\` disabled.
- **AEAD Cipher Suites**: Configured Mozilla Intermediate ECDHE/GCM/CHACHA20 ciphers (\`ssl_prefer_server_ciphers off\`).
- **OWASP Security Headers**: \`Strict-Transport-Security\`, \`X-Frame-Options\`, \`X-Content-Type-Options\`, \`Referrer-Policy\`, \`Permissions-Policy\`, and \`Content-Security-Policy\`.
- **DoS & Rate Limiting**: Per-IP rate limit (\`${RATE_LIMIT}\`, burst \`${RATE_BURST}\`) and \`client_max_body_size ${CLIENT_MAX_BODY}\`.
- **Sensitive File Protection**: Blocks hidden dotfiles (\`/.git\`, \`/.env\`, \`/.htpasswd\`) and backup/SQL artifacts (\`.bak\`, \`.sql\`, \`.old\`, \`.swp\`).
EOF
}

generate_readme_content > "$SITE_README_MD"
generate_readme_content > "$LEGACY_README_TXT"
chmod 644 "$SITE_README_MD" "$LEGACY_README_TXT"

log "   ✅ Created ${SITE_README_MD} and ${LEGACY_README_TXT}."

printf "\n${C_GREEN}${C_BOLD}====================================================================${C_RESET}\n"
printf "${C_GREEN}${C_BOLD} ✅ NGINX SITE CONFIGURED SUCCESSFULLY: ${HOST_NAME}${C_RESET}\n"
printf "${C_GREEN}${C_BOLD}====================================================================${C_RESET}\n"
printf "  Site Mode       : %s\n" "$TARGET_DESC"
printf "  Primary URL     : %s\n" "$PRIMARY_URL"
printf "  HTTP / HTTPS    : %s / %s\n" "$HTTP_PORT" "$( [[ "$SSL_MODE" != "none" ]] && echo "$HTTPS_PORT" || echo "N/A" )"
printf "  Config File     : %s\n" "$SITE_CONF_PATH"
printf "  SSL Certificate : %s (Expires: %s)\n" "${SSL_CERT_FILE:-N/A}" "$CERT_EXPIRY_DATE"
printf "  SSL Private Key : %s\n" "${SSL_KEY_FILE:-N/A}"
printf "  Access Log      : %s\n" "$ACCESS_LOG_PATH"
printf "  Error Log       : %s\n" "$ERROR_LOG_PATH"
printf "  Site README     : %s\n" "$SITE_README_MD"
printf "  Summary README  : %s\n" "$LEGACY_README_TXT"
printf "  Test Command    : %s\n" "$CURL_HEADER_CMD"
printf "${C_GREEN}${C_BOLD}====================================================================${C_RESET}\n\n"

exit 0
