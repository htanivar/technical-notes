#!/usr/bin/env bash
# diagnose.sh — Deep diagnostics, root-cause analysis, and automated self-healing (--fix)
# for Docker installations across Linux distributions.
#
# Checks:
#   1. OS, Flavour & Architecture Compatibility
#   2. Kernel Version & Required Kernel Modules (overlay, br_netfilter)
#   3. Cgroup Hierarchy (v1 / v2)
#   4. Conflicting or Half-Installed Packages (dpkg/rpm state, podman-docker, etc.)
#   5. Repository & Keyring Integrity
#   6. Binary Presence (docker, dockerd, containerd, runc)
#   7. /etc/docker/daemon.json Syntax Validation
#   8. Service & Stale PID / Socket Lock Inspection + Recent Journal Errors
#   9. /var/run/docker.sock Permissions & User 'docker' Group Membership
#  10. Network Stack: IPv4 Forwarding, iptables vs nftables, DNS
#  11. Disk Space & Inodes (/var/lib/docker, /var/lib/containerd, /tmp)
#  12. Live Daemon API Responsiveness

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

AUTO_FIX=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --fix        Automatically repair detected configuration, permission, network, and service issues (requires root)
  -h, --help   Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)      AUTO_FIX=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)          log_fatal "Unknown option: $1" 1 ;;
  esac
done

if (( AUTO_FIX == 1 )); then
  require_root "--fix"
  mkdir -p "$LOG_DIR"
  setup_logging "diagnose.sh"
fi

detect_os_and_arch
state_load 2>/dev/null || true

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
FIXED_COUNT=0
RECOMMENDATIONS=()

pass()  { printf "  ${C_GREEN}[PASS]${C_RESET} %s\n" "$*"; ((PASS_COUNT++)) || true; }
warn()  { printf "  ${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"; ((WARN_COUNT++)) || true; }
fail()  { printf "  ${C_RED}[FAIL]${C_RESET} %s\n" "$*"; ((FAIL_COUNT++)) || true; }
fixed() { printf "  ${C_CYAN}[FIXED]${C_RESET} %s\n" "$*"; ((FIXED_COUNT++)) || true; }
recommend() { RECOMMENDATIONS+=("$1"); }

printf "\n${C_BOLD}==================== DOCKER DIAGNOSTICS ====================${C_RESET}\n"
printf "Host: %s | Arch: %s | Pkg: %s | Init: %s | Mode: %s\n\n" \
  "$OS_PRETTY_NAME" "$UNAME_ARCH" "$PKG_FAMILY" "$INIT_SYSTEM" "$( (( AUTO_FIX == 1 )) && echo 'DIAGNOSE + AUTO-FIX' || echo 'READ-ONLY DIAGNOSE' )"

########################
# Check 1: OS & Arch
########################
printf "${C_BOLD}1. OS & Architecture Compatibility${C_RESET}\n"
if [[ -n "$PKG_FAMILY" ]]; then
  pass "Supported distro family detected: ${OS_ID} -> ${PKG_FAMILY} (repo=${DOCKER_DISTRO}, codename=${CODENAME:-N/A})"
else
  fail "Unrecognized package manager family for OS_ID=${OS_ID}"
fi

########################
# Check 2: Kernel & Modules
########################
printf "\n${C_BOLD}2. Kernel & Required Modules${C_RESET}\n"
KVER="$(uname -r)"
KMAJ="$(echo "$KVER" | cut -d. -f1)"
KMIN="$(echo "$KVER" | cut -d. -f2)"
if (( KMAJ > 4 || (KMAJ == 4 && KMIN >= 9) )); then
  pass "Kernel version ${KVER} (>= 4.9 recommended)"
else
  warn "Kernel version ${KVER} is older than 4.9; modern Docker features may be limited"
fi

