#!/usr/bin/env bash
# common.sh — Shared library for multi-distro Docker installation, status, and diagnostics.
# Self-sufficient helper sourced by pre.sh, install_docker.sh, status.sh, diagnose.sh,
# uninstall_docker.sh, unpre.sh, and docker-ctl.sh.

# Prevent multiple sourcing
[[ -n "${_DOCKER_INSTALL_COMMON_LOADED:-}" ]] && return 0
_DOCKER_INSTALL_COMMON_LOADED=1

# Ensure /usr/sbin and /sbin are always in PATH (Debian/RHEL non-root shells often omit /usr/sbin)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

########################
# Directories & Paths
########################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${LOG_DIR:-/var/log/docker-install}"
CACHE_DIR="${CACHE_DIR:-/var/cache/docker-install}"
STATE_DIR="${STATE_DIR:-/var/lib/docker-install}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/state.env}"
MANIFEST_FILE="${MANIFEST_FILE:-${STATE_DIR}/manifest.txt}"
KEYRING_DIR="${KEYRING_DIR:-/etc/apt/keyrings}"
APT_REPO_DIR="${APT_REPO_DIR:-/etc/apt/sources.list.d}"
YUM_REPO_DIR="${YUM_REPO_DIR:-/etc/yum.repos.d}"

########################
# Formatting & Logging
########################
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  C_RESET="\033[0m"
  C_BOLD="\033[1m"
  C_RED="\033[31m"
  C_GREEN="\033[32m"
  C_YELLOW="\033[33m"
  C_BLUE="\033[34m"
  C_CYAN="\033[36m"
else
  C_RESET=""
  C_BOLD=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_CYAN=""
fi

