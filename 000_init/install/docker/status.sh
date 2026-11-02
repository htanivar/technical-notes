#!/usr/bin/env bash
# status.sh — Comprehensive Docker installation, service, socket, and runtime status reporter.
# Can be run as root or regular user.
# Exit codes:
#   0 = Docker installed and daemon responsive
#   1 = Docker installed but daemon stopped / unreachable
#   2 = Docker CLI not installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

OUTPUT_JSON=0
QUIET=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --json       Output status in JSON format
  -q, --quiet  Exit code only (0=healthy, 1=daemon down, 2=not installed)
  -h, --help   Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)      OUTPUT_JSON=1; shift ;;
    -q|--quiet)  QUIET=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           log_fatal "Unknown option: $1" 1 ;;
  esac
done

detect_os_and_arch
state_load 2>/dev/null || true

########################
# Gather Status Data
########################
CLI_INSTALLED=0
CLI_PATH=""
CLI_VERSION="not-installed"
DOCKERD_PATH=""
CONTAINERD_VERSION="not-installed"
RUNC_VERSION="not-installed"
COMPOSE_VERSION="not-installed"
BUILDX_VERSION="not-installed"

if command -v docker >/dev/null 2>&1; then
  CLI_INSTALLED=1
  CLI_PATH="$(command -v docker)"
  CLI_VERSION="$(docker --version 2>/dev/null | sed 's/Docker version //; s/,.*//' || echo 'unknown')"
fi

if command -v dockerd >/dev/null 2>&1; then
  DOCKERD_PATH="$(command -v dockerd)"
fi

if command -v containerd >/dev/null 2>&1; then
  CONTAINERD_VERSION="$(containerd --version 2>/dev/null | awk '{print $3}' || echo 'installed')"
fi

if command -v runc >/dev/null 2>&1; then
  RUNC_VERSION="$(runc --version 2>/dev/null | awk 'NR==1{print $3}' || echo 'installed')"
fi

if (( CLI_INSTALLED == 1 )); then
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION="$(docker compose version --short 2>/dev/null || echo 'plugin')"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_VERSION="$(docker-compose --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'standalone')"
  fi
  if docker buildx version >/dev/null 2>&1; then
    BUILDX_VERSION="$(docker buildx version 2>/dev/null | awk 'NR==1{print $2}' || echo 'plugin')"
  fi
fi

# Service states
DOCKER_SVC_ACTIVE="inactive"
DOCKER_SVC_ENABLED="disabled"
CONTAINERD_SVC_ACTIVE="inactive"
if service_is_active docker; then
  DOCKER_SVC_ACTIVE="active"
fi
if service_is_active containerd; then
  CONTAINERD_SVC_ACTIVE="active"
fi
if [[ "$INIT_SYSTEM" == "systemd" ]]; then
  DOCKER_SVC_ENABLED="$(systemctl is-enabled docker.service 2>/dev/null || echo 'disabled')"
fi

# Socket status
SOCK_PATH="/var/run/docker.sock"
SOCK_EXISTS=0
SOCK_PERMS="none"
SOCK_OWNER="none"
if [[ -S "$SOCK_PATH" ]]; then
  SOCK_EXISTS=1
  SOCK_PERMS="$(stat -c '%a' "$SOCK_PATH" 2>/dev/null || echo 'unknown')"
  SOCK_OWNER="$(stat -c '%U:%G' "$SOCK_PATH" 2>/dev/null || echo 'unknown')"
fi

# User & Group membership
CHECK_USER="${TARGET_USER:-$(detect_target_user)}"
USER_IN_DOCKER_GROUP=0
if id -nG "$CHECK_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
  USER_IN_DOCKER_GROUP=1
fi

# Daemon live info
DAEMON_RESPONSIVE=0
SERVER_VERSION="unreachable"
STORAGE_DRIVER="unknown"
CGROUP_DRIVER="unknown"
CGROUP_VERSION="unknown"
DOCKER_ROOT_DIR="/var/lib/docker"
CONTAINERS_TOTAL=0
CONTAINERS_RUNNING=0
CONTAINERS_PAUSED=0
CONTAINERS_STOPPED=0
IMAGES_COUNT=0

run_docker_info() {
  if docker info "$@" 2>/dev/null; then
    return 0
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo docker info "$@" 2>/dev/null
    return $?
  fi
  return 1
}

