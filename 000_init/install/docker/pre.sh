#!/usr/bin/env bash
# pre.sh — Prep host for Docker (Debian/Ubuntu/Raspbian/Armbian; x86_64/arm64/armhf)
# - No installation here. Adds repo, fetches keys, downloads .debs for offline install.
# - Creates docker group and adds invoking user.
# - Persists state and logs for install_docker.sh & unpre.sh.

set -euo pipefail

########################
# Globals / Directories
########################
LOG_DIR="/var/log/docker-install"
CACHE_DIR="/var/cache/docker-install"          # where .deb files land
STATE_DIR="/var/lib/docker-install"
KEYRING_DIR="/etc/apt/keyrings"
REPO_DIR="/etc/apt/sources.list.d"

mkdir -p "$LOG_DIR" "$CACHE_DIR" "$STATE_DIR" "$KEYRING_DIR"

LOG_FILE="$LOG_DIR/pre.sh.log"
STATE_FILE="$STATE_DIR/state.env"
MANIFEST_FILE="$STATE_DIR/manifest.txt"

# begin logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[START] pre.sh $(date -u +'%Y-%m-%dT%H:%M:%SZ')"

##################
# Root required
##################
if [[ $EUID -ne 0 ]]; then
  echo "[FATAL] Run as root. Try: sudo $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

##################
# OS / Arch probe
##################
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "[FATAL] /etc/os-release missing; cannot detect distro."
  exit 1
fi

OS_ID="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"
OS_LIKE="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
CODENAME="${VERSION_CODENAME:-}"
[[ -z "$CODENAME" ]] && CODENAME="$(lsb_release -cs 2>/dev/null || true)"

# Normalize: treat raspbian as raspbian (Docker hosts a raspbian repo),
# armbian follows its base (debian/ubuntu) via ID_LIKE.
BASE_ID="$OS_ID"
if [[ "$OS_ID" == "armbian" ]]; then
  BASE_ID="$(echo "$OS_LIKE" | awk '{print $1}')"
  [[ -z "$BASE_ID" ]] && BASE_ID="debian"
fi
if [[ "$OS_ID" == "raspbian" ]]; then
  BASE_ID="raspbian"
fi
case "$BASE_ID" in
  debian|ubuntu|raspbian) ;;
  *) BASE_ID="debian";;
esac

UNAME_ARCH="$(uname -m)"
case "$UNAME_ARCH" in
  x86_64)  DEB_ARCH="amd64" ;;
  aarch64) DEB_ARCH="arm64" ;;
  armv7l)  DEB_ARCH="armhf" ;;
  armv6l)  DEB_ARCH="armhf" ;; # Pi Zero/1
  *) echo "[FATAL] Unsupported arch: $UNAME_ARCH"; exit 1 ;;
esac

echo "[INFO] OS_ID=$OS_ID BASE_ID=$BASE_ID CODENAME=$CODENAME ARCH=$DEB_ARCH"

#########################
# State helpers
#########################
touch "$STATE_FILE"
chmod 600 "$STATE_FILE"

state_set() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|g" "$STATE_FILE"
  else
    echo "${key}=\"${val}\"" >> "$STATE_FILE"
  fi
}

# Seed state
state_set LOG_DIR "$LOG_DIR"
state_set CACHE_DIR "$CACHE_DIR"
state_set STATE_DIR "$STATE_DIR"
state_set STATE_FILE "$STATE_FILE"
state_set MANIFEST_FILE "$MANIFEST_FILE"
state_set KEYRING_DIR "$KEYRING_DIR"
state_set REPO_DIR "$REPO_DIR"
state_set OS_ID "$OS_ID"
state_set BASE_ID "$BASE_ID"
state_set CODENAME "$CODENAME"
state_set DEB_ARCH "$DEB_ARCH"
state_set PRE_LOG "$LOG_FILE"

#########################
# Network sanity (best-effort)
#########################
echo "[STEP] Network sanity check..."
if getent hosts download.docker.com >/dev/null 2>&1; then
  echo "[OK] DNS resolves download.docker.com"
else
  echo "[WARN] DNS cannot resolve download.docker.com (will still try apt if cached/mirrored)"
fi

#########################
# Prerequisites
#########################
echo "[STEP] Update APT and install prerequisites..."
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg apt-transport-https xz-utils lsb-release apt-utils

update-ca-certificates || true

#########################
# Docker repo + keyring
#########################
DOCKER_KEYRING="$KEYRING_DIR/docker.gpg"
DOCKER_LIST="$REPO_DIR/docker.list"

# select upstream path
DOCKER_DISTRO="$BASE_ID"
# Some Armbian IDs claim ubuntu-like but use Debian codenames; keep what we probed.

echo "[STEP] Configure Docker APT repository for ${DOCKER_DISTRO} ${CODENAME} (${DEB_ARCH})..."
if [[ ! -s "$DOCKER_KEYRING" ]]; then
  curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" | gpg --dearmor -o "$DOCKER_KEYRING"
  chmod a+r "$DOCKER_KEYRING"
  echo "[OK] Keyring at $DOCKER_KEYRING"
else
  echo "[OK] Keyring already present at $DOCKER_KEYRING"
fi