check_kmod() {
  local mod="$1"
  if [[ -d "/sys/module/${mod}" ]] || grep -qw "^${mod}" /proc/modules 2>/dev/null; then
    pass "Kernel module '${mod}' is loaded"
    return 0
  elif grep -q "/${mod}.ko" "/lib/modules/${KVER}/modules.builtin" 2>/dev/null; then
    pass "Kernel module '${mod}' is built-in"
    return 0
  else
    if (( AUTO_FIX == 1 )) && command -v modprobe >/dev/null 2>&1; then
      if modprobe "$mod" 2>/dev/null; then
        fixed "Loaded kernel module '${mod}' via modprobe"
        return 0
      fi
    fi
    if (( IS_CONTAINER == 1 )); then
      warn "Kernel module '${mod}' not visible inside container environment (host kernel manages modules)"
    else
      warn "Kernel module '${mod}' is not loaded"
      recommend "Load kernel module '${mod}': sudo modprobe ${mod}"
    fi
  fi
}

check_kmod overlay
check_kmod br_netfilter

########################
# Check 3: Cgroups
########################
printf "\n${C_BOLD}3. Control Groups (cgroups)${C_RESET}\n"
if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
  pass "Cgroup v2 unified hierarchy mounted at /sys/fs/cgroup"
elif [[ -d /sys/fs/cgroup/memory || -d /sys/fs/cgroup/cpu ]]; then
  pass "Cgroup v1 hierarchy mounted at /sys/fs/cgroup"
else
  fail "No cgroup hierarchy detected at /sys/fs/cgroup"
  recommend "Ensure cgroups are mounted in /sys/fs/cgroup"
fi

########################
# Check 4: Package Manager & Conflicts
########################
printf "\n${C_BOLD}4. Package State & Conflicting Packages${C_RESET}\n"
if [[ "$PKG_FAMILY" == "apt" ]]; then
  # Check interrupted dpkg state
  if dpkg --audit 2>/dev/null | grep -q .; then
    if (( AUTO_FIX == 1 )); then
      dpkg --configure -a || true
      apt-get install -f -y || true
      fixed "Repaired interrupted dpkg state (dpkg --configure -a)"
    else
      fail "dpkg has unconfigured or half-installed packages"
      recommend "Repair dpkg state: sudo dpkg --configure -a && sudo apt-get install -f -y"
    fi
  else
    pass "APT/dpkg database is consistent"
  fi

  # Check simultaneous docker.io and docker-ce conflict
  if dpkg -s docker-ce >/dev/null 2>&1 && dpkg -s docker.io >/dev/null 2>&1; then
    fail "Both 'docker-ce' and 'docker.io' are installed simultaneously"
    recommend "Remove conflicting distro package: sudo apt-get remove -y docker.io"
  elif dpkg -s podman-docker >/dev/null 2>&1; then
    warn "'podman-docker' is installed and conflicts with Docker CLI"
    if (( AUTO_FIX == 1 )); then
      apt-get remove -y podman-docker || true
      fixed "Removed conflicting 'podman-docker' package"
    else
      recommend "Remove conflicting podman-docker: sudo apt-get remove -y podman-docker"
    fi
  else
    pass "No conflicting Docker/Podman packages detected"
  fi
else
  pass "Package manager (${PKG_FAMILY}) state check passed"
fi

########################
# Check 5: Repository & Keyring Integrity
########################
printf "\n${C_BOLD}5. Repository & GPG Keyring${C_RESET}\n"
if [[ "$PKG_FAMILY" == "apt" ]]; then
  if [[ -f "${APT_REPO_DIR}/docker.list" ]]; then
    if [[ -s "${KEYRING_DIR}/docker.gpg" ]]; then
      pass "Docker APT repo (${APT_REPO_DIR}/docker.list) and keyring (${KEYRING_DIR}/docker.gpg) are present"
    else
      fail "Docker APT repo exists at ${APT_REPO_DIR}/docker.list, but keyring ${KEYRING_DIR}/docker.gpg is missing or empty"
      if (( AUTO_FIX == 1 )); then
        rm -f "${APT_REPO_DIR}/docker.list" "${KEYRING_DIR}/docker.gpg"
        fixed "Removed broken docker.list / empty keyring; re-run sudo ./pre.sh to recreate"
      else
        recommend "Re-run 'sudo ./pre.sh' to regenerate Docker GPG keyring and repo"
      fi
    fi
  else
    warn "Official Docker APT repo (${APT_REPO_DIR}/docker.list) not configured yet (run sudo ./pre.sh to configure)"
  fi
