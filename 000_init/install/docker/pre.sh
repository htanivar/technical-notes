#!/usr/bin/env bash
# pre.sh — Prepare Linux host for Docker installation across multiple Linux flavours:
#   - Debian / Ubuntu / Raspbian / Armbian / Mint / Pop!_OS / Kali (apt)
#   - RHEL / CentOS / Rocky / AlmaLinux / Oracle / Fedora / Amazon Linux (dnf/yum)
#   - Arch / Manjaro / EndeavourOS (pacman)
#   - openSUSE / SLES (zypper)
#   - Alpine Linux (apk)
#
# Actions:
#   1. Probes OS, flavour, codename, architecture, and init system
#   2. Installs prerequisites & configures official Docker repository (with native distro fallback)
#   3. Pre-downloads packages & dependencies into /var/cache/docker-install
#   4. Creates 'docker' group and adds target user
#   5. Saves full state & SHA256 manifest to /var/lib/docker-install

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

require_root "$@"
mkdir -p "$LOG_DIR" "$CACHE_DIR" "$STATE_DIR"
setup_logging "pre.sh"

export DEBIAN_FRONTEND=noninteractive

########################
# 1. Detect OS & Arch
########################
detect_os_and_arch
log_info "Detected OS     : ${OS_PRETTY_NAME} (id=${OS_ID}, family=${PKG_FAMILY})"
log_info "Repo mapping    : distro=${DOCKER_DISTRO} codename=${CODENAME:-N/A} arch=${UNAME_ARCH} (deb=${DEB_ARCH}, rpm=${RPM_ARCH})"
log_info "Init system     : ${INIT_SYSTEM} (wsl=${IS_WSL}, container=${IS_CONTAINER})"

init_state_file
state_set LOG_DIR "$LOG_DIR"
state_set CACHE_DIR "$CACHE_DIR"
state_set STATE_DIR "$STATE_DIR"
state_set STATE_FILE "$STATE_FILE"
state_set MANIFEST_FILE "$MANIFEST_FILE"
state_set KEYRING_DIR "$KEYRING_DIR"
state_set REPO_DIR "$APT_REPO_DIR"
state_set YUM_REPO_DIR "$YUM_REPO_DIR"
state_set OS_ID "$OS_ID"
state_set OS_LIKE "$OS_LIKE"
state_set OS_VERSION_ID "$OS_VERSION_ID"
state_set PKG_FAMILY "$PKG_FAMILY"
state_set BASE_ID "$DOCKER_DISTRO"
state_set DOCKER_DISTRO "$DOCKER_DISTRO"
state_set CODENAME "$CODENAME"
state_set UNAME_ARCH "$UNAME_ARCH"
state_set DEB_ARCH "$DEB_ARCH"
state_set RPM_ARCH "$RPM_ARCH"
state_set INIT_SYSTEM "$INIT_SYSTEM"
state_set PRE_LOG "${CURRENT_LOG_FILE:-}"

########################
# 2. Network Sanity Check
########################
log_step "Checking network & DNS resolution..."
NET_OK=0
if getent hosts download.docker.com >/dev/null 2>&1 || ping -c 1 -W 3 download.docker.com >/dev/null 2>&1; then
  log_ok "DNS resolves download.docker.com"
  NET_OK=1
else
  log_warn "Cannot resolve download.docker.com (will attempt mirrors/cached packages or distro repositories)"
fi
state_set NET_OK "$NET_OK"

########################
# 3. Family-Specific Prep & Package Caching
########################
DOWNLOADED_PKGS=()
INSTALL_SOURCE="unknown"
DOCKER_KEYRING="${KEYRING_DIR}/docker.gpg"
DOCKER_LIST="${APT_REPO_DIR}/docker.list"
DOCKER_YUM_REPO="${YUM_REPO_DIR}/docker-ce.repo"

