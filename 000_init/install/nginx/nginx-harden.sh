#!/usr/bin/env bash
#
# nginx-harden.sh - fix the nginx audit warnings (WARN-1 .. WARN-15) on Debian/Ubuntu
#
# Usage:
#   sudo ./nginx-harden.sh                                   # harden, self-signed cert on default server
#   sudo ./nginx-harden.sh --domain example.com --email me@example.com
#   sudo ./nginx-harden.sh --domain example.com --domain www.example.com --proxy http://127.0.0.1:1717
#
# Options:
#   --domain NAME     Real site (repeatable; first one is the cert name). Gets a Let's Encrypt cert.
#   --email ADDR      Email for Let's Encrypt (omit to register without email)
#   --root PATH       Static web root for the site (default /var/www/html)
#   --proxy URL       Reverse-proxy the site to URL instead of serving static files
#   --csp "POLICY"    Custom Content-Security-Policy (default is strict; see note in script)
#   --no-fail2ban     Skip fail2ban installation
#   --upgrade         Run apt update + upgrade (kernel/security updates)
#   --reboot          Reboot (in 1 minute) if /var/run/reboot-required exists
#   -y, --yes         Skip confirmation
#
set -uo pipefail
shopt -u patsub_replacement 2>/dev/null || true

DOMAINS=(); EMAIL=""; WEBROOT=/var/www/html; PROXY=""
DO_UPGRADE=0; DO_REBOOT=0; SKIP_F2B=0; ASSUME_YES=0
CSP="default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)       DOMAINS+=("${2:?--domain needs a value}"); shift 2 ;;
    --email)        EMAIL=${2:?--email needs a value}; shift 2 ;;
    --root)         WEBROOT=${2:?--root needs a value}; shift 2 ;;
    --proxy)        PROXY=${2:?--proxy needs a value}; shift 2 ;;
    --csp)          CSP=${2:?--csp needs a value}; shift 2 ;;
    --no-fail2ban)  SKIP_F2B=1; shift ;;
    --upgrade)      DO_UPGRADE=1; shift ;;
    --reboot)       DO_REBOOT=1; shift ;;
    -y|--yes)       ASSUME_YES=1; shift ;;
    -h|--help)      sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }
command -v apt-get >/dev/null || { echo "This script needs apt (Debian/Ubuntu)."; exit 1; }