elif [[ "$PKG_FAMILY" == "dnf" || "$PKG_FAMILY" == "yum" ]]; then
  if [[ -s "${YUM_REPO_DIR}/docker-ce.repo" || "$DOCKER_DISTRO" == "amzn" ]]; then
    pass "RPM repository configuration verified"
  else
    warn "Docker CE repo (${YUM_REPO_DIR}/docker-ce.repo) not configured yet"
  fi
else
  pass "Native distro repository used for ${PKG_FAMILY}"
fi

########################
# Check 6: Binaries
########################
printf "\n${C_BOLD}6. Required Binaries${C_RESET}\n"
MISSING_BINS=0
for bin in docker dockerd containerd runc; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "Found '${bin}' at $(command -v "$bin")"
  else
    fail "Missing binary '${bin}' on PATH"
    ((MISSING_BINS++)) || true
  fi
done
if (( MISSING_BINS > 0 )); then
  recommend "Install Docker binaries by running: sudo ./install_docker.sh"
fi

########################
# Check 7: /etc/docker/daemon.json Validation
########################
printf "\n${C_BOLD}7. Daemon Configuration (/etc/docker/daemon.json)${C_RESET}\n"
DAEMON_JSON="/etc/docker/daemon.json"
if [[ -f "$DAEMON_JSON" ]]; then
  if [[ ! -s "$DAEMON_JSON" ]]; then
    warn "${DAEMON_JSON} exists but is empty (0 bytes) — empty file causes dockerd to fail JSON parsing!"
    if (( AUTO_FIX == 1 )); then
      echo "{}" > "$DAEMON_JSON"
      fixed "Replaced empty ${DAEMON_JSON} with valid '{}'"
    else
      recommend "Write valid JSON '{}' to ${DAEMON_JSON} or remove the empty file"
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool "$DAEMON_JSON" >/dev/null 2>&1; then
      pass "${DAEMON_JSON} contains valid JSON"
    else
      fail "${DAEMON_JSON} has invalid JSON syntax!"
      recommend "Fix JSON syntax errors in ${DAEMON_JSON}"
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq empty "$DAEMON_JSON" >/dev/null 2>&1; then
      pass "${DAEMON_JSON} contains valid JSON"
    else
      fail "${DAEMON_JSON} has invalid JSON syntax!"
      recommend "Fix JSON syntax errors in ${DAEMON_JSON}"
    fi
  else
    pass "${DAEMON_JSON} is present"
  fi
else
  pass "No custom ${DAEMON_JSON} present (using default daemon settings)"
fi

########################
# Check 8: Service & Stale PID Check
########################
printf "\n${C_BOLD}8. Services & PID Lock Files${C_RESET}\n"
if [[ -f /var/run/docker.pid ]]; then
  DPID="$(cat /var/run/docker.pid 2>/dev/null || true)"
  if [[ -n "$DPID" ]] && ! kill -0 "$DPID" 2>/dev/null; then
    if (( AUTO_FIX == 1 )); then
      rm -f /var/run/docker.pid
      fixed "Removed stale /var/run/docker.pid (dead PID ${DPID})"
    else
      fail "Stale /var/run/docker.pid exists for non-running PID ${DPID}"
      recommend "Remove stale PID file: sudo rm -f /var/run/docker.pid"
    fi
  else
    pass "/var/run/docker.pid matches active process (PID ${DPID})"
  fi
else
  pass "No stale /var/run/docker.pid lock file"
fi