prep_apt() {
  mkdir -p "$KEYRING_DIR" "$APT_REPO_DIR" "${CACHE_DIR}/partial"

  log_step "Updating APT and installing prerequisites..."
  # Remove any previously broken docker.list before initial apt-get update
  if [[ -f "$DOCKER_LIST" ]] && ! apt-get update -y >/dev/null 2>&1; then
    log_warn "Existing $DOCKER_LIST caused apt-get update failure; resetting it..."
    rm -f "$DOCKER_LIST"
  fi
  apt-get update -y || log_warn "apt-get update returned non-zero; continuing..."
  apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release apt-transport-https xz-utils iptables procps || true
  if [[ "$INIT_SYSTEM" != "systemd" ]]; then
    apt-get install -y --no-install-recommends cgroupfs-mount 2>/dev/null || true
    ensure_cgroups_mounted || true
  fi
  update-ca-certificates 2>/dev/null || true

  local use_official_ce=0
  if [[ "$DOCKER_DISTRO" =~ ^(ubuntu|debian|raspbian)$ && "$DEB_ARCH" =~ ^(amd64|arm64|armhf|s390x|ppc64el)$ ]]; then
    log_step "Configuring official Docker APT repository for ${DOCKER_DISTRO} ${CODENAME} (${DEB_ARCH})..."
    local tmp_key="${DOCKER_KEYRING}.tmp.$$"
    if curl -fsSL --connect-timeout 15 --retry 3 "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" \
        | gpg --batch --yes --dearmor -o "$tmp_key" 2>/dev/null && [[ -s "$tmp_key" ]]; then
      mv -f "$tmp_key" "$DOCKER_KEYRING"
      chmod a+r "$DOCKER_KEYRING"
      log_ok "Keyring written to $DOCKER_KEYRING"
    else
      rm -f "$tmp_key"
      if [[ -s "$DOCKER_KEYRING" ]]; then
        log_warn "Could not refresh GPG key from download.docker.com; reusing existing $DOCKER_KEYRING"
      else
        log_warn "Failed to fetch Docker GPG key; will fall back to distro docker.io packages"
      fi
    fi

    if [[ -s "$DOCKER_KEYRING" ]]; then
      cat > "$DOCKER_LIST" <<EOF
deb [arch=${DEB_ARCH} signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/${DOCKER_DISTRO} ${CODENAME} stable
EOF
      chmod 644 "$DOCKER_LIST"
      state_set DOCKER_KEYRING "$DOCKER_KEYRING"
      state_set DOCKER_LIST "$DOCKER_LIST"

      log_step "Refreshing APT cache with Docker repository..."
      if apt-get update -y; then
        local ce_cand
        ce_cand="$(apt-cache policy docker-ce 2>/dev/null | awk '/Candidate:/ {print $2}')"
        if [[ -n "$ce_cand" && "$ce_cand" != "(none)" ]]; then
          use_official_ce=1
          log_ok "Docker CE candidate verified: docker-ce=${ce_cand}"
        else
          log_warn "docker-ce has no candidate for ${DOCKER_DISTRO}/${CODENAME} (${DEB_ARCH}); removing $DOCKER_LIST and falling back to distro docker.io"
          rm -f "$DOCKER_LIST"
          apt-get update -y || true
        fi
      else
        log_warn "apt-get update failed with Docker repo (${DOCKER_DISTRO}/${CODENAME}); removing $DOCKER_LIST and falling back to distro packages"
        rm -f "$DOCKER_LIST"
        apt-get update -y || true
      fi
    fi
  fi

  local target_pkgs=()
  if (( use_official_ce == 1 )); then
    INSTALL_SOURCE="docker-ce"
    for p in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras; do
      local cand
      cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')"
      if [[ -n "$cand" && "$cand" != "(none)" ]]; then
        target_pkgs+=("$p")
        DOWNLOADED_PKGS+=("${p}=${cand}")
      fi
    done
  else
    INSTALL_SOURCE="distro-docker.io"
    for p in docker.io containerd runc docker-compose-v2 docker-compose docker-buildx; do
      local cand
      cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')"
      if [[ -n "$cand" && "$cand" != "(none)" ]]; then
        target_pkgs+=("$p")
        DOWNLOADED_PKGS+=("${p}=${cand}")
      fi
    done
  fi

  if (( ${#target_pkgs[@]} == 0 )); then
    log_fatal "No Docker packages (neither docker-ce nor docker.io) found in APT repositories!" 2
  fi

  log_step "Caching .deb packages and dependencies into ${CACHE_DIR}..."
  rm -f "${CACHE_DIR}"/*.deb 2>/dev/null || true

  # Method 1: apt-get install --download-only resolves and downloads all required dependencies
  if apt-get install -y --download-only \
      -o Dir::Cache::archives="$CACHE_DIR" \
      "${target_pkgs[@]}"; then
    log_ok "Downloaded packages and dependencies via apt-get --download-only"
  else
    log_warn "apt-get --download-only had conflicts; falling back to direct apt-get download..."
  fi

  # Ensure every primary package .deb is present in CACHE_DIR
  pushd "$CACHE_DIR" >/dev/null
  for p in "${target_pkgs[@]}"; do
    if ! ls "${p}"_*.deb >/dev/null 2>&1; then
      log_info "Downloading primary package: ${p}..."
      apt-get download "$p" || log_warn "apt-get download failed for $p"
    fi
  done
  popd >/dev/null
}

prep_dnf_or_yum() {
  local mgr="$PKG_FAMILY"
  mkdir -p "$CACHE_DIR"

  log_step "Installing prerequisites via ${mgr}..."
  if [[ "$mgr" == "dnf" ]]; then
    dnf install -y curl ca-certificates dnf-plugins-core 2>/dev/null || true
  else
    yum install -y curl ca-certificates yum-utils 2>/dev/null || true
  fi

  local target_pkgs=()
  if [[ "$DOCKER_DISTRO" == "amzn" ]]; then
    INSTALL_SOURCE="amzn-native"
    target_pkgs=(docker)
    for opt_pkg in containerd docker-buildx-plugin docker-compose-plugin; do
      if $mgr info "$opt_pkg" >/dev/null 2>&1; then
        target_pkgs+=("$opt_pkg")
      fi
    done
  else
    local repo_url="https://download.docker.com/linux/${DOCKER_DISTRO}/docker-ce.repo"
    log_step "Configuring Docker RPM repo: ${repo_url}..."
    if curl -fsSL --connect-timeout 15 --retry 3 "$repo_url" -o "$DOCKER_YUM_REPO" && [[ -s "$DOCKER_YUM_REPO" ]]; then
      chmod 644 "$DOCKER_YUM_REPO"
      state_set DOCKER_YUM_REPO "$DOCKER_YUM_REPO"
      INSTALL_SOURCE="docker-ce"
      target_pkgs=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
    else
      log_warn "Could not download ${repo_url}; falling back to distro packages"
      rm -f "$DOCKER_YUM_REPO"
      INSTALL_SOURCE="distro-rpm"
      target_pkgs=(docker)
    fi
  fi

  log_step "Caching RPM packages into ${CACHE_DIR}..."
  rm -f "${CACHE_DIR}"/*.rpm 2>/dev/null || true
  if [[ "$mgr" == "dnf" ]]; then
    dnf install -y --downloadonly --downloaddir="$CACHE_DIR" --allowerasing "${target_pkgs[@]}" \
      || dnf download --resolve --alldeps --destdir="$CACHE_DIR" "${target_pkgs[@]}" \
      || log_warn "RPM pre-download incomplete; install_docker.sh will resolve online if needed"
  else
    yum install -y --downloadonly --downloaddir="$CACHE_DIR" "${target_pkgs[@]}" \
      || yumdownloader --resolve --destdir="$CACHE_DIR" "${target_pkgs[@]}" \
      || log_warn "RPM pre-download incomplete; install_docker.sh will resolve online if needed"
  fi

  for p in "${target_pkgs[@]}"; do
    DOWNLOADED_PKGS+=("$p")
  done
}

prep_pacman() {
  INSTALL_SOURCE="pacman-official"
  mkdir -p "$CACHE_DIR"
  log_step "Syncing pacman databases and caching Docker packages..."
  pacman -Sy --noconfirm
  local target_pkgs=(docker containerd runc docker-buildx docker-compose)
  pacman -Sw --noconfirm --cachedir "$CACHE_DIR" "${target_pkgs[@]}" \
    || log_warn "Some optional Arch packages could not be cached; will install directly"
  for p in "${target_pkgs[@]}"; do
    DOWNLOADED_PKGS+=("$p")
  done
}

prep_zypper() {
  INSTALL_SOURCE="zypper-official"
  mkdir -p "$CACHE_DIR"
  log_step "Refreshing zypper repositories and caching Docker packages..."
  zypper --non-interactive --gpg-auto-import-keys refresh || true
  local target_pkgs=(docker containerd docker-buildx docker-compose)
  zypper --non-interactive --pkg-cache-dir "$CACHE_DIR" install --download-only -y docker containerd \
    || log_warn "zypper download-only warning; install_docker.sh will handle installation"
  for p in "${target_pkgs[@]}"; do
    DOWNLOADED_PKGS+=("$p")
  done
}

prep_apk() {
  INSTALL_SOURCE="apk-community"
  mkdir -p "$CACHE_DIR"
  log_step "Ensuring Alpine community repository is enabled..."
  if [[ -f /etc/apk/repositories ]]; then
    if ! grep -Eq '^[^#].*/community' /etc/apk/repositories; then
      # Enable community repo matching main repo mirror & branch
      sed -i 's|^#\s*\(.*/community\)|\1|g' /etc/apk/repositories || true
      if ! grep -Eq '^[^#].*/community' /etc/apk/repositories; then
        local main_line
        main_line="$(grep -E '^[^#].*/main' /etc/apk/repositories | head -n1 || true)"
        if [[ -n "$main_line" ]]; then
          echo "${main_line%/main*}/community" >> /etc/apk/repositories
        fi
      fi
    fi
  fi
  apk update
  local target_pkgs=(docker docker-cli docker-cli-buildx docker-cli-compose containerd openrc)
  pushd "$CACHE_DIR" >/dev/null
  apk fetch --recursive -o "$CACHE_DIR" "${target_pkgs[@]}" 2>/dev/null \
    || apk fetch -o "$CACHE_DIR" docker containerd 2>/dev/null \
    || true
  popd >/dev/null
  for p in "${target_pkgs[@]}"; do
    DOWNLOADED_PKGS+=("$p")
  done
}

case "$PKG_FAMILY" in
  apt)      prep_apt ;;
  dnf|yum)  prep_dnf_or_yum ;;
  pacman)   prep_pacman ;;
  zypper)   prep_zypper ;;
  apk)      prep_apk ;;
  *)        log_fatal "Unsupported package manager family: ${PKG_FAMILY}" 2 ;;
