#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)."
  exit 1
fi

log() {
  echo "[INFO] $1"
}

install_if_missing() {
  PKG="$1"
  if ! dpkg -s "$PKG" >/dev/null 2>&1; then
    log "Installing $PKG..."
    apt update -y
    apt install -y "$PKG"
  else
    log "$PKG already installed."
  fi
}

log "Checking required packages..."
install_if_missing certbot
install_if_missing python3-certbot-nginx

read -rp "Enter domain name (e.g., example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
  echo "Domain is required."
  exit 1
fi

read -rp "Enter email for Let's Encrypt notifications: " EMAIL
if [[ -z "$EMAIL" ]]; then
  echo "Email is required."
  exit 1
fi

read -rp "Redirect HTTP to HTTPS? (y/n) [y]: " REDIRECT
REDIRECT=${REDIRECT:-y}

if [[ "$REDIRECT" =~ ^[Yy]$ ]]; then
  REDIRECT_FLAG="--redirect"
else
  REDIRECT_FLAG="--no-redirect"
fi

log "Requesting certificate for $DOMAIN..."

certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  $REDIRECT_FLAG

log "Certificate setup completed for $DOMAIN."

log "Testing renewal..."
certbot renew --dry-run

log "Done."
