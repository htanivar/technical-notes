#!/usr/bin/env bash
#
# fail2ban.sh - install / uninstall / status / logs / unban for fail2ban
#               (Debian/Ubuntu)
#
# Usage:
#   sudo ./fail2ban.sh install   [--ignore-ip IP]... [--bantime 1h] [--findtime 10m] [--maxretry 5]
#   sudo ./fail2ban.sh status
#   sudo ./fail2ban.sh logs      [-f] [-n 100] [--bans]
#   sudo ./fail2ban.sh unban     <ip> | --all
#   sudo ./fail2ban.sh uninstall [--purge-logs] [--yes]
#
set -uo pipefail

JAIL_LOCAL=/etc/fail2ban/jail.local
F2B_LOG=/var/log/fail2ban.log

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }

usage() { sed -n '2,13p' "$0"; exit "${1:-0}"; }

jail_list() {
  fail2ban-client status 2>/dev/null \
    | grep 'Jail list' | sed -E 's/^.*Jail list:[[:space:]]*//' | tr -d ','
}

need_installed() {
  command -v fail2ban-client >/dev/null || { echo "fail2ban is not installed. Run: $0 install"; exit 1; }
}

# ---------------------------------------------------------------- install ---
cmd_install() {
  local BANTIME=1h FINDTIME=10m MAXRETRY=5
  local IGNORE=("127.0.0.1/8" "::1")

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ignore-ip) IGNORE+=("$2"); shift 2 ;;
      --bantime)   BANTIME=$2;     shift 2 ;;
      --findtime)  FINDTIME=$2;    shift 2 ;;
      --maxretry)  MAXRETRY=$2;    shift 2 ;;
      *) echo "Unknown option: $1"; usage 1 ;;
    esac
  done

  # Auto-whitelist the IP you're currently SSH'd in from, to avoid locking yourself out
  local MY_IP=""
  if [[ -n ${SSH_CLIENT:-} ]]; then MY_IP=${SSH_CLIENT%% *}
  else MY_IP=$(who -m 2>/dev/null | awk '{print $NF}' | tr -d '()'); fi
  if [[ $MY_IP =~ ^[0-9a-fA-F:.]+$ ]]; then
    IGNORE+=("$MY_IP"); echo "Whitelisting your current IP: $MY_IP"
  fi

  echo "[1/4] Installing fail2ban"
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban || { echo "Install failed"; exit 1; }

  echo "[2/4] Writing $JAIL_LOCAL"
  [[ -f $JAIL_LOCAL ]] && cp -a "$JAIL_LOCAL" "$JAIL_LOCAL.bak.$(date +%s)"

  {
    cat <<EOF
# Managed by fail2ban.sh - edit freely, then: systemctl restart fail2ban
[DEFAULT]
ignoreip  = ${IGNORE[*]}
bantime   = $BANTIME
findtime  = $FINDTIME
maxretry  = $MAXRETRY
# Repeat offenders get progressively longer bans (up to 1 week)
bantime.increment = true
bantime.factor    = 2
bantime.maxtime   = 1w

[sshd]
enabled = true
port    = ssh
EOF

    # Only enable nginx jails if nginx is present (jail fails to load without the log file)
    if command -v nginx >/dev/null 2>&1; then
      mkdir -p /var/log/nginx; touch /var/log/nginx/error.log
      cat <<'EOF'

[nginx-http-auth]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log

[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
maxretry = 2
EOF
    fi
  } > "$JAIL_LOCAL"

  echo "[3/4] Validating configuration"
  fail2ban-client -t || { echo "Config test failed. Check $JAIL_LOCAL"; exit 1; }

  echo "[4/4] Enabling and starting service"
  systemctl enable fail2ban
  systemctl restart fail2ban
  sleep 2
  echo
  cmd_status
}