esac

state_set INSTALL_SOURCE "$INSTALL_SOURCE"

########################
# 4. Build Manifest + Checksums
########################
log_step "Building artifact manifest at ${MANIFEST_FILE}..."
: > "$MANIFEST_FILE"
artifact_count=0
while IFS= read -r -d '' f; do
  sha256="$(sha256sum "$f" | awk '{print $1}')"
  size="$(stat -c%s "$f" 2>/dev/null || wc -c < "$f")"
  rel_name="$(basename "$f")"
  echo "${rel_name} sha256=${sha256} size=${size}" >> "$MANIFEST_FILE"
  ((artifact_count++)) || true
done < <(find "$CACHE_DIR" -maxdepth 3 -type f \( -name "*.deb" -o -name "*.rpm" -o -name "*.pkg.tar*" -o -name "*.apk" \) -print0 2>/dev/null)

chmod 644 "$MANIFEST_FILE"
log_ok "Manifest recorded ${artifact_count} package file(s)."

JOINED_PKGS="$(printf "%s " "${DOWNLOADED_PKGS[@]}" | sed 's/ *$//')"
state_set DOWNLOADED_PKGS "$JOINED_PKGS"
state_set ARTIFACT_COUNT "$artifact_count"

########################
# 5. Group & User Setup
########################
TARGET_USER="$(detect_target_user)"
DOCKER_GROUP_CREATED=0
USER_ADDED_TO_DOCKER=0

