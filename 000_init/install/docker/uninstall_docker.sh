#!/usr/bin/env bash
# uninstall_docker.sh — Stop Docker services and remove Docker packages across Linux distributions.
# Supports optional --purge-data to also delete /var/lib/docker and /var/lib/containerd.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

PURGE_DATA=0

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") [OPTIONS]

Options:
  --purge-data   Also delete /var/lib/docker, /var/lib/containerd, and /etc/docker
  -h, --help     Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-data) PURGE_DATA=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            log_fatal "Unknown option: $1" 1 ;;
  esac
done

require_root "$@"
state_load 2>/dev/null || true
detect_os_and_arch
mkdir -p "$LOG_DIR"
setup_logging "uninstall_docker.sh"

export DEBIAN_FRONTEND=noninteractive

log_step "Stopping Docker and containerd services..."
service_stop docker
service_stop containerd
rm -f /var/run/docker.sock /var/run/docker.pid 2>/dev/null || true

log_step "Removing Docker packages via ${PKG_FAMILY}..."
case "$PKG_FAMILY" in
  apt)
    apt-get purge -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
      docker.io docker-doc docker-compose docker-compose-v2 docker-buildx containerd runc 2>/dev/null || true
    apt-get autoremove -y --purge 2>/dev/null || true
    ;;
  dnf)
    dnf remove -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
      docker containerd 2>/dev/null || true
    ;;
  yum)
    yum remove -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
      docker containerd 2>/dev/null || true
    ;;
  pacman)
    pacman -Rns --noconfirm docker docker-buildx docker-compose containerd runc 2>/dev/null \
      || pacman -R --noconfirm docker 2>/dev/null || true
    ;;
  zypper)
    zypper --non-interactive remove -y docker docker-buildx docker-compose containerd 2>/dev/null || true
    ;;
  apk)
    apk del docker docker-cli docker-cli-buildx docker-cli-compose containerd 2>/dev/null || true
    ;;
esac

if (( PURGE_DATA == 1 )); then
  log_step "Purging Docker data directories (--purge-data)..."
  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  log_ok "Removed /var/lib/docker, /var/lib/containerd, and /etc/docker"
else
  log_info "Preserved /var/lib/docker and /var/lib/containerd (pass --purge-data to wipe images/volumes)."
fi

log_ok "uninstall_docker.sh completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
