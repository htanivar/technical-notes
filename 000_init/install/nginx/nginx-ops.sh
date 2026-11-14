#!/usr/bin/env bash
#
# nginx-ops.sh — Cross-Distro Nginx Operations, Status, Log Viewer & Remediation Advisor
#
# Supports:
#   - All major Linux families: Debian/Ubuntu/Mint/Kali (apt), RHEL/CentOS/Rocky/Alma/Fedora/Amazon (dnf/yum),
#     Arch/Manjaro (pacman), openSUSE/SLES (zypper), Alpine (apk)
#   - All init systems: systemd, SysVinit (service / update-rc.d / chkconfig), OpenRC (rc-service / rc-update),
#     and direct binary signal fallback (containers / WSL / minimal environments)
#
# Subcommands:
#   start       Validate config (nginx -t) and start Nginx
#   stop        Stop Nginx gracefully
#   restart     Validate config (nginx -t) and restart Nginx
#   reload      Validate config (nginx -t) and reload Nginx with zero downtime
#   enable      Enable Nginx service to start at boot
#   disable     Disable Nginx service from starting at boot
#   test        Test Nginx configuration syntax (pass --dump to view full effective config)
#   status      Fast operational dashboard (daemon, workers, ports, vhosts, SSL, health)
#   logs        View/tail Nginx access & error logs (--error, --access, --domain, --lines, --follow)
#   audit       Run full 17-section security & server audit via status_nginx.sh
#   advise      Read-only remediation guide: explains WHAT is wrong, WHY it matters, and HOW to fix it
#   help        Display usage guide and examples

set -euo pipefail
export LC_ALL=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_SCRIPT="${SCRIPT_DIR}/status_nginx.sh"
DEFAULT_REPORT="${SCRIPT_DIR}/nginx-audit-report.md"

########################
# Colors & Output Helpers
########################
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  C_RESET=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_RED=$'\e[31m'
  C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'
  C_BLUE=$'\e[34m'
  C_CYAN=$'\e[36m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