log_step "Configuring 'docker' group and user '${TARGET_USER}'..."
if getent group docker >/dev/null 2>&1; then
  log_ok "Group 'docker' already exists"
else
  if command -v groupadd >/dev/null 2>&1; then
    groupadd -f docker
  elif command -v addgroup >/dev/null 2>&1; then
    addgroup -S docker 2>/dev/null || addgroup docker
  fi
  DOCKER_GROUP_CREATED=1
  log_ok "Created group 'docker'"
fi

if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
  if id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    log_ok "User '${TARGET_USER}' is already in 'docker' group"
  else
    if command -v usermod >/dev/null 2>&1; then
      usermod -aG docker "$TARGET_USER"
    elif command -v addgroup >/dev/null 2>&1; then
      addgroup "$TARGET_USER" docker
    fi
    USER_ADDED_TO_DOCKER=1
    log_ok "Added user '${TARGET_USER}' to 'docker' group"
  fi
fi

state_set TARGET_USER "$TARGET_USER"
state_set DOCKER_GROUP_CREATED "$DOCKER_GROUP_CREATED"
state_set USER_ADDED_TO_DOCKER "$USER_ADDED_TO_DOCKER"
state_set PRE_COMPLETED_AT "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

chmod -R a+r "$CACHE_DIR" 2>/dev/null || true

########################
# 6. Summary
########################
echo
echo "==================== PRE-INSTALL SUMMARY ===================="
echo "OS / Flavour    : ${OS_PRETTY_NAME} (${PKG_FAMILY})"
echo "Architecture    : ${UNAME_ARCH} (deb=${DEB_ARCH}, rpm=${RPM_ARCH})"
echo "Install source  : ${INSTALL_SOURCE}"
echo "Cached files    : ${artifact_count} package(s) in ${CACHE_DIR}"
echo "Target packages : ${JOINED_PKGS}"
echo "Target user     : ${TARGET_USER}"
echo "State file      : ${STATE_FILE}"
echo "Manifest file   : ${MANIFEST_FILE}"
echo "Log file        : ${CURRENT_LOG_FILE:-N/A}"
echo "============================================================="
echo
log_ok "pre.sh completed successfully at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
