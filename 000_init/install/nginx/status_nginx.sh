#!/usr/bin/env bash
#
# status_nginx.sh (nginx-audit) - Read-only Nginx server & admin diagnostic audit report
#
# Usage:   sudo ./status_nginx.sh [-o report.md] [-n LOG_LINES] [-d CERT_WARN_DAYS]
# Example: sudo ./status_nginx.sh -o ./nginx-audit-report.md -n 100000
#
# Makes NO changes to the system outside generating the audit report file.
# Run as root (sudo) for complete results (private key permissions, protected logs).

set -u
export LC_ALL=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${SCRIPT_DIR}/nginx-audit-report.md"
LOG_LINES=50000      # how many recent access/error log lines to analyse
CERT_WARN=30         # warn when certs expire within N days

while getopts "o:n:d:h" opt; do
  case $opt in
    o) REPORT="$OPTARG" ;;
    n) LOG_LINES="$OPTARG" ;;
    d) CERT_WARN="$OPTARG" ;;
    *) sed -n '2,10p' "$0"; exit 0 ;;
  esac
done

# ---------- output & color helpers ----------
if [ -t 1 ]; then
  R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[36m'; N=$'\e[0m'; BOLD=$'\e[1m'
else
  R=""; G=""; Y=""; B=""; N=""; BOLD=""
fi

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

RAW_OUT="$TMPD/raw_sections.md"
ISSUES_TSV="$TMPD/issues.tsv"
: > "$RAW_OUT"
: > "$ISSUES_TSV"

WARN_COUNT=0
FAIL_COUNT=0
OK_COUNT=0
CURRENT_SECTION="General"
CURRENT_ANCHOR="general"

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

emit() {
  printf '%s\n' "$1"
  printf '%s\n' "$1" >> "$RAW_OUT"
}

section() {
  CURRENT_SECTION="$1"
  CURRENT_ANCHOR=$(slugify "$1")
  printf '\n%s================================================================%s\n%s %s%s\n%s================================================================%s\n' "$B" "$N" "$BOLD" "$1" "$N" "$B" "$N"
  printf '\n<a id="%s"></a>\n\n## %s\n\n' "$CURRENT_ANCHOR" "$1" >> "$RAW_OUT"
}

sub() {
  printf '\n%s--- %s ---%s\n' "$BOLD" "$1" "$N"
  printf '\n### %s\n\n' "$1" >> "$RAW_OUT"
}

# Format a local file path (and optional :line) as a clickable file:// Markdown link
file_link() {
  local ref="$1"
  [ -z "$ref" ] && { echo "N/A"; return; }
  local path="${ref%:*}"
  local line=""
  if [[ "$ref" == *:* ]] && [[ "${ref##*:}" =~ ^[0-9]+$ ]]; then
    line="${ref##*:}"
  else
    path="$ref"
  fi
  local base
  base=$(basename "$path")
  if [ -n "$line" ]; then
    printf '[%s:%s](file://%s#L%s) (`%s:%s`)' "$base" "$line" "$path" "$line" "$path" "$line"
  else
    printf '[%s](file://%s) (`%s`)' "$base" "$path" "$path"
  fi
}

# Record a structured finding:
# record_issue "FAIL|WARN" "Title/Message" "file_path[:line]" "https://doc-link" "Remediation advice"
record_issue() {
  local sev="$1"
  local msg="$2"
  local loc="${3:-}"
  local doc="${4:-}"
  local fix="${5:-}"
  local id=""
  if [ "$sev" = "FAIL" ]; then
    FAIL_COUNT=$((FAIL_COUNT+1))
    id="FAIL-${FAIL_COUNT}"
    printf '  %s[FAIL] (%s)%s %s\n' "$R" "$id" "$N" "$msg"
    [ -n "$loc" ] && printf '         Location : %s\n' "$loc"
    [ -n "$doc" ] && printf '         Docs     : %s\n' "$doc"
    [ -n "$fix" ] && printf '         Fix      : %s\n' "$fix"
    printf -- '- **[FAIL] (`%s`)** %s\n' "$id" "$msg" >> "$RAW_OUT"
  else
    WARN_COUNT=$((WARN_COUNT+1))
    id="WARN-${WARN_COUNT}"
    printf '  %s[WARN] (%s)%s %s\n' "$Y" "$id" "$N" "$msg"
    [ -n "$loc" ] && printf '         Location : %s\n' "$loc"
    [ -n "$doc" ] && printf '         Docs     : %s\n' "$doc"
    [ -n "$fix" ] && printf '         Fix      : %s\n' "$fix"
    printf -- '- **[WARN] (`%s`)** %s\n' "$id" "$msg" >> "$RAW_OUT"
  fi
  local f_link="N/A"
  [ -n "$loc" ] && f_link=$(file_link "$loc")
  printf '  - **Where**: %s\n' "$f_link" >> "$RAW_OUT"
  [ -n "$doc" ] && printf '  - **Reference**: <%s>\n' "$doc" >> "$RAW_OUT"
  [ -n "$fix" ] && printf '  - **How to Fix**: %s\n' "$fix" >> "$RAW_OUT"

  # Save to TSV for top executive diagnostic table
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$sev" "$id" "$CURRENT_SECTION" "$CURRENT_ANCHOR" "$msg" "$f_link" "${doc:-N/A}" "${fix:-Review section details}" >> "$ISSUES_TSV"
}

ok() {
  printf '  %s[ OK ]%s %s\n' "$G" "$N" "$1"
  printf -- '- **[ OK ]** %s\n' "$1" >> "$RAW_OUT"
  OK_COUNT=$((OK_COUNT+1))
}

warn() {
  record_issue "WARN" "$1" "${2:-}" "${3:-}" "${4:-}"
}

fail() {
  record_issue "FAIL" "$1" "${2:-}" "${3:-}" "${4:-}"
}

info() {
  printf '  %s\n' "$1"
  printf -- '- %s\n' "$1" >> "$RAW_OUT"
}

code_block() {
  local content="$1"
  [ -z "$content" ] && return 0
  printf '%s\n' "$content" | sed 's/^/    /'
  printf '\n```text\n%s\n```\n\n' "$content" >> "$RAW_OUT"
}

have() { command -v "$1" >/dev/null 2>&1; }

IS_ROOT=0
[ "$(id -u)" -eq 0 ] && IS_ROOT=1

if [ "$IS_ROOT" -eq 0 ]; then
  printf '%s[NOTE] Not running as root - falling back to direct config file reader when private keys require root. Run with sudo for complete results.%s\n' "$Y" "$N"
fi

# ---------- locate nginx ----------
NGINX_BIN=$(command -v nginx || true)
[ -z "$NGINX_BIN" ] && for p in /usr/sbin/nginx /usr/local/sbin/nginx /usr/local/nginx/sbin/nginx /opt/nginx/sbin/nginx; do
  [ -x "$p" ] && NGINX_BIN="$p" && break
done
if [ -z "$NGINX_BIN" ]; then
  echo "nginx binary not found. Aborting."
  exit 1
fi

CONF_PATH=$("$NGINX_BIN" -V 2>&1 | grep -oE '\-\-conf-path=[^ ]+' | cut -d= -f2)
CONF_PATH=${CONF_PATH:-/etc/nginx/nginx.conf}
CONF_DIR=$(dirname "$CONF_PATH")

FULLCONF="$TMPD/full.conf"     # complete effective config
CLEAN="$TMPD/clean.conf"       # same, with comments stripped
LINEMAP="$TMPD/linemap.txt"    # file:line:content mapping for exact links

# Try nginx -T first (or sudo -n nginx -T if non-root has passwordless sudo)
if ! "$NGINX_BIN" -T >"$FULLCONF" 2>"$TMPD/test.err"; then
  if [ "$IS_ROOT" -eq 0 ] && have sudo && sudo -n true 2>/dev/null; then
    sudo -n "$NGINX_BIN" -T >"$FULLCONF" 2>"$TMPD/test.err" || true
  fi
fi

# Fallback config assembler when nginx -T fails (e.g., unreadable SSL private key or syntax error)
USED_FALLBACK_LOADER=0
if [ ! -s "$FULLCONF" ] && [ -r "$CONF_PATH" ]; then
  USED_FALLBACK_LOADER=1
  append_conf_file() {
    local f="$1"
    [ -r "$f" ] || return 0
    printf '# configuration file %s:\n' "$f" >> "$FULLCONF"
    cat "$f" >> "$FULLCONF"
    printf '\n' >> "$FULLCONF"
  }
  append_conf_file "$CONF_PATH"
  for inc_dir in "$CONF_DIR/modules-enabled" "$CONF_DIR/conf.d" "$CONF_DIR/sites-enabled"; do
    if [ -d "$inc_dir" ]; then
      for cf in "$inc_dir"/*; do
        [ -f "$cf" ] && [ -r "$cf" ] && append_conf_file "$cf"
      done
    fi
  done
fi

sed -E 's/#.*$//' "$FULLCONF" | sed -E '/^[[:space:]]*$/d' >"$CLEAN"

# Build line map: filepath:lineno:content
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
' "$FULLCONF" > "$LINEMAP"

# Helper to find the first file:line matching an extended regex in active config (or commented directive fallback)
find_conf_loc() {
  local regex="$1"
  local fallback="${2:-${CONF_PATH}:1}"
  local match
  # Pass 1: active (uncommented) directive match
  match=$(awk -F: -v re="$regex" '
    {
      line = substr($0, length($1) + length($2) + 3)
      sub(/#.*/, "", line)
      if (line ~ re) {
        print $1 ":" $2
        exit
      }
    }
  ' "$LINEMAP" 2>/dev/null || true)
  # Pass 2: commented-out directive match (e.g. "# server_tokens off;")
  if [ -z "$match" ]; then
    match=$(awk -F: -v re="$regex" '
      {
        line = substr($0, length($1) + length($2) + 3)
        if (line ~ re) {
          print $1 ":" $2
          exit
        }
      }
    ' "$LINEMAP" 2>/dev/null || true)
  fi
  if [ -n "$match" ]; then
    echo "$match"
  else
    echo "$fallback"
  fi
}

HTTP_BLOCK_LOC=$(find_conf_loc "^[[:space:]]*http[[:space:]]*\\{")
FIRST_SERVER_LOC=$(find_conf_loc "^[[:space:]]*server[[:space:]]*\\{")

REPORT_TIME="$(date '+%F %T %Z')"
HOST_FQDN="$(hostname -f 2>/dev/null || hostname)"
OS_NAME="$( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -s)"
NGX_VER=$("$NGINX_BIN" -v 2>&1 | sed 's/.*nginx\///')

printf '%sNGINX SERVER AUDIT REPORT%s\nGenerated : %s\nHost      : %s\n' "$BOLD" "$N" "$REPORT_TIME" "$HOST_FQDN"

# =====================================================================
section "1. SYSTEM OVERVIEW"
# =====================================================================
info "OS        : $OS_NAME"
info "Kernel    : $(uname -r)  ($(uname -m))"
info "Uptime    : $(uptime -p 2>/dev/null || uptime)"
info "Load avg  : $(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)   CPUs: $(nproc 2>/dev/null)"
have free && { sub "Memory"; code_block "$(free -h)"; }
sub "Disk usage"
code_block "$(df -hT -x tmpfs -x devtmpfs -x squashfs 2>/dev/null)"
sub "Disk inodes"
code_block "$(df -i -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | head -n 10)"
while read -r pc mp; do
  [ -z "$pc" ] && continue
  p=${pc%\%}
  if [ "$p" -ge 90 ] 2>/dev/null; then
    warn "Filesystem $mp is ${pc} full" "$mp" \
      "https://docs.nginx.com/nginx/admin-guide/monitoring/logging/" \
      "Free disk space on $mp or rotate/compress old logs in /var/log/nginx"
  fi
done < <(df --output=pcent,target -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | tail -n +2)
sub "Public / local IPs"
IP_OUT=$(ip -br addr 2>/dev/null | grep -v '^lo' || hostname -I 2>/dev/null || echo "N/A")
code_block "$IP_OUT"

# =====================================================================
section "2. NGINX BINARY & BUILD"
# =====================================================================
info "Binary    : $(file_link "$NGINX_BIN")"
info "Version   : $NGX_VER"
info "Config    : $(file_link "$CONF_PATH")"
sub "Build info (nginx -V)"
code_block "$("$NGINX_BIN" -V 2>&1 | sed 's/ --/\n    --/g')"
sub "Modules compiled in / dynamic"
MODS_OUT=$(
  "$NGINX_BIN" -V 2>&1 | grep -oE '\-\-(with|add)[a-z_-]*module[^ ]*' | sort
  ls "$CONF_DIR"/modules-enabled 2>/dev/null | sed 's/^/dynamic: /'
  grep -E '^\s*load_module' "$CLEAN" 2>/dev/null || true
)
code_block "$MODS_OUT"

sub "Package info"
if have dpkg; then
  code_block "$(dpkg -l 2>/dev/null | awk '/^ii +(nginx|libnginx)/{print $2" "$3}')"
elif have rpm; then
  code_block "$(rpm -qa 2>/dev/null | grep -i nginx)"
fi
sub "Update availability"
if have apt-get; then
  up=$(apt list --upgradable 2>/dev/null | grep -i nginx || true)
  if [ -n "$up" ]; then
    warn "Nginx package update available: $up" "/etc/apt/sources.list" \
      "https://nginx.org/en/security_advisories.html" \
      "Run: sudo apt-get update && sudo apt-get install --only-upgrade -y nginx"
  else
    ok "No nginx update pending (per local apt cache)"
  fi
elif have yum; then
  if yum -q check-update nginx >/dev/null 2>&1; then
    ok "No nginx update pending"
  else
    warn "Nginx package update available" "/etc/yum.repos.d" \
      "https://nginx.org/en/security_advisories.html" \
      "Run: sudo yum update -y nginx"
  fi
fi
info "Security Advisories: https://nginx.org/en/security_advisories.html"

# =====================================================================
section "3. SERVICE STATUS & PROCESSES"
# =====================================================================
SYSTEMD_RUNNING=0
[ -d /run/systemd/system ] && have systemctl && SYSTEMD_RUNNING=1

if [ "$SYSTEMD_RUNNING" -eq 1 ] && systemctl list-unit-files 2>/dev/null | grep -q '^nginx'; then
  if systemctl is-active --quiet nginx; then
    ok "nginx systemd service is ACTIVE"
  else
    fail "nginx systemd service is NOT active" "/lib/systemd/system/nginx.service" \
      "https://nginx.org/en/docs/control.html" \
      "Test config and start Nginx: sudo nginx -t && sudo systemctl start nginx (check logs: sudo journalctl -u nginx -n 30)"
  fi
  if systemctl is-enabled --quiet nginx 2>/dev/null; then
    ok "nginx service is enabled at boot"
  else
    warn "nginx service is NOT enabled at boot" "/lib/systemd/system/nginx.service" \
      "https://www.freedesktop.org/software/systemd/man/systemctl.html" \
      "Enable service at boot: sudo systemctl enable nginx"
  fi
  code_block "$(systemctl status nginx --no-pager -n 0 2>/dev/null | head -n 15)"
  sub "Recent service journal (last 10)"
  code_block "$(journalctl -u nginx --no-pager -n 10 2>/dev/null)"
else
  INIT_SCRIPT="/etc/init.d/nginx"
  [ ! -e "$INIT_SCRIPT" ] && INIT_SCRIPT="$CONF_PATH"
  if pgrep -x nginx >/dev/null 2>&1; then
    ok "nginx process is running (non-systemd init)"
  else
    fail "nginx daemon is NOT running (0 active nginx processes)" "$INIT_SCRIPT" \
      "https://nginx.org/en/docs/control.html" \
      "Verify config and start service: sudo nginx -t && sudo service nginx start (or sudo nginx)"
  fi
  if [ -x /etc/init.d/nginx ]; then
    if ls /etc/rc*.d/S*nginx* >/dev/null 2>&1; then
      ok "SysVinit boot links present (/etc/rc*.d/S*nginx)"
    else
      warn "Nginx init script not enabled in default runlevels" "/etc/init.d/nginx" \
        "https://manpages.debian.org/bookworm/init-system-helpers/update-rc.d.8.en.html" \
        "Enable at boot: sudo update-rc.d nginx defaults"
    fi
  fi
fi

sub "Config syntax test (nginx -t)"
if grep -q 'syntax is ok' "$TMPD/test.err" && grep -q 'test is successful' "$TMPD/test.err"; then
  ok "Configuration syntax OK (nginx -t passed)"
else
  # Prioritize [emerg] / [alert] / [crit] lines over [warn] when locating the failure
  EMERG_LINE=$(grep -E '\[(emerg|alert|crit)\]' "$TMPD/test.err" | tail -n 1 || true)
  ERR_FILE_LINE=$(echo "$EMERG_LINE" | grep -oE '/[^ ":]+:[0-9]+' | tail -n 1 || true)
  [ -z "$ERR_FILE_LINE" ] && ERR_FILE_LINE=$(grep -v '\[warn\]' "$TMPD/test.err" | grep -oE '/[^ ":]+:[0-9]+' | tail -n 1 || true)
  ERR_KEY_PATH=$(grep -oE 'cannot load certificate( key)? "[^"]+"' "$TMPD/test.err" | sed -E 's/.*"([^"]+)"/\1/' | head -n 1 || true)
  if [ -n "$ERR_KEY_PATH" ] && [ -z "$ERR_FILE_LINE" ]; then
    ERR_FILE_LINE=$(find_conf_loc "$ERR_KEY_PATH" "$ERR_KEY_PATH")
  fi
  TARGET_LOC="${ERR_FILE_LINE:-${ERR_KEY_PATH:-$CONF_PATH}}"
  if [ "$IS_ROOT" -eq 0 ] && grep -qi 'Permission denied' "$TMPD/test.err"; then
    warn "nginx -t could not read restricted file '${ERR_KEY_PATH:-$TARGET_LOC}' as non-root user" "$TARGET_LOC" \
      "https://nginx.org/en/docs/switches.html" \
      "Run audit or syntax test with root privileges: sudo $0 (or sudo nginx -t)"
  else
    fail "Configuration test (nginx -t) failed" "$TARGET_LOC" \
      "https://nginx.org/en/docs/ngx_core_module.html" \
      "Inspect $(basename "${TARGET_LOC%:*}") and run: sudo nginx -t"
  fi
  code_block "$(cat "$TMPD/test.err")"
fi

if [ "$USED_FALLBACK_LOADER" -eq 1 ]; then
  info "Note: Effective config was loaded via direct file inclusion because 'nginx -T' exited non-zero."
fi

sub "Processes"
PS_NGX=$(ps -o pid,ppid,user,%cpu,%mem,rss,etime,cmd -C nginx 2>/dev/null | cut -c1-140 || true)
code_block "$PS_NGX"
NW=$(pgrep -f 'nginx: worker' 2>/dev/null | wc -l | tr -d ' ')
MP=$(pgrep -o -x nginx 2>/dev/null || true)

if [ -n "$MP" ]; then
  MASTER_USER=$(ps -o user= -p "$MP" 2>/dev/null | tr -d ' ')
  WORKER_USER=$(ps -o user= -C nginx 2>/dev/null | awk '{print $1}' | sort -u | grep -v '^root$' | head -n1 || true)
  [ "$MASTER_USER" = "root" ] && ok "Master runs as root (normal, needed for ports <1024)"
  if [ -n "$WORKER_USER" ]; then
    ok "Workers run as non-root user: $WORKER_USER"
  elif [ "$NW" -gt 0 ]; then
    USER_DIR_LOC=$(find_conf_loc "^[[:space:]]*user[[:space:]]")
    fail "Nginx worker processes are running as root!" "$USER_DIR_LOC" \
      "https://nginx.org/en/docs/ngx_core_module.html#user" \
      "Set 'user www-data;' (or 'user nginx;') at the top of $CONF_PATH and reload Nginx"
  fi
else
  info "No running nginx master/worker processes to inspect."
fi
info "Active worker processes: $NW   (CPU cores: $(nproc 2>/dev/null || echo 1))"
PIDF=$(grep -E '^\s*pid\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1 || true)
info "PID file configured: ${PIDF:-/run/nginx.pid (default)}"
if [ -n "$MP" ] && [ -r "/proc/$MP/limits" ]; then
  sub "Open-file limit of master"
  code_block "$(grep -i 'open files' "/proc/$MP/limits")"
  info "Open FDs (master): $(ls "/proc/$MP/fd" 2>/dev/null | wc -l)"
fi

# =====================================================================
section "4. LISTENING PORTS & CONNECTIONS"
# =====================================================================
sub "Sockets owned by nginx"
if have ss; then
  SOCK_OUT=$(ss -tulnp 2>/dev/null | grep -i nginx || true)
else
  SOCK_OUT=$(netstat -tulnp 2>/dev/null | grep -i nginx || true)
fi
code_block "${SOCK_OUT:-(no active sockets owned by nginx)}"

sub "Ports declared in config"
PORTS_DECL=$(grep -E '^\s*listen\s' "$CLEAN" | sed -E 's/^\s*listen\s+//; s/;//' | sort | uniq -c | sort -rn || true)
code_block "${PORTS_DECL:-(none)}"

if have ss; then
  sub "TCP connection states (all :80/:443 traffic)"
  TCP_STATES=$(ss -tan '( sport = :80 or sport = :443 )' 2>/dev/null | awk 'NR>1{c[$1]++} END{for(s in c) printf "%-14s %d\n", s, c[s]}' || true)
  code_block "${TCP_STATES:-(no active :80/:443 connections)}"
  sub "Top 10 client IPs currently connected"
  TOP_IPS=$(ss -tn '( sport = :80 or sport = :443 )' 2>/dev/null | awk 'NR>1{split($5,a,":"); sub(/:[0-9]+$/,"",$5); print $5}' | sort | uniq -c | sort -rn | head -n 10 || true)
  code_block "${TOP_IPS:-(none)}"
fi
sub "Other services listening publicly (potential exposure)"
PUB_LISTEN=$(ss -tlnH 2>/dev/null | awk '{print $4}' | grep -vE '^(127\.|\[::1\]|::1)' | head -n 25 || true)
code_block "${PUB_LISTEN:-(none detected)}"

# =====================================================================
section "5. CONFIGURATION FILES & LAYOUT"
# =====================================================================
info "Main config dir: $(file_link "$CONF_DIR")"
sub "Files loaded"
LOADED_FILES=$(grep -E '^# configuration file ' "$FULLCONF" | sed 's/^# configuration file //; s/:$//' | sort -u || true)
while IFS= read -r lf; do
  [ -n "$lf" ] && info "Loaded: $(file_link "$lf")"
done <<< "$LOADED_FILES"

sub "Directory tree"
TREE_OUT=""
for d in sites-available sites-enabled conf.d snippets modules-enabled; do
  if [ -d "$CONF_DIR/$d" ]; then
    TREE_OUT="${TREE_OUT}${CONF_DIR}/${d}:\n$(ls -la "$CONF_DIR/$d" | tail -n +4 | sed 's/^/  /')\n"
  fi
done
code_block "$(printf '%b' "$TREE_OUT")"

sub "Broken symlinks in nginx config dir"
BL=$(find "$CONF_DIR" -xtype l 2>/dev/null || true)
if [ -n "$BL" ]; then
  FIRST_BL=$(echo "$BL" | head -n1)
  fail "Broken symlink(s) found in $CONF_DIR: $(echo "$BL" | tr '\n' ' ')" "$FIRST_BL" \
    "https://nginx.org/en/docs/ngx_core_module.html#include" \
    "Remove broken symlink or fix target: sudo rm -i $FIRST_BL"
else
  ok "No broken symlinks in $CONF_DIR"
fi

sub "Sites available but NOT enabled"
if [ -d "$CONF_DIR/sites-available" ] && [ -d "$CONF_DIR/sites-enabled" ]; then
  for f in "$CONF_DIR"/sites-available/*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    [ -e "$CONF_DIR/sites-enabled/$b" ] || info "Disabled site: $(file_link "$f")"
  done
fi

sub "Core / global settings"
CORE_SETTINGS=""
for k in user worker_processes worker_connections worker_rlimit_nofile multi_accept use keepalive_timeout keepalive_requests sendfile tcp_nopush tcp_nodelay types_hash_max_size client_max_body_size client_body_timeout client_header_timeout send_timeout gzip gzip_comp_level brotli error_log access_log; do
  v=$(grep -E "^\s*$k\s" "$CLEAN" | sed -E 's/^\s+//' | sort -u | head -n 4 || true)
  [ -n "$v" ] && CORE_SETTINGS="${CORE_SETTINGS}${v}\n"
done
code_block "$(printf '%b' "$CORE_SETTINGS")"
W=$(grep -E '^\s*worker_processes' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1 || true)
[ "$W" = "auto" ] && ok "worker_processes auto" || info "worker_processes = ${W:-default(1)} (consider 'auto' in $(file_link "$CONF_PATH"))"

# =====================================================================
section "6. SITES / VIRTUAL HOSTS (parsed from effective config)"
# =====================================================================
VHOSTS_OUT=$(awk '
function val(s,k,  t){ t=s; sub("^[ \t]*" k "[ \t]+","",t); sub(/[ \t]*;.*/,"",t); return t }
/^# configuration file /{ f=$4; sub(/:$/,"",f); fline=0; next }
{
  fline++
  line=$0; sub(/#.*/,"",line)
  if (!ins && line ~ /^[ \t]*server[ \t]*\{/) {
    ins=1; depth=0; n++; file[n]=f ":" fline; lis[n]=""; sn[n]=""; rt[n]=""; ssl[n]=""; key[n]=""; px[n]=""; rtn[n]=""; fcgi[n]=""; idx[n]=""; ai[n]=""; al[n]=""; loc[n]=0; auth[n]=""; acl[n]=""
  }
  if (ins) {
    if (line ~ /^[ \t]*listen[ \t]/)        lis[n]=lis[n] (lis[n]?" | ":"") val(line,"listen")
    if (line ~ /^[ \t]*server_name[ \t]/)   sn[n]=val(line,"server_name")
    if (line ~ /^[ \t]*root[ \t]/ && rt[n]=="") rt[n]=val(line,"root")
    if (line ~ /^[ \t]*alias[ \t]/ && rt[n]=="") rt[n]="alias:" val(line,"alias")
    if (line ~ /^[ \t]*ssl_certificate[ \t]/)     ssl[n]=val(line,"ssl_certificate")
    if (line ~ /^[ \t]*ssl_certificate_key[ \t]/) key[n]=val(line,"ssl_certificate_key")
    if (line ~ /^[ \t]*proxy_pass[ \t]/)    px[n]=px[n] (px[n]?", ":"") val(line,"proxy_pass")
    if (line ~ /^[ \t]*fastcgi_pass[ \t]/)  fcgi[n]=fcgi[n] (fcgi[n]?", ":"") val(line,"fastcgi_pass")
    if (line ~ /^[ \t]*uwsgi_pass[ \t]/)    fcgi[n]=fcgi[n] (fcgi[n]?", ":"") val(line,"uwsgi_pass")
    if (line ~ /^[ \t]*grpc_pass[ \t]/)     px[n]=px[n] (px[n]?", ":"") val(line,"grpc_pass")
    if (line ~ /^[ \t]*return[ \t]/ )       rtn[n]=rtn[n] (rtn[n]?" ; ":"") val(line,"return")
    if (line ~ /^[ \t]*autoindex[ \t]+on/)  ai[n]="ON"
    if (line ~ /^[ \t]*access_log[ \t]/)    al[n]=val(line,"access_log")
    if (line ~ /^[ \t]*auth_basic[ \t]/ && line !~ /off/) auth[n]="basic-auth"
    if (line ~ /^[ \t]*(allow|deny)[ \t]/)  acl[n]="ip-acl"
    if (line ~ /^[ \t]*location[ \t]/)      loc[n]++
    o=gsub(/\{/,"{",line); c=gsub(/\}/,"}",line); depth+=o-c
    if (depth<=0) ins=0
  }
}
END{
  if(!n){ print "No server blocks found."; exit }
  for(i=1;i<=n;i++){
    printf "[%d] %s\n", i, (sn[i]==""?"(no server_name)":sn[i])
    printf "    file       : %s\n", file[i]
    printf "    listen     : %s\n", lis[i]
    if (rt[i]!="")   printf "    root       : %s\n", rt[i]
    if (px[i]!="")   printf "    proxy_pass : %s\n", px[i]
    if (fcgi[i]!="") printf "    backend    : %s\n", fcgi[i]
    if (rtn[i]!="")  printf "    return     : %s\n", rtn[i]
    if (ssl[i]!="")  printf "    ssl cert   : %s\n    ssl key    : %s\n", ssl[i], key[i]
    if (al[i]!="")   printf "    access_log : %s\n", al[i]
    printf "    locations  : %d   %s %s %s\n\n", loc[i], (auth[i]?"["auth[i]"]":""), (acl[i]?"["acl[i]"]":""), (ai[i]?"[AUTOINDEX ON]":"")
  }
  printf "Total server blocks: %d\n", n
}' "$FULLCONF")
code_block "$VHOSTS_OUT"

sub "Domains (unique server_names)"
DOMAINS_OUT=$(grep -E '^\s*server_name\s' "$CLEAN" | sed -E 's/^\s*server_name\s+//; s/;//' | tr ' ' '\n' | grep -v '^$' | sort -u || true)
code_block "${DOMAINS_OUT:-(none)}"

sub "Default servers"
DS=$(grep -E 'listen.*default_server' "$CLEAN" || true)
if [ -n "$DS" ]; then
  ok "Explicit default_server configured"
  code_block "$DS"
else
  warn "No explicit default_server configured - first server block per port answers unknown Host headers" "$FIRST_SERVER_LOC" \
    "https://nginx.org/en/docs/http/request_processing.html" \
    "Add a catch-all server block with 'listen 80 default_server; server_name _; return 444;'"
fi

sub "Upstream blocks"
UPSTREAMS_OUT=$(awk '/^[ \t]*upstream[ \t]/{p=1} p{print $0} p&&/\}/{p=0}' "$CLEAN" || true)
code_block "${UPSTREAMS_OUT:-(no upstream blocks defined)}"

sub "Location blocks summary"
LOCS_OUT=$(grep -E '^\s*location\s' "$CLEAN" | sed -E 's/^\s+//' | sort | uniq -c | sort -rn | head -n 30 || true)
code_block "${LOCS_OUT:-(none)}"

sub "Web root(s): size & owner"
while read -r r; do
  [ -z "$r" ] && continue
  if [ -d "$r" ]; then
    info "Web root $(file_link "$r") — size=$(du -sh "$r" 2>/dev/null | cut -f1) owner=$(stat -c %U:%G "$r") perms=$(stat -c %a "$r")"
  else
    ROOT_DIR_LOC=$(find_conf_loc "root[[:space:]]+${r}")
    warn "Configured web root directory does not exist: $r" "$ROOT_DIR_LOC" \
      "https://nginx.org/en/docs/http/ngx_http_core_module.html#root" \
      "Create directory 'sudo mkdir -p $r' or update the 'root' directive in $(basename "${ROOT_DIR_LOC%:*}")"
  fi
done < <(grep -E '^\s*root\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u)

# =====================================================================
section "7. SSL / TLS CERTIFICATES"
# =====================================================================
CERTS=$(grep -E '^\s*ssl_certificate\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u || true)
if [ -z "$CERTS" ]; then
  warn "No ssl_certificate directives found - HTTPS is not configured" "$FIRST_SERVER_LOC" \
    "https://nginx.org/en/docs/http/configuring_https_servers.html" \
    "Configure TLS certificates (e.g. via Certbot: sudo certbot --nginx) and listen on 443 ssl"
elif ! have openssl; then
  warn "openssl binary not installed; cannot inspect TLS certificates" "$FIRST_SERVER_LOC" \
    "https://docs.openssl.org/" \
    "Install openssl: sudo apt-get install -y openssl"
else
  NOW=$(date +%s)
  for c in $CERTS; do
    CERT_CONF_LOC=$(find_conf_loc "ssl_certificate[[:space:]]+${c}")
    if [ ! -r "$c" ]; then
      fail "Cannot read SSL certificate file: $c" "$CERT_CONF_LOC" \
        "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate" \
        "Verify certificate file exists at $c and permissions allow reading (or run script with sudo)"
      continue
    fi
    subj=$(openssl x509 -in "$c" -noout -subject 2>/dev/null | sed 's/subject=//')
    iss=$(openssl x509 -in "$c" -noout -issuer 2>/dev/null | sed 's/issuer=//')
    end=$(openssl x509 -in "$c" -noout -enddate 2>/dev/null | cut -d= -f2)
    san=$(openssl x509 -in "$c" -noout -ext subjectAltName 2>/dev/null | tail -n +2 | tr -d ' \n')
    sig=$(openssl x509 -in "$c" -noout -text 2>/dev/null | awk -F': ' '/Signature Algorithm/{print $2; exit}')
    bits=$(openssl x509 -in "$c" -noout -text 2>/dev/null | awk -F'[()]' '/Public-Key:/{print $2; exit}')
    ts=$(date -d "$end" +%s 2>/dev/null || echo "$NOW")
    days=$(( (ts-NOW)/86400 ))
    info "Certificate : $(file_link "$c") (configured at $(file_link "$CERT_CONF_LOC"))"
    info "  Subject   : $subj"
    info "  Issuer    : $iss"
    info "  SANs      : ${san:-n/a}"
    info "  Expires   : $end ($days days remaining)"
    info "  Key / Sig : $bits / $sig"
    if [ "$days" -lt 0 ]; then
      fail "SSL certificate $c EXPIRED $((-days)) days ago!" "$CERT_CONF_LOC" \
        "https://eff-certbot.readthedocs.io/en/latest/using.html#renewing-certificates" \
        "Renew or replace certificate immediately (e.g. sudo certbot renew) and reload nginx"
    elif [ "$days" -le 7 ]; then
      fail "SSL certificate $c expires in $days days!" "$CERT_CONF_LOC" \
        "https://eff-certbot.readthedocs.io/en/latest/using.html#renewing-certificates" \
        "Renew certificate urgently: sudo certbot renew && sudo systemctl reload nginx"
    elif [ "$days" -le "$CERT_WARN" ]; then
      warn "SSL certificate $c expires in $days days" "$CERT_CONF_LOC" \
        "https://eff-certbot.readthedocs.io/en/latest/using.html#renewing-certificates" \
        "Schedule or run certificate renewal: sudo certbot renew"
    else
      ok "Certificate $c validity OK ($days days remaining)"
    fi
    case "$sig" in
      *sha1*|*md5*)
        fail "Certificate $c uses weak signature algorithm ($sig)" "$CERT_CONF_LOC" \
          "https://ssl-config.mozilla.org/" \
          "Re-issue certificate signed with SHA-256 (sha256WithRSAEncryption or ECDSA)"
        ;;
    esac
  done

  sub "Private key permissions"
  while read -r k; do
    [ -z "$k" ] && continue
    KEY_CONF_LOC=$(find_conf_loc "ssl_certificate_key[[:space:]]+${k}")
    if [ ! -e "$k" ]; then
      if [ "$IS_ROOT" -eq 0 ]; then
        warn "Cannot inspect private key $k without root privileges (parent directory restricted)" "$KEY_CONF_LOC" \
          "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key" \
          "Re-run audit with sudo to verify private key permissions: sudo $0"
      else
        fail "SSL private key file is missing: $k" "$KEY_CONF_LOC" \
          "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key" \
          "Restore private key at $k or update ssl_certificate_key directive"
      fi
      continue
    fi
    p=$(stat -L -c %a "$k" 2>/dev/null || echo "")
    o=$(stat -L -c %U:%G "$k" 2>/dev/null || echo "")
    case "$p" in
      600|400|640|440) ok "Private key $k permissions OK ($p $o)" ;;
      *)
        fail "SSL private key $k has loose permissions ($p $o) - should be 600 or 640" "$k" \
          "https://ssl-config.mozilla.org/" \
          "Restrict key permissions: sudo chown root:root $k && sudo chmod 600 $k"
        ;;
    esac
  done < <(grep -E '^\s*ssl_certificate_key\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u)
fi
have certbot && {
  sub "Certbot certificates"
  code_block "$(certbot certificates 2>/dev/null)"
}
[ -d /etc/letsencrypt/live ] && info "Let's Encrypt live dir: $(ls /etc/letsencrypt/live 2>/dev/null | tr '\n' ' ')"
[ -f /etc/cron.d/certbot ] && info "certbot cron present: $(file_link /etc/cron.d/certbot)"

# =====================================================================
section "8. SECURITY AUDIT (config-based)"
# =====================================================================
sub "Information disclosure"
st=$(grep -E '^\s*server_tokens\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | tr '\n' ' ' || true)
if echo "$st" | grep -q off; then
  ok "server_tokens off (Nginx version hidden)"
else
  ST_LOC=$(find_conf_loc "server_tokens")
  warn "server_tokens is not set to 'off' - Nginx version is exposed in HTTP headers and error pages" "$ST_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens" \
    "Uncomment or add 'server_tokens off;' inside the http {} block in $CONF_PATH"
fi

if grep -E '^\s*autoindex\s+on' "$CLEAN" >/dev/null 2>&1; then
  AI_LOC=$(find_conf_loc "^[[:space:]]*autoindex[[:space:]]+on")
  fail "Directory listing (autoindex on) is enabled" "$AI_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_autoindex_module.html#autoindex" \
    "Change 'autoindex on;' to 'autoindex off;' unless public directory browsing is intentionally required"
fi
grep -qE 'proxy_hide_header\s+X-Powered-By' "$CLEAN" && ok "X-Powered-By hidden from upstreams" || info "Consider adding: proxy_hide_header X-Powered-By;"

sub "TLS protocol & cipher policy"
pr=$(grep -E '^\s*ssl_protocols\s' "$CLEAN" | sed -E 's/^\s*ssl_protocols\s+//; s/;//' | sort -u || true)
SSL_PROTO_LOC=$(find_conf_loc "^[[:space:]]*ssl_protocols[[:space:]]")
if [ -z "$pr" ]; then
  info "ssl_protocols not explicitly set (using build default)"
else
  info "ssl_protocols configured: $(echo "$pr" | tr '\n' ' ')"
  if echo "$pr" | grep -qE 'SSLv|TLSv1( |$)|TLSv1\.1'; then
    fail "Deprecated/insecure TLS protocols enabled (SSLv3/TLSv1/TLSv1.1)" "$SSL_PROTO_LOC" \
      "https://ssl-config.mozilla.org/#server=nginx" \
      "Set 'ssl_protocols TLSv1.2 TLSv1.3;' in $CONF_PATH and remove TLSv1 / TLSv1.1"
  else
    ok "No legacy SSL/TLSv1.0/TLSv1.1 protocols enabled"
  fi
  if echo "$pr" | grep -q 'TLSv1.3'; then
    ok "TLSv1.3 enabled"
  else
    warn "TLSv1.3 is not enabled in ssl_protocols" "$SSL_PROTO_LOC" \
      "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_protocols" \
      "Include TLSv1.3 in ssl_protocols: 'ssl_protocols TLSv1.2 TLSv1.3;'"
  fi
fi

ci=$(grep -E '^\s*ssl_ciphers\s' "$CLEAN" | head -n1 || true)
if [ -n "$ci" ]; then
  info "$(echo "$ci" | sed 's/^\s*//')"
  if echo "$ci" | grep -qiE 'RC4|3DES|NULL|EXPORT|MD5|aNULL|DES-CBC'; then
    CIPH_LOC=$(find_conf_loc "^[[:space:]]*ssl_ciphers[[:space:]]")
    fail "Weak TLS cipher suites allowed in ssl_ciphers" "$CIPH_LOC" \
      "https://ssl-config.mozilla.org/#server=nginx" \
      "Update ssl_ciphers using Mozilla Intermediate TLS configuration"
  fi
else
  info "ssl_ciphers not explicitly set (OpenSSL defaults used)"
fi

if grep -qE 'ssl_session_cache' "$CLEAN"; then
  ok "ssl_session_cache configured"
else
  warn "ssl_session_cache is not configured (impacts TLS handshake performance)" "$HTTP_BLOCK_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache" \
    "Add 'ssl_session_cache shared:SSL:10m; ssl_session_timeout 1d;' in http {} block of $CONF_PATH"
fi

sub "Security headers (add_header)"
for h in "Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" "Content-Security-Policy" "Referrer-Policy" "Permissions-Policy"; do
  if grep -qiE "add_header\s+\"?$h" "$CLEAN"; then
    ok "Security header $h configured"
  else
    warn "HTTP security header '$h' is missing from configuration" "$FIRST_SERVER_LOC" \
      "https://owasp.org/www-project-secure-headers/" \
      "Add 'add_header $h \"...\" always;' to your server {} block or shared security snippet"
  fi
done

sub "HTTP -> HTTPS redirection"
if grep -qE 'return\s+30[12]\s+https://' "$CLEAN" || grep -qE 'rewrite .*https://.*permanent' "$CLEAN"; then
  ok "HTTP -> HTTPS redirect present"
elif grep -qE 'listen\s+(\[::\]:)?80' "$CLEAN"; then
  LISTEN80_LOC=$(find_conf_loc "listen[[:space:]]+(\\[::\\]:)?80")
  warn "Port 80 is served without an automatic HTTP -> HTTPS redirect" "$LISTEN80_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_rewrite_module.html#return" \
    "Add 'return 301 https://\$host\$request_uri;' in the port 80 server {} block"
fi
grep -qE 'listen.*443.*http2|http2\s+on' "$CLEAN" && ok "HTTP/2 enabled" || info "HTTP/2 not enabled (consider adding 'http2' to listen 443)"

sub "Rate limiting / DoS protection"
if grep -qE 'limit_req_zone' "$CLEAN"; then
  ok "limit_req_zone defined"
else
  warn "No limit_req_zone defined (no request rate limiting against brute-force/DDoS)" "$HTTP_BLOCK_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone" \
    "Add 'limit_req_zone \$binary_remote_addr zone=req_limit:10m rate=10r/s;' in http {} block of $CONF_PATH"
fi
if grep -qE 'limit_req\s' "$CLEAN"; then
  ok "limit_req applied"
else
  warn "limit_req is not applied to any server or location context" "$FIRST_SERVER_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req" \
    "Apply 'limit_req zone=req_limit burst=20 nodelay;' inside sensitive server/location blocks"
fi

cm=$(grep -E '^\s*client_max_body_size' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | tr '\n' ' ' || true)
[ -n "$cm" ] && info "client_max_body_size: $cm" || info "client_max_body_size default (1m)"
if echo "$cm" | grep -qE '(^| )0( |$)'; then
  CM_LOC=$(find_conf_loc "client_max_body_size[[:space:]]+0")
  warn "client_max_body_size is set to 0 (unlimited request body upload size)" "$CM_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size" \
    "Set an explicit upper bound such as 'client_max_body_size 25m;'"
fi

sub "Dangerous / risky patterns"
if grep -qE 'location\s+~?\s*/\.\s*\{|location\s+~\s+/\\\.' "$CLEAN"; then
  ok "Dotfile (/.git, /.env) blocking location rule present"
else
  warn "No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd)" "$FIRST_SERVER_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_core_module.html#location" \
    "Add 'location ~ /\\.(?!well-known).* { deny all; }' to server {} blocks"
fi

sub "Access control"
AUTH_BASIC_COUNT=$(grep -cE '^\s*auth_basic\s+"' "$CLEAN" 2>/dev/null || echo 0)
info "auth_basic protected locations: $AUTH_BASIC_COUNT"
while read -r f; do
  [ -z "$f" ] && continue
  if [ -e "$f" ]; then
    info "htpasswd $(file_link "$f") perms=$(stat -c %a "$f") owner=$(stat -c %U:%G "$f") users=$(grep -c . "$f")"
  else
    HT_LOC=$(find_conf_loc "auth_basic_user_file[[:space:]]+${f}")
    warn "Referenced auth_basic_user_file is missing: $f" "$HT_LOC" \
      "https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html#auth_basic_user_file" \
      "Create htpasswd file at $f or update auth_basic_user_file directive"
  fi
done < <(grep -E '^\s*auth_basic_user_file' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u)

sub "ModSecurity / WAF"
grep -qE 'modsecurity\s+on' "$CLEAN" && ok "ModSecurity enabled" || info "ModSecurity/WAF not detected in nginx"

# =====================================================================
section "9. FILE & DIRECTORY PERMISSIONS"
# =====================================================================
info "$(file_link "$CONF_PATH")  perms=$(stat -c %a "$CONF_PATH") owner=$(stat -c %U:%G "$CONF_PATH")"
WW=$(find "$CONF_DIR" -type f -perm -o+w 2>/dev/null || true)
if [ -n "$WW" ]; then
  FIRST_WW=$(echo "$WW" | head -n1)
  fail "World-writable configuration file(s) in $CONF_DIR: $(echo "$WW" | tr '\n' ' ')" "$FIRST_WW" \
    "https://www.cisecurity.org/benchmark/nginx" \
    "Remove world-write permissions: sudo chmod o-w $CONF_DIR -R"
else
  ok "No world-writable config files in $CONF_DIR"
fi

WD=$(find "$CONF_DIR" -type d -perm -o+w 2>/dev/null || true)
if [ -n "$WD" ]; then
  fail "World-writable configuration directory in $CONF_DIR: $WD" "$WD" \
    "https://www.cisecurity.org/benchmark/nginx" \
    "Fix directory permissions: sudo chmod 755 $WD"
fi

sub "Web roots - world-writable & sensitive files"
while read -r r; do
  [ -z "$r" ] || [ ! -d "$r" ] && continue
  out=$(find "$r" -xdev \( -type f -o -type d \) -perm -o+w 2>/dev/null | head -n 10 || true)
  if [ -n "$out" ]; then
    FIRST_WWR=$(echo "$out" | head -n1)
    warn "World-writable files/directories inside web root $r" "$FIRST_WWR" \
      "https://www.cisecurity.org/benchmark/nginx" \
      "Remove world-writable bit: sudo chmod -R o-w $r"
  else
    ok "Web root $r has no world-writable files"
  fi
  sens=$(find "$r" -xdev -type f \( -name '.env' -o -name '.git' -o -name '*.bak' -o -name '*.sql' -o -name '*.old' -o -name '*.swp' -o -name 'id_rsa' -o -name '.htpasswd' -o -name 'wp-config.php.*' \) 2>/dev/null | head -n 10 || true)
  if [ -n "$sens" ]; then
    FIRST_SENS=$(echo "$sens" | head -n1)
    fail "Sensitive file(s) exposed inside web root $r: $(echo "$sens" | tr '\n' ' ')" "$FIRST_SENS" \
      "https://owasp.org/www-project-web-security-testing-guide/" \
      "Move backup/secret files ($FIRST_SENS) outside the public web root $r"
  fi
  if [ -d "$r/.git" ]; then
    fail "Exposed .git repository inside web root: $r/.git" "$r/.git" \
      "https://owasp.org/www-project-web-security-testing-guide/" \
      "Remove $r/.git or block access via 'location ~ /\\.git { deny all; }'"
  fi
done < <(grep -E '^\s*root\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u)

sub "Log dir permissions"
code_block "$(ls -ld /var/log/nginx 2>/dev/null)"

# =====================================================================
section "10. SYSTEM-LEVEL HARDENING"
# =====================================================================
sub "Firewall"
if have ufw && ufw status >/dev/null 2>&1; then
  code_block "$(ufw status 2>/dev/null)"
elif have firewall-cmd && firewall-cmd --state >/dev/null 2>&1; then
  code_block "$(firewall-cmd --list-all 2>/dev/null)"
elif have nft && [ -n "$(nft list ruleset 2>/dev/null)" ]; then
  code_block "$(nft list ruleset 2>/dev/null | head -n 40)"
elif have iptables && [ -n "$(iptables -S 2>/dev/null)" ]; then
  code_block "$(iptables -S 2>/dev/null | head -n 40)"
else
  warn "No active host firewall rules detected ( or requires root to inspect iptables/nftables )" "/etc" \
    "https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29" \
    "Enable host firewall (e.g. sudo ufw allow 'Nginx Full' && sudo ufw enable) or run audit with sudo"
fi

sub "Fail2ban"
if have fail2ban-client; then
  if [ "$SYSTEMD_RUNNING" -eq 1 ] && systemctl is-active --quiet fail2ban; then
    ok "fail2ban service is active"
  elif pgrep -x fail2ban-server >/dev/null 2>&1; then
    ok "fail2ban-server process is active"
  else
    warn "fail2ban is installed but not currently active" "/etc/fail2ban" \
      "https://github.com/fail2ban/fail2ban/wiki" \
      "Start fail2ban service: sudo service fail2ban start (or sudo systemctl enable --now fail2ban)"
  fi
else
  warn "fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning)" "/etc" \
    "https://www.fail2ban.org/wiki/index.php/Main_Page" \
    "Install fail2ban: sudo apt-get install -y fail2ban"
fi

sub "SELinux / AppArmor"
have getenforce && info "SELinux: $(getenforce 2>/dev/null)"
have aa-status && code_block "$(aa-status 2>/dev/null | grep -iE 'nginx|profiles are loaded' || true)"

sub "Kernel network tunables relevant to web servers"
SYSCTL_OUT=""
for k in net.core.somaxconn net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_syncookies net.ipv4.ip_local_port_range net.ipv4.tcp_tw_reuse fs.file-max; do
  val=$(sysctl -n "$k" 2>/dev/null || cat "/proc/sys/${k//.//}" 2>/dev/null || echo "N/A")
  SYSCTL_OUT="${SYSCTL_OUT}$(printf '%-36s %s' "$k" "$val")\n"
done
code_block "$(printf '%b' "$SYSCTL_OUT")"

sub "Auto security updates"
[ -f /etc/apt/apt.conf.d/20auto-upgrades ] && code_block "$(cat /etc/apt/apt.conf.d/20auto-upgrades)"
sub "Pending security updates"
have apt && code_block "$(apt list --upgradable 2>/dev/null | grep -i security | head -n 10 || true)"
if [ -f /var/run/reboot-required ]; then
  warn "System reboot required to apply kernel/security updates" "/var/run/reboot-required" \
    "https://wiki.debian.org/UnattendedUpgrades" \
    "Schedule a maintenance window and reboot the host: sudo reboot"
fi

# =====================================================================
section "11. LOGS - LOCATIONS, SIZE, ROTATION"
# =====================================================================
ACCESS_LOGS=$(grep -E '^\s*access_log\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | grep -vE '^(off|syslog:)' | sort -u || true)
ERROR_LOGS=$(grep -E '^\s*error_log\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | grep -vE '^(syslog:|stderr|memory:)' | sort -u || true)
[ -z "$ACCESS_LOGS" ] && ACCESS_LOGS=/var/log/nginx/access.log
[ -z "$ERROR_LOGS" ] && ERROR_LOGS=/var/log/nginx/error.log
sub "Log files"
for l in $ACCESS_LOGS $ERROR_LOGS; do
  if [ -e "$l" ]; then
    info "Log file $(file_link "$l") — size=$(du -h "$l" 2>/dev/null | cut -f1) mtime=$(stat -c %y "$l" 2>/dev/null | cut -d. -f1)"
  else
    LOG_CONF_LOC=$(find_conf_loc "(access_log|error_log)[[:space:]]+${l}")
    warn "Configured log file does not exist: $l" "$LOG_CONF_LOC" \
      "https://nginx.org/en/docs/ngx_core_module.html#error_log" \
      "Ensure directory $(dirname "$l") exists and is writable by nginx: sudo mkdir -p $(dirname "$l")"
  fi
done
info "Total /var/log/nginx size: $(du -sh /var/log/nginx 2>/dev/null | cut -f1 || echo N/A)"

sub "logrotate"
if [ -f /etc/logrotate.d/nginx ]; then
  ok "logrotate config present at $(file_link /etc/logrotate.d/nginx)"
  code_block "$(cat /etc/logrotate.d/nginx)"
else
  warn "/etc/logrotate.d/nginx not found (logs may grow unbounded)" "/etc/logrotate.d" \
    "https://manpages.debian.org/bookworm/logrotate/logrotate.8.en.html" \
    "Create /etc/logrotate.d/nginx to rotate /var/log/nginx/*.log daily"
fi
BIGL=$(find /var/log/nginx -type f -size +500M 2>/dev/null || true)
if [ -n "$BIGL" ]; then
  FIRST_BIGL=$(echo "$BIGL" | head -n1)
  warn "Log file(s) over 500MB detected: $(echo "$BIGL" | tr '\n' ' ')" "$FIRST_BIGL" \
    "https://manpages.debian.org/bookworm/logrotate/logrotate.8.en.html" \
    "Force log rotation now: sudo logrotate -f /etc/logrotate.d/nginx"
fi

# =====================================================================
section "12. ERROR LOG ANALYSIS"
# =====================================================================
ANY_ERR_READ=0
for el in $ERROR_LOGS; do
  if [ ! -r "$el" ]; then
    info "Cannot read error log $(file_link "$el") (run with sudo to analyse error log contents)"
    continue
  fi
  ANY_ERR_READ=1
  info "Analysing error log: $(file_link "$el")"
  if [ ! -s "$el" ]; then
    ok "Error log $el is empty (0 errors recorded)"
    continue
  fi
  sub "Entries by severity (last $LOG_LINES lines)"
  code_block "$(tail -n "$LOG_LINES" "$el" | grep -oE '\[(debug|info|notice|warn|error|crit|alert|emerg)\]' | sort | uniq -c | sort -rn || true)"
  sub "Top 10 error messages"
  code_block "$(tail -n "$LOG_LINES" "$el" | sed -E 's/^[0-9\/]+ [0-9:]+ //; s/\[[a-z]+\] [0-9#]+: \*[0-9]+ //; s/client: [0-9a-f.:]+/client: X/; s/request: "[^"]*"/request: "..."/; s/, host: "[^"]*"//; s/upstream: "[^"]*"/upstream: "..."/; s/referrer: "[^"]*"//' | cut -c1-120 | sort | uniq -c | sort -rn | head -n 10 || true)"
  sub "Last 15 error/crit entries"
  code_block "$(tail -n "$LOG_LINES" "$el" | grep -E '\[(error|crit|alert|emerg)\]' | tail -n 15 | cut -c1-220 || true)"

  if tail -n "$LOG_LINES" "$el" | grep -qE 'too many open files|worker_connections are not enough'; then
    fail "Resource limit errors in $el (too many open files / worker_connections)" "$el" \
      "https://nginx.org/en/docs/ngx_core_module.html#worker_connections" \
      "Increase 'worker_rlimit_nofile' and 'worker_connections' in $CONF_PATH"
  fi
  if tail -n "$LOG_LINES" "$el" | grep -qE 'upstream (timed out|prematurely closed)|connect\(\) failed'; then
    warn "Upstream/backend connection errors found in $el" "$el" \
      "https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout" \
      "Check backend service health and inspect recent lines in $el"
  fi
done

# =====================================================================
section "13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)"
# =====================================================================
for al in $ACCESS_LOGS; do
  if [ ! -r "$al" ]; then
    info "Cannot read access log $(file_link "$al") (run with sudo to analyse traffic)"
    continue
  fi
  total=$(wc -l <"$al")
  info "Analysing access log: $(file_link "$al") (last $LOG_LINES of $total lines)"
  tail -n "$LOG_LINES" "$al" >"$TMPD/acc.log"
  if [ ! -s "$TMPD/acc.log" ]; then
    info "Access log $al is empty."
    continue
  fi
  first=$(head -n1 "$TMPD/acc.log" | grep -oE '\[[^]]+\]' | head -n1 || true)
  last=$(tail -n1 "$TMPD/acc.log" | grep -oE '\[[^]]+\]' | head -n1 || true)
  info "Time range: ${first:-N/A}  ->  ${last:-N/A}"
  sub "HTTP status code distribution"
  code_block "$(awk '{print $9}' "$TMPD/acc.log" | grep -E '^[1-5][0-9][0-9]$' | sort | uniq -c | sort -rn || true)"
  sub "Status classes"
  code_block "$(awk '$9 ~ /^[1-5][0-9][0-9]$/{c=substr($9,1,1)"xx"; n[c]++; t++} END{for(k in n) printf "%s  %6d  (%.1f%%)\n",k,n[k],n[k]*100/t}' "$TMPD/acc.log" | sort || true)"
  e5=$(awk '$9 ~ /^5/' "$TMPD/acc.log" | wc -l)
  tt=$(wc -l <"$TMPD/acc.log")
  if [ "$tt" -gt 0 ] && [ $((e5*100/tt)) -ge 5 ]; then
    fail "High HTTP 5xx error rate >= 5% ($e5 of $tt requests) in $al" "$al" \
      "https://docs.nginx.com/nginx/admin-guide/monitoring/logging/" \
      "Inspect top 5xx URLs in $al and correlate with $ERROR_LOGS"
  fi
  sub "Top 15 client IPs"
  code_block "$(awk '{print $1}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 15 || true)"
  sub "Top 15 requested URLs"
  code_block "$(awk '{print $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 15 || true)"
  sub "Top 10 URLs returning 404"
  code_block "$(awk '$9==404{print $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 10 || true)"
  sub "Top 10 URLs returning 5xx"
  code_block "$(awk '$9 ~ /^5/{print $9, $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 10 || true)"
done

# =====================================================================
section "14. LIVE ENDPOINT CHECKS (localhost)"
# =====================================================================
if have curl; then
  for u in http://127.0.0.1 https://127.0.0.1; do
    info "Probing $u (Host: localhost, -k)"
    CURL_OUT=$(curl -skI --max-time 5 "$u" 2>/dev/null | head -n 15 || true)
    code_block "${CURL_OUT:-(no response from $u)}"
  done
  sub "Security headers on first named server over HTTPS"
  d=$(grep -E '^\s*server_name\s' "$CLEAN" | sed -E 's/^\s*server_name\s+//; s/;//' | tr ' ' '\n' | grep -E '^[a-zA-Z0-9.-]+\.[a-z]{2,}$' | head -n 1 || true)
  if [ -n "$d" ]; then
    info "Testing $d via --resolve $d:443:127.0.0.1"
    H=$(curl -skI --max-time 8 --resolve "$d:443:127.0.0.1" "https://$d/" 2>/dev/null || true)
    if [ -n "$H" ]; then
      code_block "$(echo "$H" | head -n 20)"
      if echo "$H" | grep -qi '^server:.*nginx/[0-9]'; then
        warn "Live HTTPS response Server header discloses exact Nginx version" "$HTTP_BLOCK_LOC" \
          "https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens" \
          "Set 'server_tokens off;' in $CONF_PATH and reload Nginx"
      fi
      if echo "$H" | grep -qi 'strict-transport'; then
        ok "Live HTTPS response includes HSTS header"
      else
        warn "Live HTTPS response on $d is missing Strict-Transport-Security (HSTS) header" "$FIRST_SERVER_LOC" \
          "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security" \
          "Add 'add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains\" always;' to the HTTPS server block"
      fi
    else
      info "No live HTTPS response on 127.0.0.1:443 for $d (daemon stopped or port not listening)"
    fi
  fi
else
  info "curl not installed - skipped live HTTP checks"
fi

if have openssl; then
  sub "TLS handshake test on 127.0.0.1:443"
  for v in tls1 tls1_1 tls1_2 tls1_3; do
    if echo | timeout 3 openssl s_client -connect 127.0.0.1:443 -"$v" >/dev/null 2>&1; then
      case $v in
        tls1|tls1_1)
          fail "Live endpoint 127.0.0.1:443 ACCEPTED deprecated protocol $v" "$SSL_PROTO_LOC" \
            "https://ssl-config.mozilla.org/#server=nginx" \
            "Disable TLSv1 and TLSv1.1 in ssl_protocols and reload Nginx"
          ;;
        *) ok "Live endpoint accepted $v" ;;
      esac
    else
      info "$v rejected or 127.0.0.1:443 not listening"
    fi
  done
fi

# =====================================================================
section "15. PERFORMANCE & CAPACITY HINTS"
# =====================================================================
WC=$(grep -E '^\s*worker_connections' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1 || true)
WC=${WC:-512}
[ "$W" = "auto" ] && WN=$(nproc 2>/dev/null || echo 1) || WN=${W:-1}
info "Theoretical max clients ~ worker_processes($WN) x worker_connections($WC) = $((WN*WC)) (halve for reverse proxy)"
RN=$(grep -E '^\s*worker_rlimit_nofile' "$CLEAN" | awk '{print $2}' | tr -d ';' || true)
[ -z "$RN" ] && info "worker_rlimit_nofile not set - ensure ulimit >= 2 x worker_connections"

if grep -qE '^\s*gzip\s+on' "$CLEAN"; then
  ok "gzip compression enabled"
else
  GZIP_LOC=$(find_conf_loc "gzip")
  warn "gzip compression is not enabled" "$GZIP_LOC" \
    "https://nginx.org/en/docs/http/ngx_http_gzip_module.html" \
    "Enable 'gzip on; gzip_types text/plain text/css application/json application/javascript text/xml;' in $CONF_PATH"
fi
grep -qE 'gzip_types' "$CLEAN" || info "gzip_types not set (only text/html compressed by default)"
grep -qE 'proxy_cache_path|fastcgi_cache_path' "$CLEAN" && ok "Proxy/FastCGI caching configured" || info "No proxy/fastcgi cache configured"
grep -qE 'expires|Cache-Control' "$CLEAN" && ok "Static caching headers present" || info "No expires/Cache-Control rules for static assets"
grep -qE '^\s*sendfile\s+on' "$CLEAN" && ok "sendfile on" || info "sendfile is not enabled"

sub "nginx memory (RSS)"
RSS_OUT=$(ps -C nginx -o rss= 2>/dev/null | awk '{s+=$1} END{printf "total RSS: %.1f MB across %d processes\n", s/1024, NR}')
code_block "$RSS_OUT"
sub "Top 5 processes by memory"
code_block "$(ps aux --sort=-%mem 2>/dev/null | head -n 6 | cut -c1-140)"
if have lsof; then
  sub "Files/sockets open by nginx"
  LSOF_COUNT=$(lsof -c nginx 2>/dev/null | wc -l | tr -d ' ')
  info "${LSOF_COUNT} open descriptors (lsof)"
fi

# =====================================================================
section "16. BACKENDS & RELATED SERVICES"
# =====================================================================
sub "Upstream/proxy targets reachability"
while read -r t; do
  [ -z "$t" ] && continue
  PASS_LOC=$(find_conf_loc "(proxy_pass|fastcgi_pass|uwsgi_pass|grpc_pass)[[:space:]]+${t}")
  case "$t" in
    unix:*)
      s=${t#unix:}
      s=${s%%:*}
      if [ -S "$s" ]; then
        ok "Backend UNIX socket $s exists"
      else
        fail "Backend UNIX socket is missing: $s (referenced by $t)" "$PASS_LOC" \
          "https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass" \
          "Start the upstream service (e.g. php-fpm / gunicorn / uwsgi) that creates socket $s"
      fi
      ;;
    http://*|https://*|*:*)
      hp=$(echo "$t" | sed -E 's#^https?://##; s#/.*##')
      h=${hp%:*}
      p=${hp##*:}
      [[ "$p" =~ ^[0-9]+$ ]] || p=$(echo "$t" | grep -q '^https' && echo 443 || echo 80)
      case "$h" in *'$'*) info "$t (uses runtime variable)"; continue ;; esac
      if timeout 3 bash -c "exec 3<>/dev/tcp/$h/$p" 2>/dev/null; then
        ok "Upstream backend $h:$p is reachable"
      else
        fail "Upstream backend $h:$p is NOT reachable (configured at $(basename "${PASS_LOC%:*}"))" "$PASS_LOC" \
          "https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass" \
          "Verify the backend application listening on $h:$p is running and check its logs"
      fi
      ;;
    *) info "$t (upstream group)" ;;
  esac
done < <(grep -E '^\s*(proxy_pass|fastcgi_pass|uwsgi_pass|grpc_pass)\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u)

sub "Common companion services"
COMP_OUT=""
for s in php-fpm php7.4-fpm php8.1-fpm php8.2-fpm php8.3-fpm mysql mariadb postgresql redis-server redis memcached docker fail2ban certbot.timer; do
  if [ "$SYSTEMD_RUNNING" -eq 1 ] && systemctl list-unit-files 2>/dev/null | grep -q "^$s"; then
    COMP_OUT="${COMP_OUT}$(printf '%-18s %s' "$s" "$(systemctl is-active "$s" 2>/dev/null)")\n"
  elif [ -x "/etc/init.d/${s%.timer}" ]; then
    st_out=$(service "${s%.timer}" status >/dev/null 2>&1 && echo "active (sysvinit)" || echo "inactive (sysvinit)")
    COMP_OUT="${COMP_OUT}$(printf '%-18s %s' "${s%.timer}" "$st_out")\n"
  fi
done
code_block "$(printf '%b' "${COMP_OUT:-(none detected)}")"

sub "Cron jobs mentioning nginx / certbot"
CRON_OUT=$(grep -rEl 'nginx|certbot' /etc/cron* /var/spool/cron 2>/dev/null || true)
if [ -n "$CRON_OUT" ]; then
  while IFS= read -r cf; do
    [ -n "$cf" ] && info "Cron file: $(file_link "$cf")"
  done <<< "$CRON_OUT"
else
  info "No cron files mentioning nginx or certbot"
fi

# =====================================================================
section "17. CONFIG BACKUP & CHANGE TRACKING"
# =====================================================================
info "10 most recently modified files in $CONF_DIR:"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  ts_part="${line%  *}"
  f_part="${line#*  }"
  info "$ts_part — $(file_link "$f_part")"
done < <(find "$CONF_DIR" -type f -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort -r | head -n 10)

[ -d "$CONF_DIR/.git" ] && ok "Config dir is tracked under git" || info "Config not under version control (consider git or etckeeper in $CONF_DIR)"
while IFS= read -r bf; do
  [ -n "$bf" ] && warn "Stray backup file inside config dir: $bf" "$bf" \
    "https://nginx.org/en/docs/ngx_core_module.html#include" \
    "Move backup file outside $CONF_DIR so wildcard include directives do not load it"
done < <(find "$CONF_DIR" -type f \( -name '*.bak' -o -name '*~' -o -name '*.old' -o -name '*.orig' -o -name '*.save' \) 2>/dev/null)

# =====================================================================
# ASSEMBLE FINAL MARKDOWN REPORT WITH EXECUTIVE SUMMARY & ISSUE LINKS
# =====================================================================
OVERALL_HEALTH="HEALTHY"
if [ "$FAIL_COUNT" -gt 0 ]; then
  OVERALL_HEALTH="CRITICAL (${FAIL_COUNT} FAIL, ${WARN_COUNT} WARN)"
elif [ "$WARN_COUNT" -gt 0 ]; then
  OVERALL_HEALTH="NEEDS ATTENTION (${WARN_COUNT} WARN)"
fi

mkdir -p "$(dirname "$REPORT")" 2>/dev/null || true

{
  printf '# Nginx Server Diagnostic & Security Audit Report\n\n'
  printf '| Property | Value |\n'
  printf '| :--- | :--- |\n'
  printf '| **Overall Health** | **%s** |\n' "$OVERALL_HEALTH"
  printf '| **Checks Summary** | **OK:** `%d` &nbsp; **WARN:** `%d` &nbsp; **FAIL:** `%d` |\n' "$OK_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
  printf '| **Generated At** | `%s` |\n' "$REPORT_TIME"
  printf '| **Host / OS** | `%s` (%s) |\n' "$HOST_FQDN" "$OS_NAME"
  printf '| **Nginx Version** | `nginx/%s` — Binary: %s |\n' "$NGX_VER" "$(file_link "$NGINX_BIN")"
  printf '| **Main Config** | %s |\n' "$(file_link "$CONF_PATH")"
  printf '| **Audit Script** | %s |\n\n' "$(file_link "${SCRIPT_DIR}/$(basename "$0")")"

  printf '## Quick Navigation\n\n'
  printf -- '- [Actionable Issues Index (Failures & Warnings)](#actionable-issues)\n'
  printf -- '- [1. System Overview](#1-system-overview)\n'
  printf -- '- [2. Nginx Binary & Build](#2-nginx-binary-build)\n'
  printf -- '- [3. Service Status & Processes](#3-service-status-processes)\n'
  printf -- '- [4. Listening Ports & Connections](#4-listening-ports-connections)\n'
  printf -- '- [5. Configuration Files & Layout](#5-configuration-files-layout)\n'
  printf -- '- [6. Sites / Virtual Hosts](#6-sites-virtual-hosts-parsed-from-effective-config)\n'
  printf -- '- [7. SSL / TLS Certificates](#7-ssl-tls-certificates)\n'
  printf -- '- [8. Security Audit](#8-security-audit-config-based)\n'
  printf -- '- [9. File & Directory Permissions](#9-file-directory-permissions)\n'
  printf -- '- [10. System-Level Hardening](#10-system-level-hardening)\n'
  printf -- '- [11. Logs - Locations, Size, Rotation](#11-logs-locations-size-rotation)\n'
  printf -- '- [12. Error Log Analysis](#12-error-log-analysis)\n'
  printf -- '- [13. Access Log & Traffic Analysis](#13-access-log-traffic-analysis-assumes-combined-format)\n'
  printf -- '- [14. Live Endpoint Checks](#14-live-endpoint-checks-localhost)\n'
  printf -- '- [15. Performance & Capacity Hints](#15-performance-capacity-hints)\n'
  printf -- '- [16. Backends & Related Services](#16-backends-related-services)\n'
  printf -- '- [17. Config Backup & Change Tracking](#17-config-backup-change-tracking)\n\n'

  printf '<a id="actionable-issues"></a>\n\n'
  printf '## What Is Wrong & How to Fix It (Failures & Warnings)\n\n'

  if [ ! -s "$ISSUES_TSV" ]; then
    printf '> All checks passed with zero failures or warnings.\n\n'
  else
    if [ "$FAIL_COUNT" -gt 0 ]; then
      printf '### Critical Failures (`[FAIL]` — Fix Immediately)\n\n'
      printf '| ID | Section | What Is Wrong | Where (File / Line Link) | Docs | How to Fix |\n'
      printf '| :--- | :--- | :--- | :--- | :--- | :--- |\n'
      awk -F'\t' '$1 == "FAIL" {
        doc = ($7 != "N/A" && $7 != "") ? "[Docs](" $7 ")" : "N/A"
        printf "| **%s** | [%s](#%s) | %s | %s | %s | %s |\n", $2, $3, $4, $5, $6, doc, $8
      }' "$ISSUES_TSV"
      printf '\n'
    fi

    if [ "$WARN_COUNT" -gt 0 ]; then
      printf '### Warnings (`[WARN]` — Recommended Hardening & Fixes)\n\n'
      printf '| ID | Section | Warning Details | Where (File / Line Link) | Docs | How to Fix |\n'
      printf '| :--- | :--- | :--- | :--- | :--- | :--- |\n'
      awk -F'\t' '$1 == "WARN" {
        doc = ($7 != "N/A" && $7 != "") ? "[Docs](" $7 ")" : "N/A"
        printf "| **%s** | [%s](#%s) | %s | %s | %s | %s |\n", $2, $3, $4, $5, $6, doc, $8
      }' "$ISSUES_TSV"
      printf '\n'
    fi
  fi

  printf -- '---\n\n'
  cat "$RAW_OUT"
} > "$REPORT"

# =====================================================================
printf '\n%s================================================================%s\n%s SUMMARY%s\n%s================================================================%s\n' "$B" "$N" "$BOLD" "$N" "$B" "$N"
printf '  %sOK: %d%s   %sWARN: %d%s   %sFAIL: %d%s\n' "$G" "$OK_COUNT" "$N" "$Y" "$WARN_COUNT" "$N" "$R" "$FAIL_COUNT" "$N"
echo "  Review all [FAIL] items first, then [WARN]."
echo "  Full effective config can be dumped with:  sudo nginx -T > nginx-full-config.txt"
echo "  Markdown Report saved to: $REPORT"
echo
