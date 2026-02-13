#!/usr/bin/env bash

set -euo pipefail

DEFAULT_DOMAIN="rbot.jaganathan.co.uk"

read -rp "Enter domain [${DEFAULT_DOMAIN}]: " DOMAIN
DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}

read -rp "Enter port [443]: " PORT
PORT=${PORT:-443}

echo
echo "Fetching certificate from ${DOMAIN}:${PORT}..."
echo

CERT=$(echo | openssl s_client -connect "${DOMAIN}:${PORT}" -servername "${DOMAIN}" 2>/dev/null)

if [[ -z "$CERT" ]]; then
  echo "Failed to retrieve certificate."
  exit 1
fi

echo "$CERT" | openssl x509 -noout -text 2>/dev/null || {
  echo "Unable to parse certificate."
  exit 1
}

echo
echo "----- Summary -----"
echo "$CERT" | openssl x509 -noout -issuer -subject -dates -fingerprint
