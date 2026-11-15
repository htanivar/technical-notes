#!/usr/bin/env bash
# caddy.sh - install and manage Caddy as a reverse proxy on (almost) any Linux.
#
# Supports: Debian/Ubuntu family (apt), Fedora/RHEL/Rocky/Alma/CentOS/Amazon (dnf/yum),
#           Arch/Manjaro (pacman), Alpine (apk), openSUSE/SLES (zypper), and any other
#           x86_64/arm/arm64/... Linux via the official static binary.
# Init:     systemd, OpenRC, or none (WSL1, containers) - falls back to a background process.
#
# Usage: ./caddy.sh [-y] <command> [args]      (run ./caddy.sh help)

# --- bootstrap: need bash (Alpine ships without it) ---------------------------
if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then exec bash "$0" "$@"; fi
  echo "This script needs bash. On Alpine: apk add bash" >&2
  exit 1
fi

set -euo pipefail
shopt -s nullglob

# --- settings -----------------------------------------------------------------
CADDY_DIR="${CADDY_DIR:-/etc/caddy}"
CADDYFILE="$CADDY_DIR/Caddyfile"
SITES_DIR="$CADDY_DIR/sites"
METHOD_FILE="$CADDY_DIR/.install-method"     # "pkg" or "binary"
LOG_DIR="/var/log/caddy"
LOG_FILE="$LOG_DIR/caddy.log"                # used when there is no journald
PID_FILE="/run/caddy.pid"                    # used when there is no init system
SERVICE="caddy"

APT_KEYRING="/usr/share/keyrings/caddy-stable-archive-keyring.gpg"
APT_LIST="/etc/apt/sources.list.d/caddy-stable.list"

# Only used by `install` to seed an empty setup. After that, use: add / remove / list
DEFAULT_SITES=(
  "github.jaganathan.co.uk|localhost:3000"
  "jenkins.jaganathan.co.uk|localhost:8080"
)

ASSUME_YES=0

# --- output helpers -----------------------------------------------------------
if [[ -t 1 ]]; then G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; N=$'\e[0m'; else G=""; R=""; Y=""; N=""; fi
info() { echo "${G}==>${N} $*"; }
warn() { echo "${Y}!!${N} $*" >&2; }
err()  { echo "${R}ERROR:${N} $*" >&2; }

confirm() {
  [[ $ASSUME_YES -eq 1 ]] && return 0
  local ans
  read -r -p "$1 [y/N] " ans || return 1
  [[ "$ans" =~ ^[Yy]$ ]]
}

as_root() {
  if [[ $EUID -eq 0 ]]; then "$@"
  elif command -v sudo >/dev/null 2>&1; then sudo "$@"
  else err "This step needs root. Re-run as root or install sudo."; exit 1
  fi
}

# --- environment detection ----------------------------------------------------
OS_NAME="Linux"
if [[ -r /etc/os-release ]]; then
  OS_NAME="$( . /etc/os-release; echo "${PRETTY_NAME:-${ID:-Linux}}" )"
fi

PM="none"
for _pm in apt-get dnf yum pacman apk zypper; do
  if command -v "$_pm" >/dev/null 2>&1; then PM="$_pm"; break; fi
done

INIT="none"
if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1; then
  INIT="systemd"
elif command -v rc-service >/dev/null 2>&1 && [[ -d /run/openrc ]]; then
  INIT="openrc"
fi

is_wsl()       { grep -qi microsoft /proc/version 2>/dev/null; }
in_container() { [[ -f /.dockerenv ]] || grep -qaE 'docker|lxc|containerd' /proc/1/cgroup 2>/dev/null; }
is_installed() { command -v caddy >/dev/null 2>&1; }
caddy_bin()    { command -v caddy 2>/dev/null || echo /usr/local/bin/caddy; }
require_installed() { is_installed || { err "Caddy is not installed. Run: $0 install"; exit 1; }; }

install_method() {
  if [[ -r "$METHOD_FILE" ]]; then cat "$METHOD_FILE"
  elif [[ "$(caddy_bin)" == /usr/local/bin/caddy ]]; then echo binary
  else echo pkg
  fi
}

# --- package manager abstraction ----------------------------------------------
pm_install() {
  case "$PM" in
    apt-get) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf|yum) as_root "$PM" install -y "$@" ;;
    pacman)  as_root pacman -S --noconfirm --needed "$@" ;;
    apk)     as_root apk add --no-cache "$@" ;;
    zypper)  as_root zypper --non-interactive install "$@" ;;
    *)       return 1 ;;
  esac
}