log_info()  { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$*"; }
log_step()  { printf "${C_CYAN}${C_BOLD}[STEP]${C_RESET}  %s\n" "$*"; }
log_ok()    { printf "${C_GREEN}[OK]${C_RESET}    %s\n" "$*"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$*" >&2; }
log_err()   { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$*" >&2; }
log_fatal() { printf "${C_RED}${C_BOLD}[FATAL]${C_RESET} %s\n" "$*" >&2; exit "${2:-1}"; }

setup_logging() {
  local script_name="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  if [[ -w "$LOG_DIR" ]]; then
    export CURRENT_LOG_FILE="${LOG_DIR}/${script_name}.log"
    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1
  else
    export CURRENT_LOG_FILE="/tmp/${script_name}.log"
    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1
  fi
  echo "=================================================================="
  echo "[START] ${script_name} at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "=================================================================="
}

########################
# Privilege Helpers
########################
require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log_fatal "Root privileges required. Please run with: sudo $0 $*" 1
  fi
}

is_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

detect_target_user() {
  local target="${SUDO_USER:-${USER:-}}"
  if [[ -z "$target" || "$target" == "root" ]]; then
    target="$(awk -F: '$3>=1000 && $1!="nobody" && $1!="nogroup"{print $1; exit}' /etc/passwd 2>/dev/null || true)"
    [[ -z "$target" ]] && target="root"
  fi
  echo "$target"
}

########################
# State File Helpers
########################
init_state_file() {
  mkdir -p "$STATE_DIR"
  touch "$STATE_FILE"
  chmod 600 "$STATE_FILE"
}

state_set() {
  local key="$1" val="${2:-}"
  mkdir -p "$(dirname "$STATE_FILE")"
  touch "$STATE_FILE"
  # Escape backslashes and double quotes for safe sourcing
  local escaped_val="${val//\\/\\\\}"
  escaped_val="${escaped_val//\"/\\\"}"
  if grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
    local tmp_file="${STATE_FILE}.tmp.$$"
    awk -v k="$key" -v v="$escaped_val" '
      BEGIN { FS="=" }
      $1 == k { print k "=\"" v "\""; next }
      { print $0 }
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
  else
    printf '%s="%s"\n' "$key" "$escaped_val" >> "$STATE_FILE"
  fi
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

state_load() {
  if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    . "$STATE_FILE"
    return 0
  fi
  return 1
}

########################
# Environment & Init Detection
########################
detect_init_system() {
  if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
  elif command -v rc-service >/dev/null 2>&1 && [[ -d /run/openrc || -f /etc/init.d/functions.sh ]]; then
    INIT_SYSTEM="openrc"
  elif command -v service >/dev/null 2>&1; then
    INIT_SYSTEM="sysvinit"
  else
    INIT_SYSTEM="none"
  fi
  export INIT_SYSTEM
}

detect_virt_env() {
  IS_WSL=0
  IS_CONTAINER=0
  if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    IS_WSL=1
  fi
  if [[ -f /.dockerenv || -f /run/.containerenv ]] || grep -qaE '(docker|lxc|containerd|kubepods)' /proc/1/cgroup 2>/dev/null; then
    IS_CONTAINER=1
  fi
  export IS_WSL IS_CONTAINER
}

########################
# Multi-Distro & Arch Detection
########################
# Sets:
#   OS_ID             - raw ID from /etc/os-release (e.g. ubuntu, debian, linuxmint, rocky, fedora, arch, opensuse-leap, alpine, amzn)
#   OS_LIKE           - raw ID_LIKE from /etc/os-release
#   OS_VERSION_ID     - VERSION_ID (e.g. 22.04, 12, 9.3, 2023)
#   OS_PRETTY_NAME    - PRETTY_NAME
#   PKG_FAMILY        - apt | dnf | yum | pacman | zypper | apk
#   DOCKER_DISTRO     - upstream Docker repo family (ubuntu | debian | raspbian | fedora | centos | rhel | none)
#   CODENAME          - normalized distro codename for apt repos (e.g. noble, jammy, bookworm, bullseye)
#   UNAME_ARCH        - uname -m (x86_64, aarch64, armv7l, s390x, ppc64le, riscv64)
#   DEB_ARCH          - amd64 | arm64 | armhf | s390x | ppc64el | riscv64
#   RPM_ARCH          - x86_64 | aarch64 | armhfp | s390x | ppc64le | riscv64
detect_os_and_arch() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
  elif [[ -r /usr/lib/os-release ]]; then
    # shellcheck disable=SC1091
    . /usr/lib/os-release
  else
    log_fatal "/etc/os-release not found; cannot detect Linux distribution." 1
  fi

  OS_ID="$(echo "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')"
  OS_LIKE="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
  OS_VERSION_ID="${VERSION_ID:-}"
  OS_PRETTY_NAME="${PRETTY_NAME:-${OS_ID}}"

  # Architecture detection
  UNAME_ARCH="$(uname -m)"
  case "$UNAME_ARCH" in
    x86_64|amd64)
      DEB_ARCH="amd64"
      RPM_ARCH="x86_64"
      ;;
    aarch64|arm64)
      DEB_ARCH="arm64"
      RPM_ARCH="aarch64"
      ;;
    armv7l|armv7|armhf)
      DEB_ARCH="armhf"
      RPM_ARCH="armhfp"
      ;;
    armv6l)
      DEB_ARCH="armhf"
      RPM_ARCH="armhfp"
      ;;
    s390x)
      DEB_ARCH="s390x"
      RPM_ARCH="s390x"
      ;;
    ppc64le)
      DEB_ARCH="ppc64el"
      RPM_ARCH="ppc64le"
      ;;
    riscv64)
      DEB_ARCH="riscv64"
      RPM_ARCH="riscv64"
      ;;
    *)
      log_fatal "Unsupported CPU architecture: ${UNAME_ARCH}" 1
      ;;
  esac

  # Package manager & family detection
  PKG_FAMILY=""
  DOCKER_DISTRO="none"
  CODENAME="${VERSION_CODENAME:-}"

  case "$OS_ID" in
    ubuntu|pop|neon|elementary|zorin|tuxedo)
      PKG_FAMILY="apt"
      DOCKER_DISTRO="ubuntu"
      CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
      ;;
    linuxmint)
      PKG_FAMILY="apt"
      if [[ -n "${DEBIAN_CODENAME:-}" ]]; then
        DOCKER_DISTRO="debian"
        CODENAME="$DEBIAN_CODENAME"
      else
        DOCKER_DISTRO="ubuntu"
        CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
      fi
      ;;
    debian|raspbian|kali|parrot|deepin|devuan|proxmox|pureos)
      PKG_FAMILY="apt"
      if [[ "$OS_ID" == "raspbian" || ( "$DEB_ARCH" == "armhf" && "$OS_ID" == "debian" && -f /etc/rpi-issue ) ]]; then
        DOCKER_DISTRO="raspbian"
      else
        DOCKER_DISTRO="debian"
      fi
      CODENAME="${DEBIAN_CODENAME:-${VERSION_CODENAME:-}}"
      ;;
    armbian)
      PKG_FAMILY="apt"
      CODENAME="${VERSION_CODENAME:-}"
      if [[ "$OS_LIKE" == *"ubuntu"* ]] || [[ "$CODENAME" =~ ^(noble|jammy|focal|bionic|oracular|plucky)$ ]]; then
        DOCKER_DISTRO="ubuntu"
      else
        DOCKER_DISTRO="debian"
      fi
      ;;
    fedora)
      PKG_FAMILY="dnf"
      DOCKER_DISTRO="fedora"
      ;;
    rhel|centos|rocky|almalinux|ol|eurolinux|cloudlinux|virtuozzo)
      if command -v dnf >/dev/null 2>&1; then
        PKG_FAMILY="dnf"
      else
        PKG_FAMILY="yum"
      fi
      DOCKER_DISTRO="centos"
      ;;
    amzn)
      if command -v dnf >/dev/null 2>&1; then
        PKG_FAMILY="dnf"
      else
        PKG_FAMILY="yum"
      fi
      DOCKER_DISTRO="amzn"
      ;;
    arch|manjaro|endeavouros|garuda|artix|cachyos)
      PKG_FAMILY="pacman"
      DOCKER_DISTRO="none"
      ;;
    opensuse*|sles|sled|suse)
      PKG_FAMILY="zypper"
      DOCKER_DISTRO="none"
      ;;
    alpine)
      PKG_FAMILY="apk"
      DOCKER_DISTRO="none"
      ;;
    *)
      # Fallback via ID_LIKE or installed package manager
      if [[ "$OS_LIKE" == *"ubuntu"* ]]; then
        PKG_FAMILY="apt"
        DOCKER_DISTRO="ubuntu"
        CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
      elif [[ "$OS_LIKE" == *"debian"* ]]; then
        PKG_FAMILY="apt"
        DOCKER_DISTRO="debian"
        CODENAME="${DEBIAN_CODENAME:-${VERSION_CODENAME:-}}"
      elif [[ "$OS_LIKE" == *"fedora"* ]]; then
        PKG_FAMILY="dnf"
        DOCKER_DISTRO="fedora"
      elif [[ "$OS_LIKE" == *"rhel"* || "$OS_LIKE" == *"centos"* ]]; then
        PKG_FAMILY="$(command -v dnf >/dev/null 2>&1 && echo dnf || echo yum)"
        DOCKER_DISTRO="centos"
      elif [[ "$OS_LIKE" == *"arch"* ]]; then
        PKG_FAMILY="pacman"
      elif [[ "$OS_LIKE" == *"suse"* ]]; then
        PKG_FAMILY="zypper"
      elif command -v apt-get >/dev/null 2>&1; then
        PKG_FAMILY="apt"
        DOCKER_DISTRO="debian"
      elif command -v dnf >/dev/null 2>&1; then
        PKG_FAMILY="dnf"
        DOCKER_DISTRO="centos"
      elif command -v yum >/dev/null 2>&1; then
        PKG_FAMILY="yum"
        DOCKER_DISTRO="centos"
      elif command -v pacman >/dev/null 2>&1; then
        PKG_FAMILY="pacman"
      elif command -v zypper >/dev/null 2>&1; then
        PKG_FAMILY="zypper"
      elif command -v apk >/dev/null 2>&1; then
        PKG_FAMILY="apk"
      else
        log_fatal "Unsupported Linux distribution: ID=${OS_ID} ID_LIKE=${OS_LIKE}" 1
      fi
      ;;
  esac

  # Normalize APT codenames for derivatives when UBUNTU_CODENAME/DEBIAN_CODENAME was not explicitly set
  if [[ "$PKG_FAMILY" == "apt" ]]; then
    [[ -z "$CODENAME" ]] && CODENAME="$(lsb_release -cs 2>/dev/null || true)"
    CODENAME="$(echo "$CODENAME" | tr '[:upper:]' '[:lower:]')"
    case "$CODENAME" in
      # Linux Mint 22.x -> Ubuntu 24.04 (noble)
      wilma|xia|zara)
        DOCKER_DISTRO="ubuntu"; CODENAME="noble" ;;
      # Linux Mint 21.x -> Ubuntu 22.04 (jammy)
      vanessa|vera|victoria|virginia)
        DOCKER_DISTRO="ubuntu"; CODENAME="jammy" ;;
      # Linux Mint 20.x -> Ubuntu 20.04 (focal)
      ulyana|ulyssa|uma|una)
        DOCKER_DISTRO="ubuntu"; CODENAME="focal" ;;
      # LMDE 6 -> Debian 12 (bookworm), LMDE 5 -> Debian 11 (bullseye)
      faye)
        DOCKER_DISTRO="debian"; CODENAME="bookworm" ;;
      elsie)
        DOCKER_DISTRO="debian"; CODENAME="bullseye" ;;
      # Kali / Parrot / Debian rolling/testing -> Debian bookworm stable repo
      kali-rolling|ara|lory|sid|unstable|testing|n/a|"")
        if [[ "$DOCKER_DISTRO" == "ubuntu" ]]; then
          # Map Ubuntu VERSION_ID if codename missing
          case "$OS_VERSION_ID" in
            24.04*) CODENAME="noble" ;;
            22.04*) CODENAME="jammy" ;;
            20.04*) CODENAME="focal" ;;
            *)      CODENAME="noble" ;;
          esac
        else
          DOCKER_DISTRO="debian"
          case "$OS_VERSION_ID" in
            13*) CODENAME="trixie" ;;
            11*) CODENAME="bullseye" ;;
            10*) CODENAME="buster" ;;
            *)   CODENAME="bookworm" ;;
          esac
        fi
        ;;
    esac
  fi

  detect_init_system
  detect_virt_env

  export OS_ID OS_LIKE OS_VERSION_ID OS_PRETTY_NAME PKG_FAMILY DOCKER_DISTRO CODENAME UNAME_ARCH DEB_ARCH RPM_ARCH
}

