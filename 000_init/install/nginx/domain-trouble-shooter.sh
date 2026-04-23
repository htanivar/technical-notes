#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  if [[ -z "${SUDO_USER:-}" ]]; then
    echo "[ERROR] Run this script with sudo."
    echo "Example: sudo $0 config.env"
  else
    echo "[ERROR] Insufficient privileges."
  fi
  exit 1
fi

CONFIG_FILE="${1:-config.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

: "${DOMAIN:?Missing DOMAIN}"
: "${EMAIL:?Missing EMAIL}"
: "${APP_PORT:?Missing APP_PORT}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

echo "=== Domain Troubleshooter ==="
echo "Domain : $DOMAIN"
echo "Port   : $APP_PORT"
echo

# 1. DNS
echo "[CHECK] DNS resolution"

DNS_SERVER="1.1.1.1"

IPV4=$(dig @"$DNS_SERVER" +short A "$DOMAIN" | head -n1 || true)
IPV6=$(dig @"$DNS_SERVER" +short AAAA "$DOMAIN" | head -n1 || true)

if [[ -n "$IPV4" || -n "$IPV6" ]]; then
  [[ -n "$IPV4" ]] && pass "IPv4 resolves to $IPV4"
  [[ -n "$IPV6" ]] && pass "IPv6 resolves to $IPV6"
else
  fail "Domain does not resolve (no A/AAAA records via $DNS_SERVER)"
fi
echo

# 2. Nginx running
echo "[CHECK] Nginx status"
if systemctl is-active --quiet nginx; then
  pass "Nginx is running"
else
  fail "Nginx is NOT running"
fi
echo

# 3. Nginx config test
echo "[CHECK] Nginx config"
if nginx -t >/dev/null 2>&1; then
  pass "Config valid"
else
  fail "Config error"
fi
echo

# 4. Site enabled
echo "[CHECK] Site enabled"
if ls /etc/nginx/sites-enabled/ 2>/dev/null | grep -q "$DOMAIN"; then
  pass "Site enabled"
else
  warn "Site not enabled"
fi
echo

# 5. Ports
echo "[CHECK] Ports"
ss -tuln | grep -q ":80 " && pass "Port 80 OK" || fail "Port 80 NOT listening"
ss -tuln | grep -q ":443 " && pass "Port 443 OK" || warn "Port 443 NOT listening"
echo

# 6. Firewall
echo "[CHECK] Firewall"

if command -v ufw >/dev/null 2>&1; then
  STATUS=$(ufw status | head -n1)

  if echo "$STATUS" | grep -q "inactive"; then
    pass "Firewall inactive (no blocking)"
  else
    if ufw status | grep -E "80/tcp|443/tcp" >/dev/null; then
      pass "Firewall allows HTTP/HTTPS"
    else
      fail "Firewall active but ports 80/443 not allowed"
    fi
  fi
else
  warn "ufw not installed (cannot verify firewall)"
fi
echo

# 7. Backend
echo "[CHECK] Backend app"
if curl -s "http://127.0.0.1:$APP_PORT" >/dev/null; then
  pass "Backend responding"
else
  fail "Backend NOT responding"
fi
echo

# 8. HTTP
echo "[CHECK] HTTP"
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "http://$DOMAIN" || true)
[[ "$HTTP_CODE" =~ ^2|3 ]] && pass "HTTP OK ($HTTP_CODE)" || fail "HTTP failed ($HTTP_CODE)"
echo

# 9. HTTPS
echo "[CHECK] HTTPS"
HTTPS_CODE=$(curl -k -o /dev/null -s -w "%{http_code}" "https://$DOMAIN" || true)
[[ "$HTTPS_CODE" =~ ^2|3 ]] && pass "HTTPS OK ($HTTPS_CODE)" || warn "HTTPS failed ($HTTPS_CODE)"
echo

# 10. SSL
echo "[CHECK] SSL cert"
if command -v certbot >/dev/null 2>&1; then
  certbot certificates 2>/dev/null | grep -q "$DOMAIN" && pass "SSL exists" || warn "SSL missing"
else
  warn "certbot not installed"
fi
echo

echo "=== Done ==="