pm_remove() {
  case "$PM" in
    apt-get) as_root apt-get purge -y "$@" && as_root apt-get autoremove -y ;;
    dnf|yum) as_root "$PM" remove -y "$@" ;;
    pacman)  as_root pacman -Rns --noconfirm "$@" ;;
    apk)     as_root apk del "$@" ;;
    zypper)  as_root zypper --non-interactive remove "$@" ;;
    *)       return 1 ;;
  esac
}

ensure_prereqs() {
  command -v curl >/dev/null 2>&1 && return 0
  info "Installing curl"
  if [[ "$PM" == apt-get ]]; then as_root apt-get update -y; fi
  pm_install curl ca-certificates || { err "curl is required. Install it and re-run."; exit 1; }
}

# --- service abstraction (systemd / openrc / none) ----------------------------
svc_enable() {
  case "$INIT" in
    systemd) as_root systemctl enable "$SERVICE" ;;
    openrc)  as_root rc-update add "$SERVICE" default ;;
    none)    warn "No init system: Caddy will NOT start automatically after reboot/restart." ;;
  esac
}

svc_disable() {
  case "$INIT" in
    systemd) as_root systemctl disable "$SERVICE" 2>/dev/null || true ;;
    openrc)  as_root rc-update del "$SERVICE" default 2>/dev/null || true ;;
  esac
}

svc_is_active() {
  case "$INIT" in
    systemd) systemctl is-active --quiet "$SERVICE" ;;
    openrc)  rc-service "$SERVICE" status >/dev/null 2>&1 ;;
    none)
      { command -v pgrep >/dev/null 2>&1 && pgrep -x caddy >/dev/null 2>&1; } ||
      { [[ -r "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; }
      ;;
  esac
}

svc_start() {
  case "$INIT" in
    systemd) as_root systemctl start "$SERVICE" ;;
    openrc)  as_root rc-service "$SERVICE" start ;;
    none)
      as_root mkdir -p "$LOG_DIR"
      as_root sh -c "nohup '$(caddy_bin)' run --config '$CADDYFILE' --adapter caddyfile --pidfile '$PID_FILE' >> '$LOG_FILE' 2>&1 &"
      ;;
  esac
}

svc_stop() {
  case "$INIT" in
    systemd) as_root systemctl stop "$SERVICE" ;;
    openrc)  as_root rc-service "$SERVICE" stop ;;
    none)    as_root "$(caddy_bin)" stop 2>/dev/null || { [[ -r "$PID_FILE" ]] && as_root kill "$(cat "$PID_FILE")"; } ;;
  esac
}

svc_reload() {
  case "$INIT" in
    systemd) as_root systemctl reload "$SERVICE" ;;
    openrc)  as_root rc-service "$SERVICE" reload 2>/dev/null || as_root "$(caddy_bin)" reload --config "$CADDYFILE" --adapter caddyfile ;;
    none)    as_root "$(caddy_bin)" reload --config "$CADDYFILE" --adapter caddyfile ;;
  esac
}

svc_restart() { svc_stop || true; sleep 1; svc_start; }

svc_status() {
  case "$INIT" in
    systemd) systemctl status "$SERVICE" --no-pager || true ;;
    openrc)  rc-service "$SERVICE" status || true ;;
    none)    if svc_is_active; then echo "caddy is running (no init system; started by caddy.sh)"; else echo "caddy is not running"; fi ;;
  esac
}

# --- config helpers -----------------------------------------------------------
validate_config() {
  local out
  if out=$(as_root "$(caddy_bin)" validate --config "$CADDYFILE" --adapter caddyfile 2>&1); then
    info "Caddyfile is valid"
    return 0
  fi
  err "Caddyfile is invalid:"
  echo "$out" >&2
  return 1
}

apply_changes() {
  if svc_is_active; then
    svc_reload && info "Caddy reloaded (no downtime)."
  else
    warn "Caddy is not running. Start it with: $0 start"
  fi
}

normalize_upstream() {
  local u="$1"
  if [[ "$u" =~ ^[0-9]+$ ]]; then echo "localhost:$u"; else echo "$u"; fi
}