log_info()  { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$*"; }
log_ok()    { printf "${C_GREEN}[ OK ]${C_RESET}  %s\n" "$*"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$*"; }
log_fail()  { printf "${C_RED}[FAIL]${C_RESET}  %s\n" "$*"; }
log_step()  { printf "${C_CYAN}${C_BOLD}[STEP]${C_RESET}  %s\n" "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

file_link() {
  local ref="$1"
  [[ -z "$ref" ]] && { echo "N/A"; return; }
  local path="${ref%:*}"
  local line=""
  if [[ "$ref" == *:* ]] && [[ "${ref##*:}" =~ ^[0-9]+$ ]]; then
    line="${ref##*:}"
  else
    path="$ref"
  fi
  local base
  base="$(basename "$path")"
  if [[ -n "$line" ]]; then
    printf '[%s:%s](file://%s#L%s) (%s:%s)' "$base" "$line" "$path" "$line" "$path" "$line"
  else
    printf '[%s](file://%s) (%s)' "$base" "$path" "$path"
  fi
}

########################
# OS, Init & Nginx Discovery
########################
detect_environment() {
  OS_ID="linux"
  OS_PRETTY="Linux"
  PKG_FAMILY="unknown"

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="$(echo "${ID:-linux}" | tr '[:upper:]' '[:lower:]')"
    OS_PRETTY="${PRETTY_NAME:-${ID:-Linux}}"
  fi

  if have apt-get; then PKG_FAMILY="apt"
  elif have dnf; then PKG_FAMILY="dnf"
  elif have yum; then PKG_FAMILY="yum"
  elif have pacman; then PKG_FAMILY="pacman"
  elif have zypper; then PKG_FAMILY="zypper"
  elif have apk; then PKG_FAMILY="apk"
  fi

  # Detect active init system
  if [[ -d /run/systemd/system ]] && have systemctl; then
    INIT_SYSTEM="systemd"
  elif have rc-service && [[ -d /run/openrc || -f /etc/init.d/functions.sh ]]; then
    INIT_SYSTEM="openrc"
  elif have service && [[ -x /etc/init.d/nginx ]]; then
    INIT_SYSTEM="sysvinit"
  else
    INIT_SYSTEM="direct"
  fi

  # Locate nginx binary
  NGINX_BIN="$(command -v nginx || true)"
  if [[ -z "$NGINX_BIN" ]]; then
    for p in /usr/sbin/nginx /usr/local/sbin/nginx /usr/local/nginx/sbin/nginx /opt/nginx/sbin/nginx; do
      if [[ -x "$p" ]]; then
        NGINX_BIN="$p"
        break
      fi
    done
  fi

  if [[ -z "$NGINX_BIN" ]]; then
    log_fail "Nginx binary not found on this system."
    printf "  Install Nginx first using: sudo %s/install_nginx.sh\n" "$SCRIPT_DIR"
    exit 1
  fi

  NGINX_VER="$("$NGINX_BIN" -v 2>&1 | sed 's/.*nginx\///')"
  CONF_PATH="$("$NGINX_BIN" -V 2>&1 | grep -oE '\-\-conf-path=[^ ]+' | cut -d= -f2 || true)"
  CONF_PATH="${CONF_PATH:-/etc/nginx/nginx.conf}"
  CONF_DIR="$(dirname "$CONF_PATH")"

  PID_PATH="$("$NGINX_BIN" -V 2>&1 | grep -oE '\-\-pid-path=[^ ]+' | cut -d= -f2 || true)"
  PID_PATH="${PID_PATH:-/run/nginx.pid}"

  IS_ROOT=0
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    IS_ROOT=1
  fi
}

# Wrapper to run privileged commands via sudo when not root
run_priv() {
  if (( IS_ROOT == 1 )); then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    log_fail "Root privileges required for '$*' (run with sudo)."
    return 1
  fi
}

########################
# Config Parsing & Line Discovery Helpers
########################
load_effective_config() {
  local full_out="$1"
  local clean_out="$2"
  local linemap_out="$3"
  local err_out="$4"

  : > "$full_out"
  : > "$err_out"

  if ! "$NGINX_BIN" -T >"$full_out" 2>"$err_out"; then
    if (( IS_ROOT == 0 )) && have sudo && sudo -n true 2>/dev/null; then
      sudo -n "$NGINX_BIN" -T >"$full_out" 2>"$err_out" || true
    fi
  fi

  # Fallback config reader if nginx -T fails (e.g. non-root permission denied on ssl_certificate_key)
  if [[ ! -s "$full_out" && -r "$CONF_PATH" ]]; then
    append_file() {
      local f="$1"
      [[ -r "$f" ]] || return 0
      printf '# configuration file %s:\n' "$f" >> "$full_out"
      cat "$f" >> "$full_out"
      printf '\n' >> "$full_out"
    }
    append_file "$CONF_PATH"
    for inc_dir in "$CONF_DIR/modules-enabled" "$CONF_DIR/conf.d" "$CONF_DIR/sites-enabled"; do
      if [[ -d "$inc_dir" ]]; then
        for cf in "$inc_dir"/*; do
          [[ -f "$cf" && -r "$cf" ]] && append_file "$cf"
        done
      fi
    done
  fi

  sed -E 's/#.*$//' "$full_out" | sed -E '/^[[:space:]]*$/d' > "$clean_out"

  awk '
  /^# configuration file / {
    f = $0
    sub(/^# configuration file /, "", f)
    sub(/:$/, "", f)
    ln = 0
    next
  }
  {
    ln++
    if (f != "") {
      printf "%s:%d:%s\n", f, ln, $0
    }
  }
  ' "$full_out" > "$linemap_out"
}

find_in_linemap() {
  local linemap="$1"
  local regex="$2"
  local fallback="${3:-${CONF_PATH}:1}"
  local match=""
  match="$(awk -F: -v re="$regex" '
    {
      line = substr($0, length($1) + length($2) + 3)
      sub(/#.*/, "", line)
      if (line ~ re) {
        print $1 ":" $2
        exit
      }
    }
  ' "$linemap" 2>/dev/null || true)"
  if [[ -z "$match" ]]; then
    match="$(awk -F: -v re="$regex" '
      {
        line = substr($0, length($1) + length($2) + 3)
        if (line ~ re) {
          print $1 ":" $2
          exit
        }
      }
    ' "$linemap" 2>/dev/null || true)"
  fi
  echo "${match:-$fallback}"
}

########################
# Process & Service Helpers
########################
nginx_is_running() {
  pgrep -x nginx >/dev/null 2>&1
}

nginx_boot_enabled() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl is-enabled --quiet nginx 2>/dev/null && return 0 || return 1
      ;;
    sysvinit)
      ls /etc/rc*.d/S*nginx* >/dev/null 2>&1 && return 0 || return 1
      ;;
    openrc)
      rc-update show default 2>/dev/null | grep -qw nginx && return 0 || return 1
      ;;
    *)
      return 1
      ;;
  esac
}

clean_stale_pid() {
  for pf in "$PID_PATH" /run/nginx.pid /var/run/nginx.pid; do
    if [[ -f "$pf" ]] && ! nginx_is_running; then
      local pval
      pval="$(cat "$pf" 2>/dev/null || true)"
      log_warn "Removing stale PID file $pf (PID ${pval:-empty} is not running)"
      run_priv rm -f "$pf" || true
    fi
  done
}

########################
# Subcommand: test
########################
cmd_test() {
  local dump_full=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dump|-T) dump_full=1; shift ;;
      *) shift ;;
    esac
  done

  log_step "Testing Nginx configuration syntax ($CONF_PATH)..."
  local tmp_err
  tmp_err="$(mktemp)"
  local rc=0

  if (( dump_full == 1 )); then
    run_priv "$NGINX_BIN" -T || rc=$?
    rm -f "$tmp_err"
    return "$rc"
  fi

  if (( IS_ROOT == 1 )); then
    "$NGINX_BIN" -t >"$tmp_err" 2>&1 || rc=$?
  elif have sudo && sudo -n true 2>/dev/null; then
    sudo -n "$NGINX_BIN" -t >"$tmp_err" 2>&1 || rc=$?
  else
    "$NGINX_BIN" -t >"$tmp_err" 2>&1 || rc=$?
  fi

  if (( rc == 0 )); then
    log_ok "Nginx configuration syntax is valid."
    sed 's/^/  /' "$tmp_err"
    rm -f "$tmp_err"
    return 0
  else
    if (( IS_ROOT == 0 )) && grep -qi "Permission denied" "$tmp_err"; then
      log_warn "Config test requires root privileges to read restricted SSL keys/files:"
      sed 's/^/  /' "$tmp_err"
      printf "  -> Re-run with sudo: ${C_BOLD}sudo %s test${C_RESET}\n" "$0"
      rm -f "$tmp_err"
      return 1
    fi
    log_fail "Nginx configuration test failed!"
    sed 's/^/  /' "$tmp_err"
    local err_loc
    err_loc="$(grep -v '\[warn\]' "$tmp_err" | grep -oE '/[^ ":]+:[0-9]+' | tail -n 1 || true)"
    [[ -n "$err_loc" ]] && printf "  Offending location: %s\n" "$(file_link "$err_loc")"
    rm -f "$tmp_err"
    return "$rc"
  fi
}