########################
# Cgroups & SysVinit Helpers
########################
cgroups_are_mounted() {
  [[ -f /sys/fs/cgroup/cgroup.controllers || -d /sys/fs/cgroup/memory || -d /sys/fs/cgroup/cpu || -d /sys/fs/cgroup/pids ]]
}

ensure_cgroups_mounted() {
  if cgroups_are_mounted; then
    return 0
  fi

  log_step "Mounting cgroup hierarchy at /sys/fs/cgroup..."
  mkdir -p /sys/fs/cgroup 2>/dev/null || true

  # Try cgroupfs-mount helper first if installed
  if command -v cgroupfs-mount >/dev/null 2>&1; then
    if cgroupfs-mount 2>/dev/null && cgroups_are_mounted; then
      log_ok "Mounted cgroups via cgroupfs-mount"
      return 0
    fi
  fi

  # Prefer unified cgroup v2 when supported by kernel
  if grep -qw cgroup2 /proc/filesystems 2>/dev/null; then
    if mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null && cgroups_are_mounted; then
      log_ok "Mounted cgroup v2 unified hierarchy at /sys/fs/cgroup"
      # Persist in /etc/fstab on non-systemd hosts so reboots keep cgroups mounted
      if [[ "$INIT_SYSTEM" != "systemd" && -w /etc/fstab ]]; then
        if ! grep -Eq '^\s*[^#].*\s+/sys/fs/cgroup\s+' /etc/fstab 2>/dev/null; then
          echo "none /sys/fs/cgroup cgroup2 defaults 0 0" >> /etc/fstab
          log_info "Added cgroup2 mount entry to /etc/fstab for persistence across reboots"
        fi
      fi
      return 0
    fi
  fi

  # Fallback: mount cgroup v1 hierarchy (tmpfs + individual controllers)
  if grep -qw cgroup /proc/filesystems 2>/dev/null; then
    if ! mountpoint -q /sys/fs/cgroup 2>/dev/null; then
      mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup 2>/dev/null || true
    fi
    local subsys
    for subsys in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups 2>/dev/null); do
      mkdir -p "/sys/fs/cgroup/${subsys}" 2>/dev/null || true
      if ! mountpoint -q "/sys/fs/cgroup/${subsys}" 2>/dev/null; then
        mount -n -t cgroup -o "${subsys}" cgroup "/sys/fs/cgroup/${subsys}" 2>/dev/null || true
      fi
    done
    if cgroups_are_mounted; then
      log_ok "Mounted cgroup v1 controllers under /sys/fs/cgroup"
      return 0
    fi
  fi

  log_warn "Could not mount /sys/fs/cgroup (may be restricted by container/sandbox environment)"
  return 1
}

