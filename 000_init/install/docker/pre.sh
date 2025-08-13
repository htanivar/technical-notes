#!/usr/bin/env bash
# pre.sh — prepare prerequisites and verify Docker package availability (no installation)
set -euo pipefail

LOG_DIR=/var/log/docker-install
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/pre.sh.log") 2>&1

if [[ $EUID -ne 0 ]]; then
  echo "Run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[STEP] Refresh APT & install prerequisite packages..."
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release apt-transport-https

. /etc/os-release || true

ARCH="$(dpkg --print-architecture)"                       # amd64 | arm64 | armhf | ...
ID_LOWER="$(echo "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')"
ID_LIKE_LOWER="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"

# Normalize distro for Docker repo selection
if [[ "$ID_LOWER" == "ubuntu" || "$ID_LIKE_LOWER" == *"ubuntu"* ]]; then
  DOCKER_DISTRO="ubuntu"
  CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
else
  DOCKER_DISTRO="debian"
  CODENAME="${VERSION_CODENAME:-}"
fi

CODENAME="${CODENAME:-bookworm}" # default/fallback

echo "[INFO] Detected: id=${ID_LOWER} (like=${ID_LIKE_LOWER}) distro=${DOCKER_DISTRO} codename=${CODENAME} arch=${ARCH}"

echo "[STEP] Configure Docker APT source (for verification only)..."
install -m 0755 -d /etc/apt/keyrings
if [[ ! -s /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_DISTRO} ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

echo "[STEP] Verify package availability (no install will be performed)..."

missing=0
check_pkg() {
  local pkg="$1"
  if apt-cache policy "$pkg" | awk '/Candidate:/ {exit ($2!="(none)")?0:1}'; then
    printf "  %-24s -> OK (candidate available)\n" "$pkg"
  else
    printf "  %-24s -> MISSING (no candidate)\n" "$pkg"
    missing=1
  fi
}

# Primary CE channel
check_pkg docker-ce
check_pkg docker-ce-cli
check_pkg containerd.io
check_pkg docker-buildx-plugin
check_pkg docker-compose-plugin

# If CE not available on this platform, check distro fallback (docker.io)
fallback_note=
if [[ $missing -eq 1 ]]; then
  echo "[INFO] Checking distro repository fallback (docker.io)..."
  apt-get update >/dev/null 2>&1 || true
  if apt-cache policy docker.io | awk '/Candidate:/ {exit ($2!="(none)")?0:1}'; then
    echo "  docker.io               -> OK (fallback available in distro repo)"
    fallback_note="(Fallback available via distro package: docker.io)"
    missing=0  # consider prerequisites satisfied if docker.io exists
  else
    echo "  docker.io               -> MISSING (no candidate)"
  fi
fi

echo
if [[ $missing -eq 0 ]]; then
  echo "[RESULT] READY — Prerequisites installed and Docker packages are resolvable ${fallback_note}"
  echo "[NEXT] You can proceed with installation when ready."
  exit 0
else
  echo "[RESULT] NOT READY — No Docker packages available for ${DOCKER_DISTRO} ${CODENAME} on ${ARCH}."
  echo "        Verify repo/codename/arch or choose a supported combination."
  exit 2
fi