########################
# Subcommands: start, stop, restart, reload, enable, disable
########################
cmd_start() {
  if nginx_is_running; then
    log_ok "Nginx is already running (Master PID: $(pgrep -o -x nginx))."
    return 0
  fi

  cmd_test
  clean_stale_pid
  log_step "Starting Nginx via ${INIT_SYSTEM}..."

  case "$INIT_SYSTEM" in
    systemd)  run_priv systemctl start nginx ;;
    sysvinit) run_priv service nginx start || run_priv "$NGINX_BIN" ;;
    openrc)   run_priv rc-service nginx start || run_priv "$NGINX_BIN" ;;
    direct)   run_priv "$NGINX_BIN" ;;
  esac

  sleep 1
  if nginx_is_running; then
    log_ok "Nginx started successfully (Master PID: $(pgrep -o -x nginx))."
  else
    log_fail "Nginx failed to start. Run '$0 logs --error' or '$0 advise' for details."
    return 1
  fi
}

cmd_stop() {
  if ! nginx_is_running; then
    log_ok "Nginx is already stopped."
    clean_stale_pid
    return 0
  fi

  log_step "Stopping Nginx via ${INIT_SYSTEM}..."
  case "$INIT_SYSTEM" in
    systemd)  run_priv systemctl stop nginx ;;
    sysvinit) run_priv service nginx stop || run_priv "$NGINX_BIN" -s quit ;;
    openrc)   run_priv rc-service nginx stop || run_priv "$NGINX_BIN" -s quit ;;
    direct)   run_priv "$NGINX_BIN" -s quit || run_priv "$NGINX_BIN" -s stop ;;
  esac

  sleep 1
  if nginx_is_running; then
    log_warn "Graceful stop timed out; sending fast stop (-s stop)..."
    run_priv "$NGINX_BIN" -s stop 2>/dev/null || run_priv pkill -x nginx || true
    sleep 1
  fi

  clean_stale_pid
  if ! nginx_is_running; then
    log_ok "Nginx stopped."
  else
    log_fail "Could not stop Nginx processes: $(pgrep -x nginx | tr '\n' ' ')"
    return 1
  fi
}

cmd_restart() {
  log_step "Validating configuration before restart..."
  cmd_test
  if nginx_is_running; then
    log_step "Restarting Nginx via ${INIT_SYSTEM}..."
    case "$INIT_SYSTEM" in
      systemd)  run_priv systemctl restart nginx ;;
      sysvinit) run_priv service nginx restart || { cmd_stop && cmd_start; } ;;
      openrc)   run_priv rc-service nginx restart || { cmd_stop && cmd_start; } ;;
      direct)   cmd_stop && cmd_start ;;
    esac
  else
    cmd_start
  fi

  sleep 1
  if nginx_is_running; then
    log_ok "Nginx restarted successfully (Master PID: $(pgrep -o -x nginx))."
  else
    log_fail "Nginx is not running after restart."
    return 1
  fi
}

cmd_reload() {
  log_step "Validating configuration before zero-downtime reload..."
  cmd_test
  if ! nginx_is_running; then
    log_warn "Nginx is not currently running; starting it instead..."
    cmd_start
    return $?
  fi

  log_step "Reloading Nginx configuration via ${INIT_SYSTEM}..."
  case "$INIT_SYSTEM" in
    systemd)  run_priv systemctl reload nginx ;;
    sysvinit) run_priv service nginx reload || run_priv "$NGINX_BIN" -s reload ;;
    openrc)   run_priv rc-service nginx reload || run_priv "$NGINX_BIN" -s reload ;;
    direct)   run_priv "$NGINX_BIN" -s reload ;;
  esac
  log_ok "Nginx reloaded gracefully."
}

cmd_enable() {
  log_step "Enabling Nginx to start at boot (${INIT_SYSTEM})..."
  case "$INIT_SYSTEM" in
    systemd)
      run_priv systemctl enable nginx
      ;;
    sysvinit)
      if have update-rc.d; then
        run_priv update-rc.d nginx defaults
      elif have chkconfig; then
        run_priv chkconfig nginx on
      else
        log_fail "Neither update-rc.d nor chkconfig found for SysVinit."
        return 1
      fi
      ;;
    openrc)
      run_priv rc-update add nginx default
      ;;
    *)
      log_warn "Boot enablement is not supported in direct/container mode (init=${INIT_SYSTEM})."
      return 1
      ;;
  esac
  log_ok "Nginx enabled at boot."
}

cmd_disable() {
  log_step "Disabling Nginx from starting at boot (${INIT_SYSTEM})..."
  case "$INIT_SYSTEM" in
    systemd)
      run_priv systemctl disable nginx
      ;;
    sysvinit)
      if have update-rc.d; then
        run_priv update-rc.d -f nginx remove
      elif have chkconfig; then
        run_priv chkconfig nginx off
      fi
      ;;
    openrc)
      run_priv rc-update del nginx default
      ;;
    *)
      log_warn "Boot disablement is not supported in direct/container mode (init=${INIT_SYSTEM})."
      return 1
      ;;
  esac
  log_ok "Nginx disabled at boot."
}