# Docker's containerd.io deb package only ships a systemd unit (/lib/systemd/system/containerd.service)
# and omits /etc/init.d/containerd, causing SysVinit hosts to fail 'service containerd start'.
ensure_sysvinit_scripts() {
  [[ "$INIT_SYSTEM" == "sysvinit" ]] || return 0
  if [[ ! -x /etc/init.d/containerd ]] && command -v containerd >/dev/null 2>&1; then
    log_step "Creating /etc/init.d/containerd SysVinit script for non-systemd host..."
    cat > /etc/init.d/containerd <<'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:           containerd
# Required-Start:     $syslog $remote_fs
# Required-Stop:      $syslog $remote_fs
# Default-Start:      2 3 4 5
# Default-Stop:       0 1 6
# Short-Description:  containerd container runtime
# Description:        An open and reliable container runtime
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
DAEMON=/usr/bin/containerd
PIDFILE=/var/run/containerd.pid
LOGFILE=/var/log/containerd.log

[ -x "$DAEMON" ] || exit 0

case "$1" in
  start)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
      echo "containerd is already running."
      exit 0
    fi
    echo "Starting containerd..."
    mkdir -p /run/containerd
    start-stop-daemon --start --background --no-close \
      --exec "$DAEMON" --pidfile "$PIDFILE" --make-pidfile \
      >> "$LOGFILE" 2>&1
    ;;
  stop)
    echo "Stopping containerd..."
    start-stop-daemon --stop --pidfile "$PIDFILE" --retry 5 || true
    rm -f "$PIDFILE"
    ;;
  restart|force-reload)
    "$0" stop
    "$0" start
    ;;
  status)
    if pgrep -x containerd >/dev/null 2>&1; then
      echo "containerd is running."
      exit 0
    else
      echo "containerd is stopped."
      exit 3
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac
EOF
    chmod 755 /etc/init.d/containerd
    if command -v update-rc.d >/dev/null 2>&1; then
      update-rc.d containerd defaults 2>/dev/null || true
    fi
    log_ok "Installed /etc/init.d/containerd"
  fi
}