valid_domain() { [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; }

write_site() {  # write_site <domain> <upstream>
  printf '%s {\n    reverse_proxy %s\n}\n' "$1" "$2" | as_root tee "$SITES_DIR/$1.caddy" >/dev/null
  as_root chmod 644 "$SITES_DIR/$1.caddy"
}

site_domains() {
  local f
  for f in "$CADDYFILE" "$SITES_DIR"/*.caddy; do
    [[ -r "$f" ]] || continue
    awk '/^[^[:space:]#}(][^{]*\{[[:space:]]*$/ { sub(/[[:space:]]*\{[[:space:]]*$/, ""); print }' "$f"
  done | sort -u
}

setup_config() {
  as_root mkdir -p "$SITES_DIR" "$LOG_DIR"
  as_root chmod 755 "$CADDY_DIR" "$SITES_DIR"
  if id caddy >/dev/null 2>&1; then as_root chown caddy:caddy "$LOG_DIR" 2>/dev/null || true; fi

  if [[ -s "$CADDYFILE" ]] && grep -qF "import $SITES_DIR/" "$CADDYFILE"; then
    return 0   # already in the sites.d layout
  fi

  if [[ -s "$CADDYFILE" ]]; then
    local bak="$CADDYFILE.bak.$(date +%s)"
    as_root cp "$CADDYFILE" "$bak"
    info "Backed up existing Caddyfile to $bak"
    if grep -q reverse_proxy "$CADDYFILE"; then
      as_root cp "$CADDYFILE" "$SITES_DIR/legacy.caddy"
      info "Migrated your existing sites to $SITES_DIR/legacy.caddy"
    fi
  fi

  as_root tee "$CADDYFILE" >/dev/null <<EOF
# Managed by caddy.sh. Add sites with: caddy.sh add <domain> <upstream>
# Each site lives in its own file under $SITES_DIR/
import $SITES_DIR/*.caddy
EOF
  as_root chmod 644 "$CADDYFILE"
}

seed_default_sites() {
  local existing=("$SITES_DIR"/*.caddy)
  [[ ${#existing[@]} -gt 0 ]] && return 0
  info "Default sites:"
  local s; for s in "${DEFAULT_SITES[@]}"; do echo "    ${s%%|*} -> ${s##*|}"; done
  confirm "Create these sites now?" || return 0
  for s in "${DEFAULT_SITES[@]}"; do write_site "${s%%|*}" "${s##*|}"; done
}

# --- system integration -------------------------------------------------------
open_firewall() {
  if command -v ufw >/dev/null 2>&1 && as_root ufw status 2>/dev/null | grep -q "Status: active"; then
    info "Opening ports in ufw"
    as_root ufw allow 80/tcp; as_root ufw allow 443/tcp; as_root ufw allow 443/udp
  elif command -v firewall-cmd >/dev/null 2>&1 && as_root firewall-cmd --state >/dev/null 2>&1; then
    info "Opening ports in firewalld"
    as_root firewall-cmd --permanent --add-service=http --add-service=https
    as_root firewall-cmd --permanent --add-port=443/udp
    as_root firewall-cmd --reload
  else
    info "No ufw/firewalld detected. If you use iptables/nftables or a cloud/router firewall,"
    info "open 80/tcp, 443/tcp and 443/udp yourself."
  fi
}

setup_selinux() {
  if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce)" == "Enforcing" ]]; then
    info "SELinux is enforcing: allowing Caddy to connect to upstream services"
    as_root setsebool -P httpd_can_network_connect 1 || warn "Could not set SELinux boolean."
  fi
}

free_ports() {
  local s
  for s in nginx apache2 httpd lighttpd; do
    case "$INIT" in
      systemd)
        if systemctl is-active --quiet "$s" 2>/dev/null; then
          warn "$s is running and will conflict with Caddy on ports 80/443."
          confirm "Stop and disable $s?" && as_root systemctl disable --now "$s"
        fi ;;
      openrc)
        if rc-service "$s" status >/dev/null 2>&1; then
          warn "$s is running and will conflict with Caddy on ports 80/443."
          confirm "Stop and disable $s?" && { as_root rc-service "$s" stop; as_root rc-update del "$s" 2>/dev/null || true; }
        fi ;;
    esac
  done
}

listeners() {
  if command -v ss >/dev/null 2>&1; then as_root ss -tlnp 2>/dev/null | grep -E ':(80|443)[[:space:]]' || true
  elif command -v netstat >/dev/null 2>&1; then as_root netstat -tlnp 2>/dev/null | grep -E ':(80|443)[[:space:]]' || true
  fi
}

# --- installers ---------------------------------------------------------------
install_via_pm() {
  case "$PM" in
    apt-get)
      as_root apt-get update -y || return 1
      pm_install curl gpg ca-certificates || return 1
      pm_install debian-keyring debian-archive-keyring apt-transport-https || true
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | as_root gpg --dearmor --yes -o "$APT_KEYRING" || return 1
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | as_root tee "$APT_LIST" >/dev/null || return 1
      as_root chmod o+r "$APT_KEYRING" "$APT_LIST"
      as_root apt-get update -y || return 1
      pm_install caddy
      ;;
    dnf)
      pm_install 'dnf-command(copr)' || true
      as_root dnf copr enable -y @caddy/caddy || warn "Caddy COPR repo unavailable, trying distro repos."
      pm_install caddy
      ;;
    yum)
      pm_install yum-plugin-copr || true
      as_root yum copr enable -y @caddy/caddy || warn "Caddy COPR repo unavailable, trying distro repos."
      pm_install caddy
      ;;
    pacman|apk|zypper)
      pm_install caddy
      ;;
    *) return 1 ;;
  esac
}

create_caddy_user() {
  id caddy >/dev/null 2>&1 && return 0
  local nologin; nologin="$(command -v nologin 2>/dev/null || echo /sbin/nologin)"
  if command -v useradd >/dev/null 2>&1; then
    as_root groupadd --system caddy 2>/dev/null || true
    as_root useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell "$nologin" caddy
  else
    as_root addgroup -S caddy 2>/dev/null || true
    as_root adduser -S -G caddy -h /var/lib/caddy -s "$nologin" caddy
  fi
}

install_binary() {
  local arch
  case "$(uname -m)" in
    x86_64|amd64)  arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv7l)        arch="arm&arm=7" ;;
    armv6l)        arch="arm&arm=6" ;;
    i?86)          arch="386" ;;
    ppc64le)       arch="ppc64le" ;;
    s390x)         arch="s390x" ;;
    riscv64)       arch="riscv64" ;;
    *) err "Unsupported CPU architecture: $(uname -m)"; return 1 ;;
  esac

  ensure_prereqs
  info "Downloading official Caddy binary ($(uname -m))"
  local tmp; tmp="$(mktemp)"
  if ! curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=${arch}" -o "$tmp"; then
    rm -f "$tmp"; err "Download failed (check network access to caddyserver.com)."; return 1
  fi
  as_root install -m 0755 "$tmp" /usr/local/bin/caddy
  rm -f "$tmp"
  /usr/local/bin/caddy version >/dev/null 2>&1 || { err "Downloaded binary does not run on this system."; return 1; }

  create_caddy_user
  as_root mkdir -p /var/lib/caddy "$CADDY_DIR" "$LOG_DIR"
  as_root chown -R caddy:caddy /var/lib/caddy "$LOG_DIR" 2>/dev/null || true

  case "$INIT" in
    systemd)
      as_root tee /etc/systemd/system/caddy.service >/dev/null <<'EOF'
[Unit]
Description=Caddy web server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile --adapter caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
      as_root systemctl daemon-reload
      ;;
    openrc)
      as_root tee /etc/init.d/caddy >/dev/null <<'EOF'
#!/sbin/openrc-run
name="caddy"
description="Caddy web server"
command="/usr/local/bin/caddy"
command_args="run --environ --config /etc/caddy/Caddyfile --adapter caddyfile"
command_background=true
pidfile="/run/caddy.pid"
output_log="/var/log/caddy/caddy.log"
error_log="/var/log/caddy/caddy.log"
extra_started_commands="reload"

depend() {
  need net
  after firewall
}

reload() {
  ebegin "Reloading caddy"
  /usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
  eend $?
}
EOF
      as_root chmod +x /etc/init.d/caddy
      # Run unprivileged only if the binary can bind to ports 80/443
      if command -v setcap >/dev/null 2>&1 && as_root setcap cap_net_bind_service=+ep /usr/local/bin/caddy; then
        echo 'command_user="caddy:caddy"' | as_root tee -a /etc/init.d/caddy >/dev/null
      fi
      ;;
  esac
  echo binary | as_root tee "$METHOD_FILE" >/dev/null
}

# --- commands -----------------------------------------------------------------
cmd_install() {
  info "Detected: $OS_NAME | package manager: $PM | init: $INIT"
  is_wsl && warn "WSL detected: Let's Encrypt must reach this machine on ports 80/443 from the internet. Behind a home router/Windows NAT that usually fails."
  if [[ "$INIT" == none ]]; then
    in_container && warn "Container without init: Caddy will run as a background process. Publish ports 80/443 on the container."
    warn "No init system found: Caddy will be run as a background process."
  fi

  if is_installed; then
    warn "Caddy already installed ($(caddy version | head -1)). Re-applying configuration."
  else
    free_ports
    as_root mkdir -p "$CADDY_DIR"
    if [[ "$PM" != none ]] && install_via_pm; then
      echo pkg | as_root tee "$METHOD_FILE" >/dev/null
    else
      warn "Package install not available or failed; using the official static binary instead."
      install_binary || { err "Installation failed."; exit 1; }
    fi
  fi

  setup_config
  seed_default_sites
  validate_config || { err "Fix the config, then run: $0 reload"; exit 1; }
  setup_selinux
  open_firewall
  svc_enable

  if svc_is_active; then svc_reload; else svc_start; fi
  sleep 2
  if svc_is_active; then
    info "Caddy is running. Certificates are issued automatically on the first request."
    info "Watch it with:  $0 logs -f      Diagnose DNS/ports with:  $0 check"
  else
    err "Caddy did not start. See: $0 logs"; exit 1
  fi
}

cmd_uninstall() {
  is_installed || { warn "Caddy is not installed."; return 0; }
  confirm "Uninstall Caddy?" || return 0
  local method; method="$(install_method)"

  svc_stop 2>/dev/null || true
  svc_disable

  if [[ "$method" == pkg ]]; then
    info "Removing package"
    pm_remove caddy || warn "Package removal reported an error."
    case "$PM" in
      apt-get) as_root rm -f "$APT_LIST" "$APT_KEYRING"; as_root apt-get update -y || true ;;
      dnf)     as_root dnf copr disable -y @caddy/caddy 2>/dev/null || true ;;
      yum)     as_root yum copr disable -y @caddy/caddy 2>/dev/null || true ;;
    esac
  else
    info "Removing binary and service files"
    as_root rm -f /usr/local/bin/caddy /etc/systemd/system/caddy.service /etc/init.d/caddy
    [[ "$INIT" == systemd ]] && as_root systemctl daemon-reload
  fi

  if confirm "Also delete config, sites and issued certificates ($CADDY_DIR, /var/lib/caddy, $LOG_DIR)?"; then
    as_root rm -rf "$CADDY_DIR" /var/lib/caddy "$LOG_DIR" "$PID_FILE"
    as_root userdel caddy 2>/dev/null || as_root deluser caddy 2>/dev/null || true
    as_root groupdel caddy 2>/dev/null || true
  fi
  info "Caddy removed."
}

cmd_upgrade() {
  require_installed
  info "Current: $(caddy version | head -1)"
  if [[ "$(install_method)" == binary ]]; then
    as_root "$(caddy_bin)" upgrade
  else
    case "$PM" in
      apt-get) as_root apt-get update -y && as_root apt-get install -y --only-upgrade caddy ;;
      dnf|yum) as_root "$PM" upgrade -y caddy ;;
      pacman)  warn "Arch has no partial upgrades; this runs a full system upgrade."
               confirm "Run pacman -Syu?" && as_root pacman -Syu --noconfirm ;;
      apk)     as_root apk update && as_root apk add --upgrade caddy ;;
      zypper)  as_root zypper --non-interactive update caddy ;;
    esac
  fi
  svc_is_active && svc_restart
  info "Now: $(caddy version | head -1)"
}

cmd_status() {
  require_installed
  svc_status
  echo
  info "Version: $(caddy version | head -1)  |  install method: $(install_method)  |  init: $INIT"
  info "Listening on 80/443:"
  local l; l="$(listeners)"
  if [[ -n "$l" ]]; then echo "$l"; else warn "Nothing listening on 80/443"; fi
  echo
  cmd_list
}

cmd_logs() {
  require_installed
  local arg="${1:-100}"
  if [[ "$INIT" == systemd ]] && command -v journalctl >/dev/null 2>&1; then
    if [[ "$arg" == "-f" ]]; then as_root journalctl -u "$SERVICE" -f
    else as_root journalctl -u "$SERVICE" -n "$arg" --no-pager; fi
  elif [[ -f "$LOG_FILE" ]]; then
    if [[ "$arg" == "-f" ]]; then as_root tail -f "$LOG_FILE"
    else as_root tail -n "$arg" "$LOG_FILE"; fi
  elif [[ -f /var/log/messages ]]; then
    as_root grep -i caddy /var/log/messages | tail -n "${arg//-f/100}"
  else
    err "No log source found (looked at journald, $LOG_FILE, /var/log/messages)."; exit 1
  fi
}

cmd_add() {
  require_installed
  local domain="${1:-}" upstream="${2:-}"
  [[ -n "$domain" && -n "$upstream" ]] || { err "Usage: $0 add <domain> <upstream|port>   e.g. $0 add git.example.com 3000"; exit 1; }
  valid_domain "$domain" || { err "Invalid domain: $domain"; exit 1; }
  upstream="$(normalize_upstream "$upstream")"
  [[ "$upstream" =~ [[:space:]{}] ]] && { err "Invalid upstream: $upstream"; exit 1; }

  setup_config
  local file="$SITES_DIR/$domain.caddy" bak=""
  if [[ -f "$file" ]]; then
    confirm "$domain already exists. Overwrite?" || return 0
    bak="$(mktemp)"; as_root cp "$file" "$bak"
  fi
  write_site "$domain" "$upstream"

  if validate_config; then
    info "Added $domain -> $upstream"
    apply_changes
  else
    if [[ -n "$bak" ]]; then as_root cp "$bak" "$file"; else as_root rm -f "$file"; fi
    err "Change rolled back."; exit 1
  fi
  [[ -n "$bak" ]] && rm -f "$bak"
  info "Make sure DNS for $domain points at this server."
}

cmd_remove() {
  require_installed
  local domain="${1:-}"
  [[ -n "$domain" ]] || { err "Usage: $0 remove <domain>"; exit 1; }
  local file="$SITES_DIR/$domain.caddy"
  if [[ ! -f "$file" ]]; then err "No site file for $domain. Existing sites:"; cmd_list; exit 1; fi
  confirm "Remove $domain?" || return 0
  local bak; bak="$(mktemp)"; as_root cp "$file" "$bak"
  as_root rm -f "$file"
  if validate_config; then
    info "Removed $domain"; apply_changes
  else
    as_root cp "$bak" "$file"; err "Change rolled back."; exit 1
  fi
  rm -f "$bak"
}

cmd_list() {
  local files=("$SITES_DIR"/*.caddy) f d u
  if [[ ${#files[@]} -eq 0 ]]; then warn "No sites configured. Add one: $0 add <domain> <upstream>"; return 0; fi
  info "Configured sites:"
  for f in "${files[@]}"; do
    d="$(basename "$f" .caddy)"
    u="$(awk '/reverse_proxy/ {print $2; exit}' "$f")"
    printf '    %-38s -> %s\n' "$d" "${u:-?}"
  done
}

cmd_edit() {
  require_installed
  local target="$CADDYFILE"
  [[ -n "${1:-}" ]] && target="$SITES_DIR/$1.caddy"
  [[ -f "$target" ]] || { err "Not found: $target"; exit 1; }
  local ed="${EDITOR:-}"
  if [[ -z "$ed" ]]; then for ed in nano vim vi; do command -v "$ed" >/dev/null 2>&1 && break; done; fi
  local bak; bak="$(mktemp)"; as_root cp "$target" "$bak"
  as_root "$ed" "$target"
  if validate_config; then apply_changes
  else
    if confirm "Restore the previous version?"; then as_root cp "$bak" "$target"; info "Restored."; fi
  fi
  rm -f "$bak"
}

cmd_validate() { require_installed; validate_config; }

cmd_fmt() {
  require_installed
  local f
  for f in "$CADDYFILE" "$SITES_DIR"/*.caddy; do as_root "$(caddy_bin)" fmt --overwrite "$f"; done
  info "Formatted."
}

cmd_reload()  { require_installed; validate_config && svc_reload && info "Reloaded."; }
cmd_restart() { require_installed; validate_config && svc_restart && info "Restarted."; }
cmd_start()   { require_installed; svc_start && info "Started."; }
cmd_stop()    { require_installed; svc_stop && info "Stopped."; }

public_ip() { curl "$1" -fsS --max-time 5 https://ifconfig.me 2>/dev/null || true; }

resolve() {  # resolve <A|AAAA> <name>
  local fam=ahostsv4; [[ "$1" == AAAA ]] && fam=ahostsv6
  if command -v getent >/dev/null 2>&1; then getent "$fam" "$2" 2>/dev/null | awk 'NR==1 {print $1}'
  elif command -v dig >/dev/null 2>&1; then dig +short "$1" "$2" | head -1
  fi
}

cmd_check() {
  ensure_prereqs
  local pub4 pub6
  pub4="$(public_ip -4)"; pub6="$(public_ip -6)"
  info "This server's public IPv4: ${pub4:-none}   IPv6: ${pub6:-none}"

  local -a domains=()
  if [[ -n "${1:-}" ]]; then domains=("$1"); else mapfile -t domains < <(site_domains); fi
  [[ ${#domains[@]} -gt 0 ]] || warn "No domains found to check."

  local d a aaaa
  for d in "${domains[@]}"; do
    valid_domain "$d" || continue
    echo; info "Checking $d"
    a="$(resolve A "$d" || true)"; aaaa="$(resolve AAAA "$d" || true)"
    echo "  A    record: ${a:-none}"
    echo "  AAAA record: ${aaaa:-none}"
    [[ -z "$a" && -z "$aaaa" ]] && warn "  $d does not resolve. Create a DNS record first."
    [[ -n "$a" && -n "$pub4" && "$a" != "$pub4" ]] && warn "  A record differs from this server's public IP (wrong DNS, CGNAT or a proxy like Cloudflare?)"
    [[ -n "$aaaa" && "$aaaa" != "$pub6" ]] && warn "  AAAA points elsewhere. Let's Encrypt prefers IPv6: remove or fix it."
  done

  echo; info "Listeners on 80/443:"
  local l; l="$(listeners)"; if [[ -n "$l" ]]; then echo "$l"; else warn "Nothing listening on 80/443"; fi
  if command -v ufw >/dev/null 2>&1; then echo; info "ufw:"; as_root ufw status | head -12 || true; fi
  if command -v firewall-cmd >/dev/null 2>&1; then echo; info "firewalld:"; as_root firewall-cmd --list-all 2>/dev/null | head -12 || true; fi
  echo
  warn "Also confirm ports 80/443 are open in your router or cloud security group."
  warn "Test from OUTSIDE your network:  curl -I http://<your-domain>"
}

cmd_help() {
  cat <<EOF
Usage: $0 [-y] <command> [args]      (-y = answer yes to all prompts)

Setup
  install               Install Caddy (native package, or official binary), configure, start
  uninstall             Remove Caddy (asks before deleting config and certificates)
  upgrade               Upgrade Caddy to the latest version

Sites
  add <domain> <up>     Add a site; <up> is host:port or just a port (e.g. 3000)
  remove <domain>       Remove a site
  list                  Show configured sites
  edit [domain]         Edit the Caddyfile (or one site), validate, reload
  fmt                   Auto-format all Caddy config files

Service
  status                Service state, version, listeners, sites
  logs [N|-f]           Last N log lines (default 100) or follow with -f
  start | stop | restart
  reload                Validate + graceful reload (no downtime)
  validate              Check configuration for errors
  check [domain]        Diagnose DNS / IPv6 / firewall / port problems for certificates

Detected here: $OS_NAME | package manager: $PM | init: $INIT
EOF
}

# --- dispatch -----------------------------------------------------------------
if [[ "${1:-}" == "-y" ]]; then ASSUME_YES=1; shift; fi

cmd="${1:-help}"; [[ $# -gt 0 ]] && shift
case "$cmd" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  upgrade)   cmd_upgrade ;;
  status)    cmd_status ;;
  logs)      cmd_logs "${1:-100}" ;;
  add)       cmd_add "$@" ;;
  remove|rm) cmd_remove "$@" ;;
  list|ls)   cmd_list ;;
  edit)      cmd_edit "$@" ;;
  validate)  cmd_validate ;;
  fmt)       cmd_fmt ;;
  reload)    cmd_reload ;;
  restart)   cmd_restart ;;
  start)     cmd_start ;;
  stop)      cmd_stop ;;
  check)     cmd_check "$@" ;;
  help|-h|--help) cmd_help ;;
  *) err "Unknown command: $cmd"; cmd_help; exit 1 ;;
esac