########################
# Subcommand: status
########################
cmd_status() {
  local tmpd
  tmpd="$(mktemp -d)"
  local full="$tmpd/full.conf" clean="$tmpd/clean.conf" linemap="$tmpd/linemap.txt" err="$tmpd/err.txt"
  load_effective_config "$full" "$clean" "$linemap" "$err"

  local running=0
  if nginx_is_running; then
    running=1
  fi

  local boot_state="DISABLED"
  if nginx_boot_enabled; then
    boot_state="ENABLED"
  fi

  local master_pid="none" worker_count=0 rss_mb="0.0" uptime_str="N/A"
  if (( running == 1 )); then
    master_pid="$(pgrep -o -x nginx 2>/dev/null || echo 'none')"
    worker_count="$(pgrep -f 'nginx: worker' 2>/dev/null | wc -l | tr -d ' ')"
    rss_mb="$(ps -C nginx -o rss= 2>/dev/null | awk '{s+=$1} END{printf "%.1f", s/1024}')"
    if [[ "$master_pid" != "none" ]]; then
      uptime_str="$(ps -o etime= -p "$master_pid" 2>/dev/null | tr -d ' ' || echo 'N/A')"
    fi
  fi

  printf "\n${C_BOLD}==================== NGINX OPERATIONAL STATUS ====================${C_RESET}\n"
  printf "${C_CYAN}[Host & Binary]${C_RESET}\n"
  printf "  OS / Distro    : %s (%s)\n" "$OS_PRETTY" "$PKG_FAMILY"
  printf "  Init System    : %s\n" "$INIT_SYSTEM"
  printf "  Nginx Version  : nginx/%s (%s)\n" "$NGINX_VER" "$(file_link "$NGINX_BIN")"
  printf "  Main Config    : %s\n" "$(file_link "$CONF_PATH")"

  printf "\n${C_CYAN}[Service & Processes]${C_RESET}\n"
  if (( running == 1 )); then
    printf "  Daemon State   : ${C_GREEN}${C_BOLD}ACTIVE (RUNNING)${C_RESET}\n"
    printf "  Master PID     : %s (uptime: %s)\n" "$master_pid" "$uptime_str"
    printf "  Worker Procs   : %s worker(s) | Memory RSS: %s MB\n" "$worker_count" "$rss_mb"
  else
    printf "  Daemon State   : ${C_RED}${C_BOLD}STOPPED (0 active nginx processes)${C_RESET}\n"
  fi
  if [[ "$boot_state" == "ENABLED" ]]; then
    printf "  Boot Startup   : ${C_GREEN}ENABLED${C_RESET}\n"
  else
    printf "  Boot Startup   : ${C_YELLOW}DISABLED${C_RESET}\n"
  fi

  printf "\n${C_CYAN}[Configuration & Listening Sockets]${C_RESET}\n"
  if grep -q 'syntax is ok' "$err" && grep -q 'test is successful' "$err"; then
    printf "  Syntax Test    : ${C_GREEN}OK (nginx -t passed)${C_RESET}\n"
  elif (( IS_ROOT == 0 )) && grep -qi 'Permission denied' "$err"; then
    printf "  Syntax Test    : ${C_YELLOW}NEEDS SUDO (restricted SSL key file; run 'sudo %s status')${C_RESET}\n" "$0"
  else
    printf "  Syntax Test    : ${C_RED}FAILED (run 'sudo %s test' for details)${C_RESET}\n" "$0"
  fi

  local sock_out=""
  if have ss; then
    sock_out="$(ss -tulnp 2>/dev/null | grep -i nginx || true)"
  elif have netstat; then
    sock_out="$(netstat -tulnp 2>/dev/null | grep -i nginx || true)"
  fi
  if [[ -n "$sock_out" ]]; then
    printf "  Active Sockets :\n"
    echo "$sock_out" | sed 's/^/    /'
  else
    printf "  Active Sockets : (none — daemon stopped or requires sudo to view socket owners)\n"
  fi

  printf "\n${C_CYAN}[Configured Virtual Hosts]${C_RESET}\n"
  awk '
  function val(s,k,  t){ t=s; sub("^[ \t]*" k "[ \t]+","",t); sub(/[ \t]*;.*/,"",t); return t }
  /^# configuration file /{ f=$4; sub(/:$/,"",f); fline=0; next }
  {
    fline++
    line=$0; sub(/#.*/,"",line)
    if (!ins && line ~ /^[ \t]*server[ \t]*\{/) {
      ins=1; depth=0; n++; file[n]=f ":" fline; lis[n]=""; sn[n]=""; rt[n]=""; px[n]=""; ssl[n]=""
    }
    if (ins) {
      if (line ~ /^[ \t]*listen[ \t]/)        lis[n]=lis[n] (lis[n]?", ":"") val(line,"listen")
      if (line ~ /^[ \t]*server_name[ \t]/)   sn[n]=val(line,"server_name")
      if (line ~ /^[ \t]*root[ \t]/ && rt[n]=="") rt[n]=val(line,"root")
      if (line ~ /^[ \t]*proxy_pass[ \t]/)    px[n]=val(line,"proxy_pass")
      if (line ~ /^[ \t]*ssl_certificate[ \t]/) ssl[n]=val(line,"ssl_certificate")
      o=gsub(/\{/,"{",line); c=gsub(/\}/,"}",line); depth+=o-c
      if (depth<=0) ins=0
    }
  }
  END {
    if (!n) { print "  (no server blocks found)"; exit }
    for (i=1; i<=n; i++) {
      target = (px[i] != "") ? "proxy -> " px[i] : "root -> " (rt[i] != "" ? rt[i] : "default")
      split(file[i], fp, ":")
      nparts = split(fp[1], bparts, "/")
      bname = bparts[nparts]
      printf "  [%d] %-26s | listen: %-18s | %s\n", i, (sn[i]==""?"_ (default)":sn[i]), lis[i], target
      printf "      config: [%s:%s](file://%s#L%s) (%s)\n", bname, fp[2], fp[1], fp[2], file[i]
    }
  }
  ' "$full"

  printf "\n${C_CYAN}[Quick Diagnostics & Next Steps]${C_RESET}\n"
  printf "  - Run ${C_BOLD}%s advise${C_RESET}  -> View what is wrong, why it matters, and exact commands to fix it\n" "$0"
  printf "  - Run ${C_BOLD}%s logs${C_RESET}    -> Inspect error and access logs (--error, --access, --follow)\n" "$0"
  printf "  - Run ${C_BOLD}%s audit${C_RESET}   -> Generate full 17-section Markdown report (%s)\n" "$0" "$(basename "$DEFAULT_REPORT")"
  printf "${C_BOLD}==================================================================${C_RESET}\n\n"

  rm -rf "$tmpd"
  (( running == 1 )) && return 0 || return 1
}

########################
# Subcommand: logs
########################
cmd_logs() {
  local show_error=0
  local show_access=0
  local follow=0
  local lines=50
  local domain_filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--error)   show_error=1; shift ;;
      -a|--access)  show_access=1; shift ;;
      -f|--follow)  follow=1; shift ;;
      -n|--lines)
        lines="${2:-50}"
        shift 2
        ;;
      -d|--domain)
        domain_filter="${2:-}"
        shift 2
        ;;
      -h|--help)
        cat <<EOF