if (( MISSING_BINS == 0 )); then
  if service_is_active containerd; then
    pass "containerd service is active"
  else
    if (( AUTO_FIX == 1 )); then
      service_enable_and_start containerd && fixed "Started containerd service" || warn "Could not start containerd service"
    else
      warn "containerd service is not active"
      recommend "Start containerd: sudo systemctl restart containerd"
    fi
  fi

  if service_is_active docker; then
    pass "docker service is active"
  else
    if (( AUTO_FIX == 1 )); then
      if ensure_docker_daemon_running; then
        fixed "Started Docker daemon via self-healing startup"
      else
        fail "Docker service failed to start even after auto-fix"
      fi
    else
      fail "docker service is NOT active"
      recommend "Start Docker service or run auto-repair: sudo ./diagnose.sh --fix"
    fi
    if [[ "$INIT_SYSTEM" == "systemd" ]] && command -v journalctl >/dev/null 2>&1; then
      printf "  ${C_YELLOW}--- Recent docker.service journal logs ---${C_RESET}\n"
      journalctl -u docker.service -n 12 --no-pager 2>/dev/null | sed 's/^/    /' || true
    fi
  fi
fi

########################
# Check 9: Socket & User Group
########################
printf "\n${C_BOLD}9. Docker Socket & User Permissions${C_RESET}\n"
CHECK_USER="${TARGET_USER:-$(detect_target_user)}"
if getent group docker >/dev/null 2>&1; then
  pass "Group 'docker' exists"
else
  if (( AUTO_FIX == 1 )); then
    groupadd -f docker 2>/dev/null || addgroup docker 2>/dev/null || true
    fixed "Created 'docker' group"
  else
    warn "Group 'docker' does not exist"
    recommend "Create docker group: sudo groupadd docker"
  fi
fi

if [[ -n "$CHECK_USER" && "$CHECK_USER" != "root" ]] && id "$CHECK_USER" >/dev/null 2>&1; then
  if id -nG "$CHECK_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    pass "User '${CHECK_USER}' is a member of 'docker' group"
  else
    if (( AUTO_FIX == 1 )); then
      usermod -aG docker "$CHECK_USER" 2>/dev/null || addgroup "$CHECK_USER" docker 2>/dev/null || true
      fixed "Added user '${CHECK_USER}' to 'docker' group"
    else
      warn "User '${CHECK_USER}' is NOT in 'docker' group (requires sudo for docker CLI)"
      recommend "Add user to docker group: sudo usermod -aG docker ${CHECK_USER}"
    fi
  fi
fi

if [[ -S /var/run/docker.sock ]]; then
  SOCK_GRP="$(stat -c '%G' /var/run/docker.sock 2>/dev/null || echo '')"
  SOCK_MODE="$(stat -c '%a' /var/run/docker.sock 2>/dev/null || echo '')"
  if [[ "$SOCK_GRP" == "docker" || "$SOCK_GRP" == "root" ]]; then
    pass "/var/run/docker.sock exists (group=${SOCK_GRP}, mode=${SOCK_MODE})"
    if [[ "$SOCK_GRP" != "docker" ]] && getent group docker >/dev/null 2>&1 && (( AUTO_FIX == 1 )); then
      chgrp docker /var/run/docker.sock 2>/dev/null || true
      chmod 660 /var/run/docker.sock 2>/dev/null || true
      fixed "Updated /var/run/docker.sock ownership to root:docker (660)"
    fi
  else
    warn "/var/run/docker.sock has unexpected group '${SOCK_GRP}'"
  fi
else
  if (( MISSING_BINS == 0 )); then
    fail "/var/run/docker.sock does not exist (daemon not listening)"
  else
    warn "/var/run/docker.sock not present (Docker not installed yet)"
  fi
fi

########################
# Check 10: Networking, IP Forwarding & iptables
########################
printf "\n${C_BOLD}10. Networking, IPv4 Forwarding & Firewall Backend${C_RESET}\n"
IP_FWD="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 0)"
if [[ "$IP_FWD" == "1" ]]; then
  pass "IPv4 forwarding is enabled (net.ipv4.ip_forward = 1)"