if (( CLI_INSTALLED == 1 )); then
  if INFO_OUT="$(run_docker_info --format '{{.ServerVersion}}|{{.Driver}}|{{.CgroupDriver}}|{{.CgroupVersion}}|{{.DockerRootDir}}|{{.Containers}}|{{.ContainersRunning}}|{{.ContainersPaused}}|{{.ContainersStopped}}|{{.Images}}')" && [[ -n "$INFO_OUT" ]]; then
    DAEMON_RESPONSIVE=1
    IFS='|' read -r SERVER_VERSION STORAGE_DRIVER CGROUP_DRIVER CGROUP_VERSION DOCKER_ROOT_DIR CONTAINERS_TOTAL CONTAINERS_RUNNING CONTAINERS_PAUSED CONTAINERS_STOPPED IMAGES_COUNT <<< "$INFO_OUT"
  fi
fi

# State & Cache status
PRE_STATE_PRESENT=0
[[ -f "$STATE_FILE" ]] && PRE_STATE_PRESENT=1
CACHED_PKG_COUNT=0
if [[ -d "$CACHE_DIR" ]]; then
  CACHED_PKG_COUNT="$(find "$CACHE_DIR" -maxdepth 2 -type f \( -name "*.deb" -o -name "*.rpm" -o -name "*.pkg.tar*" -o -name "*.apk" \) 2>/dev/null | wc -l | tr -d ' ')"
fi

# Determine overall health & exit code
OVERALL_STATUS="HEALTHY"
EXIT_CODE=0
if (( CLI_INSTALLED == 0 )); then
  OVERALL_STATUS="NOT_INSTALLED"
  EXIT_CODE=2
elif (( DAEMON_RESPONSIVE == 0 )); then
  OVERALL_STATUS="DEGRADED_DAEMON_DOWN"
  EXIT_CODE=1
fi

if (( QUIET == 1 )); then
  exit "$EXIT_CODE"
fi

if (( OUTPUT_JSON == 1 )); then
  cat <<EOF
{
  "overall_status": "${OVERALL_STATUS}",
  "os": {
    "id": "${OS_ID}",
    "pretty_name": "${OS_PRETTY_NAME}",
    "version_id": "${OS_VERSION_ID}",
    "pkg_family": "${PKG_FAMILY}",
    "docker_distro": "${DOCKER_DISTRO}",
    "codename": "${CODENAME:-}",
    "arch": "${UNAME_ARCH}",
    "init_system": "${INIT_SYSTEM}",
    "is_wsl": ${IS_WSL},
    "is_container": ${IS_CONTAINER}
  },
  "binaries": {
    "cli_installed": ${CLI_INSTALLED},
    "cli_path": "${CLI_PATH}",
    "cli_version": "${CLI_VERSION}",
    "dockerd_path": "${DOCKERD_PATH}",
    "containerd_version": "${CONTAINERD_VERSION}",
    "runc_version": "${RUNC_VERSION}",
    "compose_version": "${COMPOSE_VERSION}",
    "buildx_version": "${BUILDX_VERSION}"
  },
  "services": {
    "docker_active": "${DOCKER_SVC_ACTIVE}",
    "docker_enabled": "${DOCKER_SVC_ENABLED}",
    "containerd_active": "${CONTAINERD_SVC_ACTIVE}"
  },
  "socket": {
    "path": "${SOCK_PATH}",
    "exists": ${SOCK_EXISTS},
    "permissions": "${SOCK_PERMS}",
    "owner": "${SOCK_OWNER}",
    "target_user": "${CHECK_USER}",
    "user_in_docker_group": ${USER_IN_DOCKER_GROUP}
  },
  "daemon": {
    "responsive": ${DAEMON_RESPONSIVE},
    "server_version": "${SERVER_VERSION}",
    "storage_driver": "${STORAGE_DRIVER}",
    "cgroup_driver": "${CGROUP_DRIVER}",
    "cgroup_version": "${CGROUP_VERSION}",
    "root_dir": "${DOCKER_ROOT_DIR}",
    "containers_total": ${CONTAINERS_TOTAL:-0},
    "containers_running": ${CONTAINERS_RUNNING:-0},
    "containers_paused": ${CONTAINERS_PAUSED:-0},
    "containers_stopped": ${CONTAINERS_STOPPED:-0},
    "images": ${IMAGES_COUNT:-0}
  },
  "installer_state": {
    "state_file": "${STATE_FILE}",
    "state_present": ${PRE_STATE_PRESENT},
    "cached_packages": ${CACHED_PKG_COUNT}
  }
}
EOF
  exit "$EXIT_CODE"