########################
# Service Control Helpers
########################
service_enable_and_start() {
  local svc="$1"
  case "$INIT_SYSTEM" in
    systemd)
      systemctl daemon-reload 2>/dev/null || true
      systemctl reset-failed "${svc}.service" 2>/dev/null || true
      systemctl unmask "${svc}.service" 2>/dev/null || true
      systemctl enable "${svc}.service" 2>/dev/null || true
      systemctl restart "${svc}.service"
      ;;
    openrc)
      rc-update add "$svc" default 2>/dev/null || true
      rc-service "$svc" restart
      ;;
    sysvinit)
      ensure_sysvinit_scripts
      if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d "$svc" defaults 2>/dev/null || true
      elif command -v chkconfig >/dev/null 2>&1; then
        chkconfig "$svc" on 2>/dev/null || true
      fi
      service "$svc" restart
      ;;
    *)
      return 1
      ;;
  esac
}

service_stop() {
  local svc="$1"
  case "$INIT_SYSTEM" in
    systemd)
      systemctl stop "${svc}.socket" 2>/dev/null || true
      systemctl stop "${svc}.service" 2>/dev/null || true
      ;;
    openrc)
      rc-service "$svc" stop 2>/dev/null || true
      ;;
    sysvinit)
      service "$svc" stop 2>/dev/null || true
      ;;
  esac
  # Ensure underlying daemon process is stopped if init script missed it
  if [[ "$svc" == "docker" ]]; then
    pkill -x "dockerd" 2>/dev/null || true
  elif [[ "$svc" == "containerd" ]]; then
    pkill -x "containerd" 2>/dev/null || true
  fi
}