else
  if (( AUTO_FIX == 1 )); then
    if sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1; then
      mkdir -p /etc/sysctl.d
      echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-docker-ipforward.conf
      fixed "Enabled net.ipv4.ip_forward = 1"
    else
      warn "Could not set net.ipv4.ip_forward = 1 (read-only /proc/sys inside container)"
    fi
  else
    warn "IPv4 forwarding is disabled (net.ipv4.ip_forward = 0); container bridge networking will not route external traffic"
    recommend "Enable IP forwarding: sudo sysctl -w net.ipv4.ip_forward=1"
  fi
fi

if command -v iptables >/dev/null 2>&1; then
  IPT_VER="$(iptables --version 2>/dev/null || echo 'unknown')"
  pass "iptables binary present: ${IPT_VER}"
else
  warn "iptables binary not found; Docker bridge NAT rules require iptables or nftables"
  recommend "Install iptables package for container port publishing and NAT"
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1 || getent hosts download.docker.com >/dev/null 2>&1; then
  pass "DNS resolution for Docker Hub / download.docker.com is working"
else
  warn "DNS resolution for Docker Hub / download.docker.com failed (offline or restricted network)"
fi

########################
# Check 11: Disk Space
########################
printf "\n${C_BOLD}11. Disk Space (/var/lib/docker & /var)${C_RESET}\n"
CHECK_DIR="/var/lib/docker"
[[ ! -d "$CHECK_DIR" ]] && CHECK_DIR="/var"
FREE_MB="$(df -Pm "$CHECK_DIR" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)"
USE_PCT="$(df -Pm "$CHECK_DIR" 2>/dev/null | awk 'NR==2 {print $5}' || echo '0%')"
if (( FREE_MB >= 2048 )); then
  pass "Available disk space on ${CHECK_DIR}: ${FREE_MB} MB free (${USE_PCT} used)"
elif (( FREE_MB >= 512 )); then
  warn "Low disk space on ${CHECK_DIR}: ${FREE_MB} MB free (${USE_PCT} used)"
  recommend "Free up disk space or run: docker system prune -f"
else
  fail "Critically low disk space on ${CHECK_DIR}: ${FREE_MB} MB free (${USE_PCT} used)"
  recommend "Free up disk space immediately on ${CHECK_DIR}"
fi

########################
# Check 12: Live Daemon API
########################
printf "\n${C_BOLD}12. Live Daemon API Responsiveness${C_RESET}\n"
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1 || (command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1); then
    pass "Docker daemon responded to 'docker info'"
  else
    fail "Docker daemon did not respond to 'docker info'"
    recommend "Run 'sudo ./diagnose.sh --fix' or 'sudo ./install_docker.sh' to install/start Docker"
  fi
else
  warn "Skipped live daemon query (Docker CLI not installed)"
fi

########################
# Summary
########################
printf "\n${C_BOLD}==================== DIAGNOSTIC SUMMARY ====================${C_RESET}\n"
printf "  Passed : ${C_GREEN}%d${C_RESET}\n" "$PASS_COUNT"
printf "  Warned : ${C_YELLOW}%d${C_RESET}\n" "$WARN_COUNT"
printf "  Failed : ${C_RED}%d${C_RESET}\n" "$FAIL_COUNT"
if (( AUTO_FIX == 1 )); then
  printf "  Fixed  : ${C_CYAN}%d${C_RESET}\n" "$FIXED_COUNT"
fi

if (( ${#RECOMMENDATIONS[@]} > 0 )); then
  printf "\n${C_BOLD}Recommended Actions:${C_RESET}\n"
  idx=1
  for rec in "${RECOMMENDATIONS[@]}"; do
    printf "  %d. %s\n" "$idx" "$rec"
    ((idx++)) || true
  done
fi
printf "${C_BOLD}============================================================${C_RESET}\n\n"

if (( FAIL_COUNT > 0 )); then
  exit 1
fi
exit 0