cat > "$DOCKER_LIST" <<EOF
deb [arch=${DEB_ARCH} signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/${DOCKER_DISTRO} ${CODENAME} stable
EOF

chmod 644 "$DOCKER_LIST"
echo "[OK] Repo file at $DOCKER_LIST"

state_set DOCKER_KEYRING "$DOCKER_KEYRING"
state_set DOCKER_LIST "$DOCKER_LIST"

echo "[STEP] apt-get update (Docker repo)..."
if ! apt-get update -y; then
  echo "[WARN] apt-get update failed; continuing (might still resolve from base repos)"
fi

#########################
# Candidate verification
#########################
PKGS=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
echo "[STEP] Verify candidate availability..."
missing=0
available_list=()
for p in "${PKGS[@]}"; do
  cand="$(apt-cache policy "$p" | awk '/Candidate:/ {print $2}')"
  if [[ -n "$cand" && "$cand" != "(none)" ]]; then
    echo "  $p -> $cand"
    available_list+=("$p=$cand")
  else
    echo "  $p -> MISSING"
    ((missing++)) || true
  fi
done

# Fallback: if docker-ce missing but docker.io exists (Debian/Ubuntu), note it for manifest (not auto-download unless user wants CE path)
fallback_note=""
docker_io_cand="$(apt-cache policy docker.io | awk '/Candidate:/ {print $2}')"
if [[ "$missing" -gt 0 && -n "$docker_io_cand" && "$docker_io_cand" != "(none)" ]]; then
  fallback_note="(fallback available: docker.io=$docker_io_cand)"
  echo "  docker.io -> $docker_io_cand  ${fallback_note}"
fi

#########################
# Download artifacts
#########################
echo "[STEP] Download .deb packages to $CACHE_DIR ..."
pushd "$CACHE_DIR" >/dev/null

downloaded_pkgs=()
failed_pkgs=()

# Prefer official CE set if present; otherwise pull what exists among CE set.
for spec in "${available_list[@]}"; do
  pkg="${spec%%=*}"
  ver="${spec#*=}"
  echo "  downloading $pkg=$ver ..."
  if apt-get download "$pkg=$ver"; then
    downloaded_pkgs+=("$pkg=$ver")
  else
    echo "  [ERR] download failed: $pkg=$ver"
    failed_pkgs+=("$pkg=$ver")
  fi
done

# If CE completely missing but docker.io exists, download docker.io + containerd/cli equivalents from distro.
if [[ ${#downloaded_pkgs[@]} -eq 0 && -n "$docker_io_cand" && "$docker_io_cand" != "(none)" ]]; then
  echo "[STEP] CE not available; downloading distro docker.io stack..."
  # docker.io pulls containerd + runc via deps; still capture primary .deb
  if apt-get download "docker.io=$docker_io_cand"; then
    downloaded_pkgs+=("docker.io=$docker_io_cand")
  else
    echo "  [ERR] download failed: docker.io=$docker_io_cand"
    failed_pkgs+=("docker.io=$docker_io_cand")
  fi
fi

popd >/dev/null

if [[ ${#downloaded_pkgs[@]} -eq 0 ]]; then
  echo "[FATAL] No packages downloaded. Check repo/codename/arch. ${fallback_note}"
  exit 2
fi

#########################
# Manifest + checksums
#########################
echo "[STEP] Build manifest..."
: > "$MANIFEST_FILE"
pushd "$CACHE_DIR" >/dev/null
for f in *.deb; do
  [[ -e "$f" ]] || continue
  sha256="$(sha256sum "$f" | awk '{print $1}')"
  size="$(stat -c%s "$f")"
  echo "${f} sha256=${sha256} size=${size}" >> "$MANIFEST_FILE"
done
popd >/dev/null
chmod 644 "$MANIFEST_FILE"

# Save list of resolved packages to state
JOINED="$(printf "%s " "${downloaded_pkgs[@]}" | sed 's/ *$//')"
state_set DOWNLOADED_PKGS "$JOINED"
state_set FALLBACK_DOCKER_IO "${docker_io_cand:-}"

#########################
# Group/user setup
#########################
TARGET_USER="${SUDO_USER:-${USER}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  TARGET_USER="$(awk -F: '$3>=1000 && $1!="nobody"{print $1; exit}' /etc/passwd || true)"
  [[ -z "$TARGET_USER" ]] && TARGET_USER="root"
fi

DOCKER_GROUP_CREATED=0
USER_ADDED_TO_DOCKER=0

echo "[STEP] Ensure docker group and user membership..."
if getent group docker >/dev/null 2>&1; then
  echo "  group 'docker' exists"
else
  groupadd docker
  DOCKER_GROUP_CREATED=1
  echo "  created group 'docker'"
fi

if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx docker; then
  echo "  user '$TARGET_USER' already in docker group"
else
  usermod -aG docker "$TARGET_USER"
  USER_ADDED_TO_DOCKER=1
  echo "  added '$TARGET_USER' to docker group"
fi

state_set TARGET_USER "$TARGET_USER"
state_set DOCKER_GROUP_CREATED "$DOCKER_GROUP_CREATED"
state_set USER_ADDED_TO_DOCKER "$USER_ADDED_TO_DOCKER"

#########################
# Permissions
#########################
chown -R "$TARGET_USER:$TARGET_USER" "$CACHE_DIR" || true
chmod -R a+r "$CACHE_DIR"

#########################
# Summary
#########################
echo
echo "========== SUMMARY =========="
echo "Log file        : $LOG_FILE"
echo "State file      : $STATE_FILE"
echo "Manifest        : $MANIFEST_FILE"
echo "Cache dir       : $CACHE_DIR"
echo "Repo file       : $DOCKER_LIST"
echo "Keyring         : $DOCKER_KEYRING"
echo "Target user     : $TARGET_USER"
echo "Downloaded pkgs : $JOINED"
if [[ -n "${fallback_note}" ]]; then
  echo "Fallback        : $fallback_note"
fi
echo "============================="
echo
echo "[NEXT] Run install_docker.sh (reads $STATE_FILE and installs from $CACHE_DIR)."
echo "[CLEANUP] Later, unpre.sh should remove repo/keyring/cache and revert group/user using $STATE_FILE."
echo "[DONE] Completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
