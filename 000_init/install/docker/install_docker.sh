#!/usr/bin/env bash
# install_docker.sh — Bulletproof multi-distro Docker Engine installer.
# - Automatically runs pre.sh if state.env or cached packages are missing (unless --no-auto-pre is set).
# - Supports apt (Debian/Ubuntu/Mint/Pop/Kali/Raspbian/Armbian), dnf/yum (RHEL/CentOS/Rocky/Alma/Fedora/Amazon),
#   pacman (Arch/Manjaro), zypper (openSUSE/SLES), and apk (Alpine).
# - Resolves package conflicts, starts services across systemd/openrc/sysvinit/direct daemon,
#   and includes self-healing startup recovery (stale PID cleanup, iptables-legacy fallback).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

AUTO_PRE=1
FORCE_PRE=0
VERIFY_CONTAINER=0

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") [OPTIONS]

Options:
  --force-pre          Always run pre.sh before installing
  --no-auto-pre        Do not automatically run pre.sh if state file is missing
  --verify-container   Run 'docker run --rm hello-world' post-install smoke test
  -h, --help           Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-pre)        FORCE_PRE=1; shift ;;
    --no-auto-pre)      AUTO_PRE=0; shift ;;
    --verify-container) VERIFY_CONTAINER=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  log_fatal "Unknown option: $1 (use --help for usage)" 1 ;;
  esac
done

require_root
mkdir -p "$LOG_DIR"
setup_logging "install_docker.sh"

export DEBIAN_FRONTEND=noninteractive

########################
# 1. Load State or Run pre.sh
########################
if (( FORCE_PRE == 1 )); then
  log_step "Running pre.sh (--force-pre specified)..."
  "${SCRIPT_DIR}/pre.sh"
elif [[ ! -f "$STATE_FILE" ]]; then
  if (( AUTO_PRE == 1 )); then
    log_warn "State file ($STATE_FILE) not found; automatically running pre.sh first..."
    "${SCRIPT_DIR}/pre.sh"
  else
    log_fatal "STATE_FILE not found: $STATE_FILE (run pre.sh first or omit --no-auto-pre)" 1
  fi
fi

state_load || log_fatal "Failed to load state file: $STATE_FILE" 1
detect_os_and_arch
state_set INSTALL_LOG "${CURRENT_LOG_FILE:-}"

