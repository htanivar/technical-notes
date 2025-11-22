#!/usr/bin/env bash
# uninstall_docker.sh — Remove Docker packages and stop services.
set -euo pipefail

STATE_FILE="${STATE_FILE:-/var/lib/docker-install/state.env}"
if [[ -f "$STATE_FILE" ]]; then
  . "$STATE_FILE"
  LOG_BASE="${LOG_DIR:-/var/log/docker-install}"
else
  LOG_BASE="/var/log/docker-install"
fi

mkdir -p "$LOG_BASE"
LOG_FILE="${LOG_BASE}/uninstall_docker.sh.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[START] uninstall_docker.sh $(date -u +'%Y-%m-%dT%H:%M:%SZ')"

echo "[STEP] Stop Docker services..."
systemctl stop docker.service 2>/dev/null || true
systemctl stop containerd.service 2>/dev/null || true

echo "[STEP] Remove packages..."
apt-get purge -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin containerd.io 2>/dev/null || true
apt-get purge -y docker.io 2>/dev/null || true
apt-get autoremove -y --purge || true

echo "[STEP] Optional data cleanup (images/volumes)."
echo "       To wipe data: rm -rf /var/lib/docker /var/lib/containerd"

echo "[DONE] uninstall_docker.sh completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