fi

########################
# Human-Readable Report
########################
STATUS_COLOR="$C_GREEN"
[[ "$OVERALL_STATUS" == "DEGRADED_DAEMON_DOWN" ]] && STATUS_COLOR="$C_YELLOW"
[[ "$OVERALL_STATUS" == "NOT_INSTALLED" ]] && STATUS_COLOR="$C_RED"

printf "\n${C_BOLD}==================== DOCKER STATUS REPORT ====================${C_RESET}\n"
printf "Overall Status   : ${STATUS_COLOR}${C_BOLD}%s${C_RESET}\n" "$OVERALL_STATUS"
printf "\n${C_CYAN}[Host & Environment]${C_RESET}\n"
printf "  OS / Distro    : %s (id=%s, family=%s)\n" "$OS_PRETTY_NAME" "$OS_ID" "$PKG_FAMILY"
printf "  Repo Mapping   : distro=%s codename=%s\n" "$DOCKER_DISTRO" "${CODENAME:-N/A}"
printf "  Architecture   : %s (kernel %s)\n" "$UNAME_ARCH" "$(uname -r)"
printf "  Init System    : %s (WSL=%s, Container=%s)\n" "$INIT_SYSTEM" "$IS_WSL" "$IS_CONTAINER"

printf "\n${C_CYAN}[Binaries & Plugins]${C_RESET}\n"
printf "  docker CLI     : %s %s\n" "$CLI_VERSION" "${CLI_PATH:+(${CLI_PATH})}"
printf "  dockerd        : %s\n" "${DOCKERD_PATH:-not-installed}"
printf "  containerd     : %s\n" "$CONTAINERD_VERSION"
printf "  runc           : %s\n" "$RUNC_VERSION"
printf "  docker compose : %s\n" "$COMPOSE_VERSION"
printf "  docker buildx  : %s\n" "$BUILDX_VERSION"

printf "\n${C_CYAN}[Services & Socket]${C_RESET}\n"
printf "  docker service : %s (enabled: %s)\n" "$DOCKER_SVC_ACTIVE" "$DOCKER_SVC_ENABLED"
printf "  containerd svc : %s\n" "$CONTAINERD_SVC_ACTIVE"
if (( SOCK_EXISTS == 1 )); then
  printf "  docker.sock    : present (%s, %s, mode %s)\n" "$SOCK_PATH" "$SOCK_OWNER" "$SOCK_PERMS"
else
  printf "  docker.sock    : ${C_RED}missing (%s)${C_RESET}\n" "$SOCK_PATH"
fi
printf "  Target User    : %s (in 'docker' group: %s)\n" "$CHECK_USER" "$( (( USER_IN_DOCKER_GROUP == 1 )) && echo 'yes' || echo 'NO' )"

printf "\n${C_CYAN}[Daemon Runtime]${C_RESET}\n"
if (( DAEMON_RESPONSIVE == 1 )); then
  printf "  Server Version : %s\n" "$SERVER_VERSION"
  printf "  Storage Driver : %s (root: %s)\n" "$STORAGE_DRIVER" "$DOCKER_ROOT_DIR"
  printf "  Cgroup Driver  : %s (v%s)\n" "$CGROUP_DRIVER" "$CGROUP_VERSION"
  printf "  Containers     : %s total (%s running, %s paused, %s stopped)\n" \
    "$CONTAINERS_TOTAL" "$CONTAINERS_RUNNING" "$CONTAINERS_PAUSED" "$CONTAINERS_STOPPED"
  printf "  Images         : %s\n" "$IMAGES_COUNT"
else
  printf "  Daemon Status  : ${C_RED}Unreachable / Not Running${C_RESET}\n"
  printf "  Next Step      : Run './diagnose.sh' or 'sudo ./diagnose.sh --fix'\n"
fi

printf "\n${C_CYAN}[Installer State]${C_RESET}\n"
printf "  State File     : %s (%s)\n" "$STATE_FILE" "$( (( PRE_STATE_PRESENT == 1 )) && echo 'present' || echo 'not created' )"
printf "  Cache Dir      : %s (%s cached package(s))\n" "$CACHE_DIR" "$CACHED_PKG_COUNT"
printf "${C_BOLD}==============================================================${C_RESET}\n\n"

exit "$EXIT_CODE"