########################
# 2. Install Packages by Distro Family
########################
install_apt() {
  shopt -s nullglob
  local deb_files=("$CACHE_DIR"/*.deb)

  if (( ${#deb_files[@]} == 0 )) && (( AUTO_PRE == 1 )); then
    log_warn "No cached .deb files found in ${CACHE_DIR}; running pre.sh to populate cache..."
    "${SCRIPT_DIR}/pre.sh"
    state_load || true
    deb_files=("$CACHE_DIR"/*.deb)
  fi

  local dpkg_opts=(
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confnew
  )

  # Determine whether we are installing docker-ce or distro docker.io
  local has_ce=0
  for f in "${deb_files[@]}"; do
    if [[ "$(basename "$f")" == docker-ce_* ]]; then
      has_ce=1
      break
    fi
  done

  if (( has_ce == 1 )) || [[ "${INSTALL_SOURCE:-}" == "docker-ce" ]]; then
    log_step "Removing conflicting legacy packages (if present) before installing Docker CE..."
    for conflict_pkg in podman-docker docker.io docker-doc docker-compose; do
      if dpkg -s "$conflict_pkg" >/dev/null 2>&1; then
        log_info "Removing conflicting package: ${conflict_pkg}"
        apt-get remove -y "$conflict_pkg" 2>/dev/null || dpkg --remove --force-depends "$conflict_pkg" 2>/dev/null || true
      fi
    done
  fi

  if (( ${#deb_files[@]} > 0 )); then
    log_step "Installing ${#deb_files[@]} cached .deb package(s) from ${CACHE_DIR}..."
    # Strategy A: Use apt-get install on local .deb files (handles dependency ordering + local/repo resolution)
    if apt-get install -y "${dpkg_opts[@]}" "${deb_files[@]}"; then
      log_ok "Installed cached .deb packages via apt-get."
    else
      log_warn "Direct apt-get install of .deb batch returned non-zero; applying ordered dpkg + apt-get -f install..."
      local order=(containerd.io docker-ce-cli docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras docker-ce docker.io)
      for p in "${order[@]}"; do
        local pkg_debs=("$CACHE_DIR"/${p}_*.deb)
        if (( ${#pkg_debs[@]} > 0 )); then
          log_info "dpkg -i ${pkg_debs[0]}"
          dpkg --force-confdef --force-confnew -i "${pkg_debs[0]}" || true
        fi
      done
      # Install any remaining .debs in cache
      dpkg --force-confdef --force-confnew -i "${deb_files[@]}" || true
      apt-get install -y "${dpkg_opts[@]}" -f
    fi
  else
    log_warn "No .deb files in ${CACHE_DIR}; attempting direct online installation via APT..."
    apt-get update -y || true
    if [[ -n "$(apt-cache policy docker-ce 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" {print $2}')" ]]; then
      apt-get install -y "${dpkg_opts[@]}" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
      apt-get install -y "${dpkg_opts[@]}" docker.io containerd runc
    fi
  fi
}

install_dnf_or_yum() {
  local mgr="$PKG_FAMILY"
  shopt -s nullglob
  local rpm_files=("$CACHE_DIR"/*.rpm)

  log_step "Installing Docker RPM packages via ${mgr}..."
  if (( ${#rpm_files[@]} > 0 )); then
    if [[ "$mgr" == "dnf" ]]; then
      dnf install -y --allowerasing "${rpm_files[@]}" \
        || dnf install -y --allowerasing --nobest "${rpm_files[@]}"
    else
      yum localinstall -y "${rpm_files[@]}" || yum install -y "${rpm_files[@]}"
    fi
  else
    if [[ "${INSTALL_SOURCE:-}" == "docker-ce" ]]; then
      if [[ "$mgr" == "dnf" ]]; then
        dnf install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      else
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      fi
    else
      $mgr install -y docker
    fi
  fi
}

install_pacman() {
  shopt -s nullglob
  local pkg_files=("$CACHE_DIR"/*.pkg.tar*)
  log_step "Installing Docker packages via pacman..."
  if (( ${#pkg_files[@]} > 0 )); then
    pacman -U --noconfirm --needed "${pkg_files[@]}" \
      || pacman -S --noconfirm --needed docker containerd runc docker-buildx docker-compose
  else
    pacman -S --noconfirm --needed docker containerd runc docker-buildx docker-compose
  fi
}

install_zypper() {
  log_step "Installing Docker packages via zypper..."
  zypper --non-interactive --pkg-cache-dir "$CACHE_DIR" install -y docker containerd \
    || zypper --non-interactive install -y docker
  for opt_pkg in docker-buildx docker-compose; do
    zypper --non-interactive --pkg-cache-dir "$CACHE_DIR" install -y "$opt_pkg" 2>/dev/null || true
  done
}

install_apk() {
  shopt -s nullglob
  local apk_files=("$CACHE_DIR"/*.apk)
  log_step "Installing Docker packages via apk..."
  if (( ${#apk_files[@]} > 0 )); then
    apk add --allow-untrusted "${apk_files[@]}" \
      || apk add docker docker-cli docker-cli-buildx docker-cli-compose containerd
  else
    apk add docker docker-cli docker-cli-buildx docker-cli-compose containerd \
      || apk add docker containerd
  fi
}

case "$PKG_FAMILY" in
  apt)      install_apt ;;
  dnf|yum)  install_dnf_or_yum ;;
  pacman)   install_pacman ;;
  zypper)   install_zypper ;;
  apk)      install_apk ;;
  *)        log_fatal "Unsupported package manager family: ${PKG_FAMILY}" 2 ;;
esac

########################
# 3. Verify Binary Presence
########################
if ! command -v docker >/dev/null 2>&1; then
  log_fatal "Docker CLI binary not found on PATH after package installation!" 3
fi
log_ok "Docker binary installed: $(command -v docker)"

########################
# 4. Ensure User/Group & Start Services
########################
TARGET_USER="${TARGET_USER:-$(detect_target_user)}"
if ! getent group docker >/dev/null 2>&1; then
  groupadd -f docker 2>/dev/null || addgroup docker 2>/dev/null || true
fi
if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
  if ! id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    usermod -aG docker "$TARGET_USER" 2>/dev/null || addgroup "$TARGET_USER" docker 2>/dev/null || true
  fi
fi

if ! ensure_docker_daemon_running; then
  log_warn "Docker daemon did not start cleanly; running diagnose.sh --fix..."
  if [[ -x "${SCRIPT_DIR}/diagnose.sh" ]]; then
    "${SCRIPT_DIR}/diagnose.sh" --fix || true
  fi
fi

# Ensure /var/run/docker.sock has group 'docker' rw permissions
if [[ -S /var/run/docker.sock ]] && getent group docker >/dev/null 2>&1; then
  chgrp docker /var/run/docker.sock 2>/dev/null || true
  chmod 660 /var/run/docker.sock 2>/dev/null || true
fi

########################
# 5. Post-Install Sanity & Optional Smoke Test
########################
log_step "Running post-install verification..."
DOCKER_VER="$(docker --version 2>/dev/null || echo 'unknown')"
log_ok "CLI Version     : ${DOCKER_VER}"

if docker compose version >/dev/null 2>&1; then
  log_ok "Compose Version : $(docker compose version --short 2>/dev/null || docker compose version)"
elif command -v docker-compose >/dev/null 2>&1; then
  log_ok "Compose Version : $(docker-compose --version 2>/dev/null || true)"
fi

if docker buildx version >/dev/null 2>&1; then
  log_ok "Buildx Version  : $(docker buildx version 2>/dev/null | head -n1)"
fi

if docker info >/dev/null 2>&1; then
  SERVER_VER="$(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo 'active')"
  STORAGE_DRV="$(docker info --format '{{.Driver}}' 2>/dev/null || echo 'unknown')"
  CGROUP_DRV="$(docker info --format '{{.CgroupDriver}} (v{{.CgroupVersion}})' 2>/dev/null || echo 'unknown')"
  log_ok "Daemon Server   : v${SERVER_VER} (storage=${STORAGE_DRV}, cgroup=${CGROUP_DRV})"
else
  log_err "Docker daemon is not responding to 'docker info'. Run './diagnose.sh' for details."
  exit 4
fi

if (( VERIFY_CONTAINER == 1 )); then
  log_step "Running container smoke test (hello-world)..."
  if docker run --rm hello-world; then
    log_ok "Container smoke test passed!"
  else
    log_warn "Container smoke test failed (check internet access to Docker Hub or run './diagnose.sh')"
  fi
fi

state_set DOCKER_VERSION "$DOCKER_VER"
state_set INSTALL_COMPLETED_AT "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

echo
echo "==================== INSTALL SUMMARY ===================="
echo "Status          : HEALTHY"
echo "Docker CLI      : ${DOCKER_VER}"
echo "Daemon Server   : v${SERVER_VER:-unknown} (${STORAGE_DRV:-unknown})"
echo "Target user     : ${TARGET_USER} (in 'docker' group; re-login or run 'newgrp docker' to apply)"
echo "Log file        : ${CURRENT_LOG_FILE:-N/A}"
echo "========================================================="
echo
log_ok "install_docker.sh completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