# ----------------------------------------------------------------- status ---
cmd_status() {
  need_installed
  echo "== Service =="
  systemctl is-enabled fail2ban 2>/dev/null | sed 's/^/enabled: /'
  systemctl is-active  fail2ban 2>/dev/null | sed 's/^/active:  /'
  echo
  if ! fail2ban-client ping >/dev/null 2>&1; then
    echo "fail2ban server is not responding. Try: journalctl -u fail2ban -n 50"
    return 1
  fi
  echo "== Jails =="
  fail2ban-client status
  local total=0
  for j in $(jail_list); do
    echo
    echo "--- $j ---"
    fail2ban-client status "$j"
    n=$(fail2ban-client status "$j" | awk -F: '/Currently banned/ {gsub(/[ \t]/,"",$2); print $2}')
    total=$(( total + ${n:-0} ))
  done
  echo
  echo "Total currently banned IPs: $total"
}

# ------------------------------------------------------------------- logs ---
cmd_logs() {
  local FOLLOW=0 LINES_N=50 BANS=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--follow) FOLLOW=1; shift ;;
      -n)          LINES_N=$2; shift 2 ;;
      --bans)      BANS=1; shift ;;
      *) echo "Unknown option: $1"; usage 1 ;;
    esac
  done

  if [[ -f $F2B_LOG ]]; then
    if (( BANS )); then
      if (( FOLLOW )); then tail -n "$LINES_N" -F "$F2B_LOG" | grep --line-buffered -E ' (Ban|Unban|Restore Ban) '
      else grep -E ' (Ban|Unban|Restore Ban) ' "$F2B_LOG" | tail -n "$LINES_N"; fi
    else
      if (( FOLLOW )); then tail -n "$LINES_N" -F "$F2B_LOG"
      else tail -n "$LINES_N" "$F2B_LOG"; fi
    fi
  else
    echo "$F2B_LOG not found, using journald"
    local args=(-u fail2ban --no-pager -n "$LINES_N")
    (( FOLLOW )) && args+=(-f)
    if (( BANS )); then journalctl "${args[@]}" | grep -E ' (Ban|Unban|Restore Ban) '
    else journalctl "${args[@]}"; fi
  fi
}

# ------------------------------------------------------------------ unban ---
cmd_unban() {
  need_installed
  [[ $# -ge 1 ]] || { echo "Usage: $0 unban <ip> | --all"; exit 1; }
  if [[ $1 == --all ]]; then
    fail2ban-client unban --all
  else
    fail2ban-client unban "$1"
  fi
}

# -------------------------------------------------------------- uninstall ---
cmd_uninstall() {
  local PURGE_LOGS=0 YES=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge-logs) PURGE_LOGS=1; shift ;;
      -y|--yes)     YES=1; shift ;;
      *) echo "Unknown option: $1"; usage 1 ;;
    esac
  done

  echo "This will stop fail2ban, unban all IPs, purge the package and delete /etc/fail2ban and /var/lib/fail2ban."
  (( PURGE_LOGS )) && echo "It will also delete $F2B_LOG*."
  if (( ! YES )); then
    read -r -p "Type 'yes' to continue: " ans
    [[ $ans == yes ]] || { echo "Aborted."; exit 1; }
  fi

  if [[ -f $JAIL_LOCAL ]]; then
    local B=/root/fail2ban-jail.local.$(date +%Y%m%d-%H%M%S)
    cp -a "$JAIL_LOCAL" "$B" && echo "Saved your jail.local to $B"
  fi

  if command -v fail2ban-client >/dev/null; then
    echo "Unbanning all IPs"
    fail2ban-client unban --all 2>/dev/null || true
  fi

  systemctl stop fail2ban 2>/dev/null || true
  systemctl disable fail2ban 2>/dev/null || true

  DEBIAN_FRONTEND=noninteractive apt-get purge -y fail2ban
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

  rm -rf /etc/fail2ban /var/lib/fail2ban
  (( PURGE_LOGS )) && rm -f "$F2B_LOG" "$F2B_LOG".*

  echo "fail2ban removed."
}

# ------------------------------------------------------------------- main ---
[[ $# -ge 1 ]] || usage 1
CMD=$1; shift
case "$CMD" in
  install)   cmd_install "$@" ;;
  status)    cmd_status "$@" ;;
  logs)      cmd_logs "$@" ;;
  unban)     cmd_unban "$@" ;;
  uninstall) cmd_uninstall "$@" ;;
  -h|--help|help) usage 0 ;;
  *) echo "Unknown command: $CMD"; usage 1 ;;
esac