Usage: $(basename "$0") logs [OPTIONS]

Options:
  -e, --error            Show error logs only
  -a, --access           Show access logs only
  -d, --domain <name>    Filter log files matching <name> (e.g. nginx.localhost.com)
  -n, --lines <N>        Show last N lines per log file (default: 50)
  -f, --follow           Follow log output live (tail -f)
  -h, --help             Show this help message
EOF
        return 0
        ;;
      *)
        log_warn "Unknown logs option: $1"
        shift
        ;;
    esac
  done

  # Default: show both error and access logs if neither flag specified
  if (( show_error == 0 && show_access == 0 )); then
    show_error=1
    show_access=1
  fi

  local tmpd
  tmpd="$(mktemp -d)"
  local full="$tmpd/full.conf" clean="$tmpd/clean.conf" linemap="$tmpd/linemap.txt" err="$tmpd/err.txt"
  load_effective_config "$full" "$clean" "$linemap" "$err"

  local log_files=()
  if (( show_error == 1 )); then
    while IFS= read -r l; do
      [[ -n "$l" ]] && log_files+=("$l") || true
    done < <(grep -E '^\s*error_log\s' "$clean" | awk '{print $2}' | tr -d ';"' | grep -vE '^(off|syslog:|stderr|memory:)' | sort -u || true)
    if [[ ${#log_files[@]} -eq 0 && -e /var/log/nginx/error.log ]]; then
      log_files+=("/var/log/nginx/error.log")
    fi
  fi

  if (( show_access == 1 )); then
    while IFS= read -r l; do
      [[ -n "$l" ]] && log_files+=("$l") || true
    done < <(grep -E '^\s*access_log\s' "$clean" | awk '{print $2}' | tr -d ';"' | grep -vE '^(off|syslog:)' | sort -u || true)
    if [[ -e /var/log/nginx/access.log ]]; then
      log_files+=("/var/log/nginx/access.log")
    fi
  fi

  rm -rf "$tmpd"

  # Deduplicate and optionally filter by domain
  local unique_logs=()
  while IFS= read -r lf; do
    [[ -z "$lf" ]] && continue
    if [[ -n "$domain_filter" && "$lf" != *"$domain_filter"* ]]; then
      continue
    fi
    if [[ -e "$lf" ]]; then
      unique_logs+=("$lf")
    fi
  done < <(printf "%s\n" "${log_files[@]}" | awk '!seen[$0]++')

  if (( ${#unique_logs[@]} == 0 )); then
    log_warn "No matching log files found${domain_filter:+ for domain '$domain_filter'}."
    return 0
  fi

  log_info "Matched log file(s):"
  for lf in "${unique_logs[@]}"; do
    printf "  - %s\n" "$(file_link "$lf")"
  done
  echo

  if (( follow == 1 )); then
    log_step "Live tailing ${#unique_logs[@]} log file(s) (Ctrl+C to stop)..."
    tail -n "$lines" -f "${unique_logs[@]}"
  else
    for lf in "${unique_logs[@]}"; do
      printf "${C_BOLD}==> %s (last %s lines) <==${C_RESET}\n" "$(file_link "$lf")" "$lines"
      if [[ -r "$lf" ]]; then
        if [[ -s "$lf" ]]; then
          tail -n "$lines" "$lf" | sed 's/^/  /'
        else
          printf "  (log file is empty — 0 bytes)\n"
        fi
      else
        log_warn "Cannot read $lf without root privileges (try: sudo $0 logs)"
      fi
      echo
    done
  fi
}

########################
# Subcommand: audit
########################
cmd_audit() {
  if [[ ! -x "$AUDIT_SCRIPT" ]]; then
    log_fail "Audit script not found or not executable: $AUDIT_SCRIPT"
    return 1
  fi
  log_step "Running full 17-section Nginx audit via $(file_link "$AUDIT_SCRIPT")..."
  "$AUDIT_SCRIPT" "$@"
}

########################
# Subcommand: advise (Read-Only Remediation Advisor)
########################
cmd_advise() {
  local tmpd
  tmpd="$(mktemp -d)"
  local full="$tmpd/full.conf" clean="$tmpd/clean.conf" linemap="$tmpd/linemap.txt" err="$tmpd/err.txt"
  load_effective_config "$full" "$clean" "$linemap" "$err"

  local http_loc first_srv_loc
  http_loc="$(find_in_linemap "$linemap" "^[[:space:]]*http[[:space:]]*\\{" "${CONF_PATH}:12")"
  first_srv_loc="$(find_in_linemap "$linemap" "^[[:space:]]*server[[:space:]]*\\{" "${CONF_PATH}:1")"

  printf "\n${C_BOLD}======================================================================${C_RESET}\n"
  printf "${C_BOLD} NGINX DIAGNOSTIC & SELF-REMEDIATION ADVISOR (READ-ONLY — NO CHANGES) ${C_RESET}\n"
  printf "${C_BOLD}======================================================================${C_RESET}\n"
  printf "Host: %s | Init: %s | Pkg: %s | Report: %s\n\n" \
    "$OS_PRETTY" "$INIT_SYSTEM" "$PKG_FAMILY" "$(file_link "$DEFAULT_REPORT")"

  local issue_num=0

  print_advice() {
    local sev="$1"
    local title="$2"
    local where="$3"
    local why="$4"
    local how="$5"
    local docs="$6"
    issue_num=$((issue_num + 1))
    local badge="${C_YELLOW}[WARN]${C_RESET}"
    [[ "$sev" == "FAIL" ]] && badge="${C_RED}${C_BOLD}[FAIL]${C_RESET}"

    printf "${C_BOLD}%d. %b %s${C_RESET}\n" "$issue_num" "$badge" "$title"
    printf "   ${C_CYAN}Where     :${C_RESET} %s\n" "$(file_link "$where")"
    printf "   ${C_CYAN}Why (Risk):${C_RESET} %s\n" "$why"
    printf "   ${C_CYAN}Reference :${C_RESET} %s\n" "$docs"
    printf "   ${C_GREEN}How to Fix:${C_RESET}\n"
    while IFS= read -r hl; do
      printf "     %s\n" "$hl"
    done <<< "$how"
    echo
  }

  # 1. Check if Nginx daemon is running
  if ! nginx_is_running; then
    local start_cmd="sudo systemctl start nginx"
    [[ "$INIT_SYSTEM" == "sysvinit" ]] && start_cmd="sudo service nginx start   # or: sudo $0 start" || true
    [[ "$INIT_SYSTEM" == "openrc" ]]   && start_cmd="sudo rc-service nginx start # or: sudo $0 start" || true
    [[ "$INIT_SYSTEM" == "direct" ]]   && start_cmd="sudo $NGINX_BIN            # or: sudo $0 start" || true
    print_advice "FAIL" \
      "Nginx daemon is NOT running (0 active nginx processes)" \
      "/etc/init.d/nginx" \
      "All HTTP (port 80) and HTTPS (port 443) requests are currently refused because no Nginx master or worker processes are active." \
      "1) Test configuration syntax as root:
   sudo nginx -t
2) Start the Nginx service:
   ${start_cmd}
3) Verify it is listening on ports 80/443:
   $0 status" \
      "https://nginx.org/en/docs/control.html"
  fi

  # 2. Check for deprecated TLSv1 / TLSv1.1 protocols
  local pr
  pr="$(grep -E '^\s*ssl_protocols\s' "$clean" | sed -E 's/^\s*ssl_protocols\s+//; s/;//' | sort -u || true)"
  if echo "$pr" | grep -qE 'SSLv|TLSv1( |$)|TLSv1\.1'; then
    local proto_loc
    proto_loc="$(find_in_linemap "$linemap" "^[[:space:]]*ssl_protocols[[:space:]]" "$http_loc")"
    local proto_file="${proto_loc%:*}"
    print_advice "FAIL" \
      "Deprecated and insecure TLS protocols enabled (TLSv1 / TLSv1.1)" \
      "$proto_loc" \
      "TLS 1.0 and TLS 1.1 are officially deprecated (RFC 8996), lack modern AEAD cipher support, and are vulnerable to protocol downgrade and BEAST/POODLE-class attacks." \
      "1) Edit ${proto_file} around line ${proto_loc##*:} and restrict ssl_protocols to TLSv1.2 and TLSv1.3:
   sudo sed -i 's/ssl_protocols .*/ssl_protocols TLSv1.2 TLSv1.3;/' ${proto_file}
2) Validate and reload Nginx:
   sudo nginx -t && sudo $0 reload" \
      "https://ssl-config.mozilla.org/#server=nginx"
  fi

  # 3. Check for weak TLS ciphers
  local ci
  ci="$(grep -E '^\s*ssl_ciphers\s' "$clean" | head -n1 || true)"
  if [[ -n "$ci" ]] && echo "$ci" | grep -qiE 'RC4|3DES|NULL|EXPORT|MD5|aNULL|DES-CBC'; then
    local ciph_loc
    ciph_loc="$(find_in_linemap "$linemap" "^[[:space:]]*ssl_ciphers[[:space:]]" "$first_srv_loc")"
    local ciph_file="${ciph_loc%:*}"
    print_advice "FAIL" \
      "Weak TLS cipher suites allowed in ssl_ciphers" \
      "$ciph_loc" \
      "Allowing weak or legacy cipher suites (such as 3DES, RC4, MD5, or export-grade ciphers) exposes encrypted HTTPS traffic to Sweet32 and cipher-downgrade attacks." \
      "1) Open ${ciph_file} at line ${ciph_loc##*:} and replace 'ssl_ciphers' with Mozilla Intermediate AEAD ciphers:
   ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
   ssl_prefer_server_ciphers off;
2) Validate and reload Nginx:
   sudo nginx -t && sudo $0 reload" \
      "https://ssl-config.mozilla.org/#server=nginx"
  fi

  # 4. Check if Nginx is enabled at boot
  if ! nginx_boot_enabled; then
    local en_cmd="sudo systemctl enable nginx"
    [[ "$INIT_SYSTEM" == "sysvinit" ]] && en_cmd="sudo update-rc.d nginx defaults   # or: sudo $0 enable" || true
    [[ "$INIT_SYSTEM" == "openrc" ]]   && en_cmd="sudo rc-update add nginx default  # or: sudo $0 enable" || true
    print_advice "WARN" \
      "Nginx service is not enabled to start automatically at system boot" \
      "/etc/init.d/nginx" \
      "If the server reboots after a kernel update or power cycle, Nginx will remain stopped until started manually." \
      "Enable boot persistence using:
   ${en_cmd}" \
      "https://nginx.org/en/docs/control.html"
  fi

  # 5. Check server_tokens
  local st
  st="$(grep -E '^\s*server_tokens\s' "$clean" | awk '{print $2}' | tr -d ';' | sort -u | tr '\n' ' ' || true)"
  if ! echo "$st" | grep -q off; then
    local st_loc
    st_loc="$(find_in_linemap "$linemap" "server_tokens" "$http_loc")"
    print_advice "WARN" \
      "server_tokens is not set to 'off' (Nginx version exposed)" \
      "$st_loc" \
      "Exposing 'Server: nginx/${NGINX_VER}' in HTTP response headers and default error pages helps automated scanners fingerprint exact CVE patch levels." \
      "1) Uncomment or set 'server_tokens off;' in ${CONF_PATH} (line ${st_loc##*:}):
   sudo sed -i 's/#\s*server_tokens off;/server_tokens off;/' ${CONF_PATH}
2) Test and reload Nginx:
   sudo nginx -t && sudo $0 reload" \
      "https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens"
  fi

  # 6. Check ssl_session_cache
  if ! grep -qE 'ssl_session_cache' "$clean"; then
    print_advice "WARN" \
      "ssl_session_cache is not configured" \
      "$http_loc" \
      "Without a shared SSL session cache, every worker process performs full TLS handshakes more frequently, increasing CPU usage and client latency." \
      "Add the following inside the 'http {' block of ${CONF_PATH}:
   ssl_session_cache shared:SSL:10m;
   ssl_session_timeout 1d;
   ssl_session_tickets off;" \
      "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache"
  fi

  # 7. Check HTTP Security Headers
  local missing_hdrs=()
  for h in "Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" "Content-Security-Policy" "Referrer-Policy" "Permissions-Policy"; do
    if ! grep -qiE "add_header\s+\"?$h" "$clean"; then
      missing_hdrs+=("$h")
    fi
  done
  if (( ${#missing_hdrs[@]} > 0 )); then
    print_advice "WARN" \
      "Missing HTTP Security Headers (${missing_hdrs[*]})" \
      "$first_srv_loc" \
      "Missing browser security headers leave clients exposed to protocol downgrade (missing HSTS), clickjacking (missing X-Frame-Options/CSP), MIME-sniffing (missing X-Content-Type-Options), and referrer leakage." \
      "Add the following inside your HTTPS 'server {' block in ${first_srv_loc%:*}:
   add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains\" always;
   add_header X-Frame-Options \"SAMEORIGIN\" always;
   add_header X-Content-Type-Options \"nosniff\" always;
   add_header Referrer-Policy \"strict-origin-when-cross-origin\" always;
   add_header Permissions-Policy \"geolocation=(), microphone=(), camera=()\" always;
   add_header Content-Security-Policy \"default-src 'self';\" always;" \
      "https://owasp.org/www-project-secure-headers/"
  fi

  # 8. Check Rate Limiting (limit_req_zone / limit_req)
  if ! grep -qE 'limit_req_zone' "$clean" || ! grep -qE 'limit_req\s' "$clean"; then
    print_advice "WARN" \
      "Request rate limiting (limit_req_zone / limit_req) is not configured" \
      "$http_loc" \
      "Without request rate limiting, a single IP can flood dynamic endpoints, login pages, or upstream backends with brute-force or application-layer DoS traffic." \
      "1) Define a rate-limit zone inside 'http {' in ${CONF_PATH}:
   limit_req_zone \$binary_remote_addr zone=req_limit_per_ip:10m rate=10r/s;
2) Apply the limit inside your 'server {' or 'location / {' block in ${first_srv_loc%:*}:
   limit_req zone=req_limit_per_ip burst=20 nodelay;" \
      "https://nginx.org/en/docs/http/ngx_http_limit_req_module.html"
  fi

  # 9. Check Dotfile Protection (/.git, /.env, /.htpasswd)
  if ! grep -qE 'location\s+~?\s*/\.\s*\{|location\s+~\s+/\\\.' "$clean"; then
    print_advice "WARN" \
      "No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd)" \
      "$first_srv_loc" \
      "If a deployment accidentally leaves a '.env' or '.git' folder in the document root, attackers can download credentials and source code directly." \
      "Add this block inside your 'server {' block in ${first_srv_loc%:*}:
   location ~ /\\.(?!well-known).* {
       deny all;
       access_log off;
       log_not_found off;
   }" \
      "https://nginx.org/en/docs/http/ngx_http_core_module.html#location"
  fi

  # 10. Check Host Firewall & Fail2ban
  if ! have fail2ban-client; then
    local f2b_cmd="sudo apt-get update && sudo apt-get install -y fail2ban"
    [[ "$PKG_FAMILY" == "dnf" || "$PKG_FAMILY" == "yum" ]] && f2b_cmd="sudo $PKG_FAMILY install -y fail2ban" || true
    [[ "$PKG_FAMILY" == "pacman" ]] && f2b_cmd="sudo pacman -S --noconfirm fail2ban" || true
    [[ "$PKG_FAMILY" == "zypper" ]] && f2b_cmd="sudo zypper install -y fail2ban" || true
    [[ "$PKG_FAMILY" == "apk" ]]    && f2b_cmd="sudo apk add fail2ban" || true
    print_advice "WARN" \
      "Fail2ban intrusion prevention is not installed" \
      "/etc" \
      "Fail2ban monitors Nginx access and error logs and automatically bans IPs that repeatedly trigger 401/403 authentication errors or vulnerability scans." \
      "Install Fail2ban using your distribution's package manager:
   ${f2b_cmd}" \
      "https://www.fail2ban.org/wiki/index.php/Main_Page"
  fi

  if (( issue_num == 0 )); then
    log_ok "No critical failures or warnings found! Your Nginx installation looks healthy."
  else
    printf "${C_BOLD}Summary:${C_RESET} Found ${C_BOLD}%d${C_RESET} actionable item(s) above.\n" "$issue_num"
    printf "Full report with all 17 audit sections: %s\n\n" "$(file_link "$DEFAULT_REPORT")"
  fi

  rm -rf "$tmpd"
}

########################
# Subcommand: help
########################
cmd_help() {
  cat <<EOF
${C_BOLD}nginx-ops.sh — Multi-Distro Nginx Operations, Diagnostics & Remediation CLI${C_RESET}

${C_BOLD}USAGE:${C_RESET}
  $(basename "$0") <command> [options]

${C_BOLD}SERVICE LIFECYCLE COMMANDS:${C_RESET}
  start                 Validate config (nginx -t) and start Nginx daemon
  stop                  Stop Nginx daemon gracefully
  restart               Validate config (nginx -t) and restart Nginx daemon
  reload                Validate config (nginx -t) and reload config with zero downtime
  enable                Enable Nginx service to start automatically at boot
  disable               Disable Nginx service from starting at boot
  test [--dump]         Test Nginx configuration syntax (pass --dump for full 'nginx -T')

${C_BOLD}STATUS, LOGS & DIAGNOSTIC COMMANDS:${C_RESET}
  status                Show fast operational dashboard (daemon, workers, sockets, vhosts)
  advise                Read-only remediation guide: explains WHAT is wrong, WHY, and HOW to fix it
  audit [args]          Run full 17-section audit via status_nginx.sh (generates nginx-audit-report.md)
  logs [options]        Inspect or live-tail Nginx error and access logs:
                          -e, --error           Error logs only
                          -a, --access          Access logs only
                          -d, --domain <name>   Filter logs for specific domain/vhost
                          -n, --lines <N>       Show last N lines (default: 50)
                          -f, --follow          Follow logs in real time (tail -f)
  help                  Show this help message

${C_BOLD}EXAMPLES:${C_RESET}
  ./nginx-ops.sh status
  ./nginx-ops.sh advise
  sudo ./nginx-ops.sh start
  sudo ./nginx-ops.sh reload
  ./nginx-ops.sh logs --error --lines 100
  ./nginx-ops.sh logs --domain nginx.localhost.com --follow
  sudo ./nginx-ops.sh audit -o ./nginx-audit-report.md
EOF
}

########################
# Main Dispatcher
########################
detect_environment

SUBCMD="${1:-help}"
shift || true

case "$SUBCMD" in
  start)                  cmd_start "$@" ;;
  stop)                   cmd_stop "$@" ;;
  restart)                cmd_restart "$@" ;;
  reload)                 cmd_reload "$@" ;;
  enable)                 cmd_enable "$@" ;;
  disable)                cmd_disable "$@" ;;
  test|check|configtest)  cmd_test "$@" ;;
  status|st)              cmd_status "$@" ;;
  logs|log)               cmd_logs "$@" ;;
  audit|report)           cmd_audit "$@" ;;
  advise|fix-guide|doctor) cmd_advise "$@" ;;
  help|-h|--help)         cmd_help ;;
  *)
    log_fail "Unknown command: '${SUBCMD}'"
    echo
    cmd_help
    exit 1
    ;;
esac