service_is_active() {
  local svc="$1"
  local bin_name="$svc"
  [[ "$svc" == "docker" ]] && bin_name="dockerd"

  case "$INIT_SYSTEM" in
    systemd)
      systemctl is-active --quiet "${svc}.service" 2>/dev/null && return 0
      ;;
    openrc)
      rc-service "$svc" status >/dev/null 2>&1 && return 0
      ;;
    sysvinit)
      service "$svc" status >/dev/null 2>&1 && return 0
      ;;
  esac

  # Process-level check (essential on sysvinit / non-root / direct daemon launch)
  pgrep -x "$bin_name" >/dev/null 2>&1
  return $?
}

########################
# Self-Healing Startup Helper
########################
# Mounts cgroups, cleans stale PID/socket files, checks iptables-nft vs iptables-legacy, and starts Docker.
ensure_docker_daemon_running() {
  log_step "Ensuring cgroups, containerd, and Docker daemon are running..."

  # 0. Ensure cgroups are mounted (critical on SysVinit / OpenRC / non-systemd systems!)
  ensure_cgroups_mounted || true
  ensure_sysvinit_scripts || true

  # 1. Clean up stale PID files if processes are not running
  local pid_file
  for pid_file in /var/run/docker.pid /var/run/docker-ssd.pid /var/run/containerd.pid /var/run/docker/containerd/containerd.pid; do
    if [[ -f "$pid_file" ]]; then
      local pid_val
      pid_val="$(cat "$pid_file" 2>/dev/null || true)"
      if [[ -z "$pid_val" ]] || ! kill -0 "$pid_val" 2>/dev/null; then
        log_warn "Removing stale PID file: ${pid_file} (PID ${pid_val:-empty} not running)"
        rm -f "$pid_file"
      fi
    fi
  done

  # Clean up orphaned /var/run/docker.sock if dockerd is not running
  if [[ -S /var/run/docker.sock ]] && ! pgrep -x dockerd >/dev/null 2>&1; then
    if [[ "$INIT_SYSTEM" != "systemd" ]] || ! systemctl is-active --quiet docker.socket 2>/dev/null; then
      log_warn "Removing orphaned /var/run/docker.sock (no running dockerd process)"
      rm -f /var/run/docker.sock
    fi
  fi

  # 2. Load kernel modules best-effort (skip if in unprivileged container)
  if command -v modprobe >/dev/null 2>&1; then
    modprobe overlay 2>/dev/null || true
    modprobe br_netfilter 2>/dev/null || true
  fi

  # 3. Try normal service startup when init system is available
  if [[ "$INIT_SYSTEM" != "none" ]]; then
    service_enable_and_start containerd || true
    if service_enable_and_start docker; then
      if wait_for_docker_sock 15; then
        log_ok "Docker service is active and responsive."
        return 0
      fi
    fi

    # 4. Self-heal attempt: check if iptables-nft is failing on this kernel
    log_warn "Docker service did not start cleanly on first attempt; running self-healing recovery..."
    local recent_logs=""
    if [[ "$INIT_SYSTEM" == "systemd" ]] && command -v journalctl >/dev/null 2>&1; then
      recent_logs="$(journalctl -u docker.service -n 25 --no-pager 2>/dev/null || true)"
    elif [[ -f /var/log/docker.log ]]; then
      recent_logs="$(tail -n 25 /var/log/docker.log 2>/dev/null || true)"
    fi

    if command -v update-alternatives >/dev/null 2>&1 && [[ -x /usr/sbin/iptables-legacy ]]; then
      if ! iptables -L >/dev/null 2>&1 || echo "$recent_logs" | grep -qiE "iptables|nf_tables|chain|nat"; then
        log_warn "Detected iptables/nftables incompatibility; switching to iptables-legacy..."
        update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
        update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
      fi
    fi

    # Reset failed units / stale sockets and retry
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
      systemctl reset-failed docker.service docker.socket containerd.service 2>/dev/null || true
      systemctl stop docker.socket 2>/dev/null || true
    else
      rm -f /var/run/docker.pid /var/run/docker-ssd.pid /var/run/docker.sock 2>/dev/null || true
    fi
    service_enable_and_start containerd || true
    if service_enable_and_start docker && wait_for_docker_sock 15; then
      log_ok "Docker service recovered and started after self-healing."
      return 0
    fi
  fi

  # 5. Fallback: Direct daemon launch (SysVinit init script failure, WSL, or container)
  log_warn "Init system (${INIT_SYSTEM}) could not start Docker unit cleanly; attempting direct daemon launch..."
  mkdir -p "$LOG_DIR"
  if ! pgrep -x containerd >/dev/null 2>&1 && command -v containerd >/dev/null 2>&1; then
    nohup containerd >"${LOG_DIR}/containerd-direct.log" 2>&1 &
    sleep 2
  fi
  if ! pgrep -x dockerd >/dev/null 2>&1 && command -v dockerd >/dev/null 2>&1; then
    rm -f /var/run/docker.pid /var/run/docker.sock 2>/dev/null || true
    nohup dockerd >"${LOG_DIR}/dockerd-direct.log" 2>&1 &
    if wait_for_docker_sock 15; then
      log_ok "dockerd started directly in background (log: ${LOG_DIR}/dockerd-direct.log)."
      return 0
    fi
    # Retry with --iptables=false --storage-driver=vfs if inside restricted environment
    if ! pgrep -x dockerd >/dev/null 2>&1; then
      log_warn "Retrying direct dockerd launch with --iptables=false --storage-driver=vfs..."
      rm -f /var/run/docker.pid /var/run/docker.sock 2>/dev/null || true
      nohup dockerd --iptables=false --storage-driver=vfs >"${LOG_DIR}/dockerd-direct.log" 2>&1 &
      if wait_for_docker_sock 15; then
        log_ok "dockerd started in compatibility mode (--iptables=false --storage-driver=vfs)."
        return 0
      fi
    fi
  fi

  log_err "Docker daemon failed to start. Run './diagnose.sh' for detailed root-cause analysis."
  return 1
}

wait_for_docker_sock() {
  local timeout="${1:-15}"
  local elapsed=0
  while (( elapsed < timeout )); do
    if [[ -S /var/run/docker.sock ]] && docker info >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    ((elapsed++)) || true
  done
  return 1
}