for d in "${DOMAINS[@]}"; do
  [[ $d =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] || { echo "Invalid domain: $d"; exit 1; }
done
SERVER_NAMES="${DOMAINS[*]:-}"
PRIMARY="${DOMAINS[0]:-}"

step() { echo; echo "[$1] $2"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ------------------------------------------------------------ confirmation ---
echo "== nginx hardening =="
echo "Will: back up /etc/nginx, edit nginx.conf (comment out conflicting directives),"
echo "      add conf.d/00-security.conf + snippets, REPLACE sites-available/default."
if [[ -n $PRIMARY ]]; then
  if [[ -n $PROXY ]]; then echo "Site: $SERVER_NAMES (proxy -> $PROXY) + Let's Encrypt cert"
  else echo "Site: $SERVER_NAMES (static -> $WEBROOT) + Let's Encrypt cert"; fi
fi
(( SKIP_F2B )) || echo "Will install/configure fail2ban."
(( DO_UPGRADE )) && echo "Will run apt upgrade."
echo
if (( ! ASSUME_YES )); then
  read -r -p "Proceed? Type 'yes': " ans
  [[ $ans == yes ]] || { echo "Aborted."; exit 1; }
fi

# ------------------------------------------------- 1. packages and backup ---
step 1/9 "Installing packages and backing up /etc/nginx"
apt-get update -y
PKGS=(nginx openssl curl)
[[ -n $PRIMARY ]] && PKGS+=(certbot)
DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS[@]}" || die "package install failed"

BACKUP=/root/nginx-harden-backup-$(date +%Y%m%d-%H%M%S).tar.gz
tar -czf "$BACKUP" -C / etc/nginx || die "backup failed"
echo "Backup: $BACKUP"

rollback() {
  echo "Rolling back /etc/nginx from $BACKUP"
  rm -rf /etc/nginx && tar -xzf "$BACKUP" -C /
  nginx -t && { systemctl is-active --quiet nginx && systemctl reload nginx; }
}

apply() {   # test config; reload on success, roll back on failure
  if nginx -t; then
    systemctl enable nginx >/dev/null 2>&1
    if systemctl is-active --quiet nginx; then systemctl reload nginx; else systemctl start nginx; fi
  else
    rollback; die "nginx -t failed; original config restored"
  fi
}

NGX=/etc/nginx/nginx.conf
grep -Eq '^[[:space:]]*include[[:space:]]+/etc/nginx/conf\.d/\*\.conf;' "$NGX" \
  || die "nginx.conf does not include conf.d/*.conf inside http {}; add it and re-run"
grep -Eq '^[[:space:]]*include[[:space:]]+/etc/nginx/sites-enabled/\*;' "$NGX" \
  || die "nginx.conf does not include sites-enabled/*; add it and re-run"

# --------------------------------------- 2. neutralise conflicting directives
step 2/9 "Commenting out directives in nginx.conf that we set in conf.d"
for d in server_tokens ssl_protocols ssl_ciphers ssl_prefer_server_ciphers \
         ssl_session_cache ssl_session_timeout ssl_session_tickets; do
  sed -i -E "s|^([[:space:]]*)(${d}[[:space:]].*)\$|\1# \2  # moved to conf.d/00-security.conf|" "$NGX"
done

# --------------------------------------------- 3. http-level + snippets ------
step 3/9 "Writing conf.d/00-security.conf and snippets"
install -d /etc/nginx/conf.d /etc/nginx/snippets /etc/nginx/sites-available /etc/nginx/sites-enabled

# WARN-2 (server_tokens), WARN-3 (ssl_session_cache), WARN-11 (limit_req_zone)
cat > /etc/nginx/conf.d/00-security.conf <<'EOF'
# Managed by nginx-harden.sh (http-level settings)

# Hide nginx version                                         [WARN-2]
server_tokens off;

# TLS: modern protocols/ciphers, session cache               [WARN-3]
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# Request rate limiting zone (applied in snippets/security-server.conf)  [WARN-11]
limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
limit_req_status 429;

# Slow-client / oversized request protection
client_body_timeout   10s;
client_header_timeout 10s;
send_timeout          10s;
client_max_body_size  10m;
EOF

# WARN-4..9: security headers (shared snippet).
# NOTE: add_header inside a location{} block REPLACES inherited headers - re-include
# this snippet in any location that sets its own add_header.
# NOTE: the default CSP blocks inline scripts and third-party CDNs/fonts. Loosen with --csp.
cat > /etc/nginx/snippets/security-headers.conf <<'EOF'
# Managed by nginx-harden.sh
add_header Strict-Transport-Security "max-age=31536000" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Content-Security-Policy "@@CSP@@" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
EOF
_h=$(< /etc/nginx/snippets/security-headers.conf)
printf '%s\n' "${_h//@@CSP@@/$CSP}" > /etc/nginx/snippets/security-headers.conf

# WARN-12 (limit_req applied) + WARN-13 (block dotfiles)
cat > /etc/nginx/snippets/security-server.conf <<'EOF'
# Managed by nginx-harden.sh
limit_req zone=req_limit burst=20 nodelay;

# Block hidden files (.git, .env, .htpasswd ...) but allow /.well-known/
location ~ /\.(?!well-known).* {
    deny all;
    access_log off;
    log_not_found off;
}
EOF

# ------------------------------------------------- 4. sites and certificates
step 4/9 "Writing hardened default site (WARN-1, WARN-10)"

NGX_VER=$(nginx -v 2>&1 | sed -E 's|.*/([0-9.]+).*|\1|')
if [[ $(printf '%s\n' 1.25.1 "$NGX_VER" | sort -V | head -n1) == 1.25.1 ]]; then
  H2L=""; H2D="    http2 on;"
else
  H2L=" http2"; H2D=""
fi

IFS= read -r -d '' LOC_STATIC <<'EOF'
    root @@WEBROOT@@;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
EOF

IFS= read -r -d '' LOC_PROXY <<'EOF'
    location / {
        proxy_pass @@PROXY@@;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_hide_header X-Powered-By;
    }
EOF

if [[ -n $PROXY ]]; then LOCATION_BLOCK=$LOC_PROXY; else LOCATION_BLOCK=$LOC_STATIC; fi
if [[ -n $PRIMARY ]]; then DEFAULT_BODY="    return 444;   # unknown Host/SNI: drop connection"
else DEFAULT_BODY=$LOC_STATIC; fi

render() {
  local t; t=$(cat)
  t=${t//@@LOCATION@@/$LOCATION_BLOCK}
  t=${t//@@DEFAULT_BODY@@/$DEFAULT_BODY}
  t=${t//@@SERVER_NAMES@@/$SERVER_NAMES}
  t=${t//@@PRIMARY@@/$PRIMARY}
  t=${t//@@WEBROOT@@/$WEBROOT}
  t=${t//@@PROXY@@/$PROXY}
  t=${t//@@H2L@@/$H2L}
  t=${t//@@H2D@@/$H2D}
  printf '%s\n' "$t"
}

# Self-signed cert so the catch-all HTTPS server has ssl_certificate  [WARN-1]
CERT_DIR=/etc/ssl/nginx-default
if [[ ! -s $CERT_DIR/default.crt ]]; then
  mkdir -p "$CERT_DIR"
  openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -days 3650 \
    -subj "/CN=localhost" -keyout "$CERT_DIR/default.key" -out "$CERT_DIR/default.crt" 2>/dev/null \
    || die "failed to generate self-signed certificate"
  chmod 600 "$CERT_DIR/default.key"
fi

render > /etc/nginx/sites-available/default <<'EOF'
# Managed by nginx-harden.sh - catch-all server (direct IP / unknown hostnames)

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    include snippets/security-headers.conf;
    include snippets/security-server.conf;

    return 301 https://$host$request_uri;          # [WARN-10]
}

server {
    listen 443 ssl@@H2L@@ default_server;
    listen [::]:443 ssl@@H2L@@ default_server;
@@H2D@@
    server_name _;

    ssl_certificate     /etc/ssl/nginx-default/default.crt;
    ssl_certificate_key /etc/ssl/nginx-default/default.key;

    include snippets/security-headers.conf;
    include snippets/security-server.conf;

@@DEFAULT_BODY@@
}
EOF
ln -sfn /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

write_domain_http() {   # port 80 only: ACME challenge + redirect
  render > "/etc/nginx/sites-available/$PRIMARY.conf" <<'EOF'
# Managed by nginx-harden.sh
server {
    listen 80;
    listen [::]:80;
    server_name @@SERVER_NAMES@@;

    include snippets/security-headers.conf;
    include snippets/security-server.conf;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/certbot;
        default_type "text/plain";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
EOF
  ln -sfn "/etc/nginx/sites-available/$PRIMARY.conf" "/etc/nginx/sites-enabled/$PRIMARY.conf"
}

write_domain_full() {   # port 80 + 443 with the real cert
  { cat <<'EOF'
# Managed by nginx-harden.sh
server {
    listen 80;
    listen [::]:80;
    server_name @@SERVER_NAMES@@;

    include snippets/security-headers.conf;
    include snippets/security-server.conf;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/certbot;
        default_type "text/plain";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl@@H2L@@;
    listen [::]:443 ssl@@H2L@@;
@@H2D@@
    server_name @@SERVER_NAMES@@;

    ssl_certificate     /etc/letsencrypt/live/@@PRIMARY@@/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/@@PRIMARY@@/privkey.pem;

    access_log /var/log/nginx/@@PRIMARY@@.access.log;

    include snippets/security-headers.conf;
    include snippets/security-server.conf;

@@LOCATION@@
}
EOF
  } | render > "/etc/nginx/sites-available/$PRIMARY.conf"
  ln -sfn "/etc/nginx/sites-available/$PRIMARY.conf" "/etc/nginx/sites-enabled/$PRIMARY.conf"
}

[[ -n $PRIMARY ]] && write_domain_http

step 5/9 "Testing and applying configuration"
apply

# --------------------------------------------------- 6. Let's Encrypt cert --
step 6/9 "Let's Encrypt certificate"
if [[ -z $PRIMARY ]]; then
  echo "No --domain given: using self-signed cert on the default server."
  echo "Re-run with --domain example.com --email you@example.com to get a trusted cert."
else
  mkdir -p /var/www/certbot && chmod 755 /var/www/certbot
  if [[ -d /etc/letsencrypt/live/$PRIMARY ]]; then
    echo "Certificate for $PRIMARY already exists, reusing it."
    CERT_OK=1
  else
    CB=(certbot certonly --webroot -w /var/www/certbot --non-interactive --agree-tos)
    [[ -n $EMAIL ]] && CB+=(-m "$EMAIL") || CB+=(--register-unsafely-without-email)
    for d in "${DOMAINS[@]}"; do CB+=(-d "$d"); done
    if "${CB[@]}"; then CERT_OK=1; else CERT_OK=0; fi
  fi

  if (( CERT_OK )); then
    write_domain_full
    if nginx -t; then
      systemctl reload nginx
      mkdir -p /etc/letsencrypt/renewal-hooks/deploy
      printf '#!/bin/sh\nnginx -t && systemctl reload nginx\n' > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
      chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
      systemctl enable --now certbot.timer >/dev/null 2>&1 || true
      echo "HTTPS enabled for: $SERVER_NAMES (auto-renewal configured)"
    else
      echo "WARNING: HTTPS config failed validation; falling back to HTTP-only block."
      write_domain_http; nginx -t && systemctl reload nginx
    fi
  else
    echo "WARNING: certbot failed. Check that DNS for $SERVER_NAMES points to this server"
    echo "         and port 80 is reachable. HTTP->HTTPS redirect block is in place;"
    echo "         re-run this script after fixing DNS."
  fi
fi

# -------------------------------------------------------------- 7. fail2ban --
step 7/9 "fail2ban (WARN-14)"
if (( SKIP_F2B )); then
  echo "Skipped (--no-fail2ban)"
else
  DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban || echo "WARNING: fail2ban install failed"
  mkdir -p /var/log/nginx; touch /var/log/nginx/error.log

  MY_IP=""
  if [[ -n ${SSH_CLIENT:-} ]]; then MY_IP=${SSH_CLIENT%% *}
  else MY_IP=$(who -m 2>/dev/null | awk '{print $NF}' | tr -d '()'); fi
  [[ $MY_IP =~ ^[0-9a-fA-F:.]+$ ]] || MY_IP=""

  JL=/etc/fail2ban/jail.local
  if [[ ! -f $JL ]]; then
    cat > "$JL" <<EOF
# Managed by nginx-harden.sh
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 $MY_IP
bantime  = 1h
findtime = 10m
maxretry = 5
bantime.increment = true
bantime.factor    = 2
bantime.maxtime   = 1w

[sshd]
enabled = true
port    = ssh

[nginx-http-auth]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log

[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
maxretry = 2

[nginx-limit-req]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log
EOF
  elif ! grep -q '^\[nginx-limit-req\]' "$JL"; then
    cat >> "$JL" <<'EOF'

[nginx-limit-req]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log
EOF
  fi

  if fail2ban-client -t >/dev/null 2>&1; then
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl restart fail2ban
    echo "fail2ban active."
  else
    echo "WARNING: fail2ban config test failed; check $JL"
  fi
fi

# ---------------------------------------------- 8. updates and reboot -------
step 8/9 "System updates (WARN-15)"
if (( DO_UPGRADE )); then
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
else
  echo "Skipped (use --upgrade to apply pending updates)"
fi

REBOOT_PENDING=0
if [[ -f /var/run/reboot-required ]]; then
  REBOOT_PENDING=1
  echo "A reboot is required to finish applying kernel/security updates."
fi

# ------------------------------------------------------------- 9. verify ----
step 9/9 "Verification"
nginx -t
echo
echo "Response headers:"
{
  if [[ -n $PRIMARY && -f /etc/nginx/sites-enabled/$PRIMARY.conf && -d /etc/letsencrypt/live/$PRIMARY ]]; then
    curl -skI --max-time 10 --resolve "$PRIMARY:443:127.0.0.1" "https://$PRIMARY/"
  else
    curl -skI --max-time 10 https://127.0.0.1/
  fi
} | grep -iE '^(HTTP|server|strict-transport|x-frame|x-content-type|content-security|referrer-policy|permissions-policy)' || true

echo
echo "Done. Backup: $BACKUP"
echo "Restore with: sudo rm -rf /etc/nginx && sudo tar -xzf $BACKUP -C /"
echo "Re-run your audit tool to confirm the warnings are cleared."

if (( REBOOT_PENDING )); then
  if (( DO_REBOOT )); then
    echo "Rebooting in 1 minute (cancel with: sudo shutdown -c)"
    shutdown -r +1 "nginx-harden: rebooting to apply updates"
  else
    echo "Reboot when convenient:  sudo reboot   (or re-run with --reboot)"
  fi
fi