#!/usr/bin/env bash
# install_docker.sh — Install Docker Engine from packages downloaded by pre.sh.
set -euo pipefail

STATE_FILE="${STATE_FILE:-/var/lib/docker-install/state.env}"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "[FATAL] STATE_FILE not found: $STATE_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$STATE_FILE"

LOG_FILE="${LOG_DIR}/install_docker.sh.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[START] install_docker.sh $(date -u +'%Y-%m-%dT%H:%M:%SZ')"

require() {
  local v="$1"
  if [[ -z "${!v:-}" ]]; then
    echo "[FATAL] Missing state var: $v"; exit 1
  fi
}
require LOG_DIR
require CACHE_DIR

if [[ ! -d "$CACHE_DIR" ]]; then
  echo "[FATAL] CACHE_DIR not found: $CACHE_DIR"
  exit 2
fi

shopt -s nullglob
deb_files=("$CACHE_DIR"/*.deb)
if (( ${#deb_files[@]} == 0 )); then
  echo "[FATAL] No .deb files found in $CACHE_DIR"
  exit 3
fi

echo "[STEP] Installing Docker packages from $CACHE_DIR ..."
order=(containerd.io docker-ce-cli docker-buildx-plugin docker-compose-plugin docker-ce)
present=()
for p in "${order[@]}"; do
  fcount=$(ls "$CACHE_DIR"/${p}_*.deb 2>/dev/null | wc -l || true)
  (( fcount > 0 )) && present+=("$p")
done

if (( ${#present[@]} > 0 )); then
  for p in "${present[@]}"; do
    echo "  installing $p ..."
    f=$(ls "$CACHE_DIR"/${p}_*.deb 2>/dev/null | head -n1 || true)
    dpkg -i "$f" || true
  done
  apt-get -y -o Dpkg::Options::=--force-confnew -f install
else
  io_pkg=$(ls "$CACHE_DIR"/docker.io_*.deb 2>/dev/null | head -n1 || true)
  if [[ -n "$io_pkg" ]]; then
    echo "  installing docker.io ..."
    dpkg -i "$io_pkg" || true
    apt-get -y -o Dpkg::Options::=--force-confnew -f install
  else
    echo "[FATAL] Could not find CE set or docker.io .debs in $CACHE_DIR"
    exit 4
  fi
fi

echo "[STEP] Enable and start services..."
systemctl daemon-reload || true
systemctl enable containerd.service docker.service || true
systemctl restart containerd.service docker.service || true

echo "[STEP] Post-install sanity..."
docker --version || true
docker info || true

echo "[DONE] install_docker.sh completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
