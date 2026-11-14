#!/usr/bin/env bash
#
# nginx-audit.sh - Read-only nginx server & admin audit report
#
# Usage:   sudo ./nginx-audit.sh [-o report.txt] [-n LOG_LINES] [-d CERT_WARN_DAYS]
# Example: sudo ./nginx-audit.sh -o /tmp/nginx-report.txt -n 100000
#
# Makes NO changes to the system. Run as root for complete results.

set -u
export LC_ALL=C

REPORT=""
LOG_LINES=50000      # how many recent access-log lines to analyse
CERT_WARN=30         # warn when certs expire within N days

while getopts "o:n:d:h" opt; do
  case $opt in
    o) REPORT="$OPTARG" ;;
    n) LOG_LINES="$OPTARG" ;;
    d) CERT_WARN="$OPTARG" ;;
    *) sed -n '2,10p' "$0"; exit 0 ;;
  esac
done

# ---------- output helpers ----------
if [ -t 1 ] && [ -z "$REPORT" ]; then
  R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[36m'; N=$'\e[0m'; BOLD=$'\e[1m'
else
  R=""; G=""; Y=""; B=""; N=""; BOLD=""
fi
[ -n "$REPORT" ] && exec > >(tee "$REPORT") 2>&1

WARN_COUNT=0; FAIL_COUNT=0; OK_COUNT=0
section() { printf '\n%s================================================================%s\n%s %s%s\n%s================================================================%s\n' "$B" "$N" "$BOLD" "$1" "$N" "$B" "$N"; }
sub()     { printf '\n%s--- %s ---%s\n' "$BOLD" "$1" "$N"; }
ok()      { printf '  %s[ OK ]%s %s\n' "$G" "$N" "$1"; OK_COUNT=$((OK_COUNT+1)); }
warn()    { printf '  %s[WARN]%s %s\n' "$Y" "$N" "$1"; WARN_COUNT=$((WARN_COUNT+1)); }
fail()    { printf '  %s[FAIL]%s %s\n' "$R" "$N" "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
info()    { printf '  %s\n' "$1"; }
have()    { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -ne 0 ]; then
  printf '%sNot running as root - some sections (config dump, logs, keys) will be incomplete. Use sudo.%s\n' "$Y" "$N"
fi

# ---------- locate nginx ----------
NGINX_BIN=$(command -v nginx || true)
[ -z "$NGINX_BIN" ] && for p in /usr/sbin/nginx /usr/local/sbin/nginx /usr/local/nginx/sbin/nginx /opt/nginx/sbin/nginx; do
  [ -x "$p" ] && NGINX_BIN="$p" && break
done
if [ -z "$NGINX_BIN" ]; then
  echo "nginx binary not found. Aborting."; exit 1
fi

TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
FULLCONF="$TMPD/full.conf"     # complete effective config (nginx -T)
CLEAN="$TMPD/clean.conf"       # same, with comments stripped
"$NGINX_BIN" -T >"$FULLCONF" 2>"$TMPD/test.err"
sed -E 's/#.*$//' "$FULLCONF" | sed -E '/^[[:space:]]*$/d' >"$CLEAN"

CONF_PATH=$("$NGINX_BIN" -V 2>&1 | grep -oE '\-\-conf-path=[^ ]+' | cut -d= -f2)
CONF_PATH=${CONF_PATH:-/etc/nginx/nginx.conf}
CONF_DIR=$(dirname "$CONF_PATH")

printf '%sNGINX SERVER AUDIT REPORT%s\nGenerated : %s\nHost      : %s\n' "$BOLD" "$N" "$(date '+%F %T %Z')" "$(hostname -f 2>/dev/null || hostname)"

# =====================================================================
section "1. SYSTEM OVERVIEW"
# =====================================================================
info "OS        : $( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -s)"
info "Kernel    : $(uname -r)  ($(uname -m))"
info "Uptime    : $(uptime -p 2>/dev/null || uptime)"
info "Load avg  : $(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)   CPUs: $(nproc 2>/dev/null)"
have free && { sub "Memory"; free -h; }
sub "Disk usage"; df -hT -x tmpfs -x devtmpfs -x squashfs 2>/dev/null
sub "Disk inodes"; df -i -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | head -n 10
df --output=pcent,target -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | tail -n +2 | while read -r pc mp; do
  p=${pc%\%}; [ "$p" -ge 90 ] 2>/dev/null && warn "Filesystem $mp is ${pc} full"
done
sub "Public / local IPs"
ip -br addr 2>/dev/null | grep -v '^lo' || hostname -I

# =====================================================================
section "2. NGINX BINARY & BUILD"
# =====================================================================
NGX_VER=$("$NGINX_BIN" -v 2>&1 | sed 's/.*nginx\///')
info "Binary    : $NGINX_BIN"
info "Version   : $NGX_VER"
info "Config    : $CONF_PATH"
sub "Build info (nginx -V)"
"$NGINX_BIN" -V 2>&1 | sed 's/ --/\n    --/g'
sub "Modules compiled in / dynamic"
"$NGINX_BIN" -V 2>&1 | grep -oE '\-\-(with|add)[a-z_-]*module[^ ]*' | sort | sed 's/^/    /'
ls "$CONF_DIR"/modules-enabled 2>/dev/null | sed 's/^/    dynamic: /'
grep -E '^\s*load_module' "$CLEAN" | sed 's/^/    /'

sub "Package info"
if have dpkg; then dpkg -l 2>/dev/null | awk '/^ii +(nginx|libnginx)/{print "    "$2" "$3}'
elif have rpm; then rpm -qa 2>/dev/null | grep -i nginx | sed 's/^/    /'; fi
sub "Update availability"
if have apt-get; then
  up=$(apt list --upgradable 2>/dev/null | grep -i nginx)
  [ -n "$up" ] && warn "nginx update available: $up" || ok "No nginx update pending (per local apt cache)"
elif have yum; then
  yum -q check-update nginx >/dev/null 2>&1; [ $? -eq 100 ] && warn "nginx update available" || ok "No nginx update pending"
fi
info "Tip: compare $NGX_VER against https://nginx.org/en/security_advisories.html"

# =====================================================================
section "3. SERVICE STATUS & PROCESSES"
# =====================================================================
if have systemctl && systemctl list-unit-files 2>/dev/null | grep -q '^nginx'; then
  systemctl is-active --quiet nginx && ok "nginx service is ACTIVE" || fail "nginx service is NOT active"
  systemctl is-enabled --quiet nginx && ok "Enabled at boot" || warn "Not enabled at boot"
  systemctl status nginx --no-pager -n 0 2>/dev/null | sed 's/^/    /' | head -n 15
  sub "Recent service journal (last 10)"
  journalctl -u nginx --no-pager -n 10 2>/dev/null | sed 's/^/    /'
else
  pgrep -x nginx >/dev/null && ok "nginx process running (non-systemd)" || fail "nginx is not running"
fi
sub "Config syntax test (nginx -t)"
if grep -q 'syntax is ok' "$TMPD/test.err" && grep -q 'test is successful' "$TMPD/test.err"; then
  ok "Configuration syntax OK"
else
  fail "Configuration test reported problems:"; sed 's/^/    /' "$TMPD/test.err"
fi
grep -iE 'warn|deprecat' "$TMPD/test.err" | sed 's/^/    /'

sub "Processes"
ps -o pid,ppid,user,%cpu,%mem,rss,etime,cmd -C nginx 2>/dev/null | cut -c1-140
MASTER_USER=$(ps -o user= -p "$(pgrep -o -x nginx 2>/dev/null)" 2>/dev/null | tr -d ' ')
WORKER_USER=$(ps -o user= -C nginx 2>/dev/null | sort -u | grep -v '^root$' | head -n1)
[ "$MASTER_USER" = "root" ] && ok "Master runs as root (normal, needed for ports <1024)"
if [ -n "$WORKER_USER" ]; then ok "Workers run as non-root user: $WORKER_USER"
else fail "Workers appear to run as root!"; fi
NW=$(pgrep -f 'nginx: worker' | wc -l); info "Worker processes: $NW   (CPU cores: $(nproc))"
PIDF=$(grep -E '^\s*pid\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1)
info "PID file: ${PIDF:-default}"
MP=$(pgrep -o -x nginx 2>/dev/null)
if [ -n "$MP" ] && [ -r /proc/$MP/limits ]; then
  sub "Open-file limit of master"; grep -i 'open files' /proc/$MP/limits | sed 's/^/    /'
  info "Open FDs (master): $(ls /proc/$MP/fd 2>/dev/null | wc -l)"
fi

# =====================================================================
section "4. LISTENING PORTS & CONNECTIONS"
# =====================================================================
sub "Sockets owned by nginx"
if have ss; then ss -tulnp 2>/dev/null | grep -i nginx | sed 's/^/    /' || true
else netstat -tulnp 2>/dev/null | grep -i nginx | sed 's/^/    /'; fi
sub "Ports declared in config"
grep -E '^\s*listen\s' "$CLEAN" | sed -E 's/^\s*listen\s+//; s/;//' | sort | uniq -c | sort -rn | sed 's/^/    /'
if have ss; then
  sub "TCP connection states (all :80/:443 traffic)"
  ss -tan '( sport = :80 or sport = :443 )' 2>/dev/null | awk 'NR>1{c[$1]++} END{for(s in c) printf "    %-14s %d\n", s, c[s]}'
  sub "Top 10 client IPs currently connected"
  ss -tn '( sport = :80 or sport = :443 )' 2>/dev/null | awk 'NR>1{split($5,a,":"); sub(/:[0-9]+$/,"",$5); print $5}' | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'
fi
sub "Other services listening publicly (potential exposure)"
ss -tlnH 2>/dev/null | awk '{print $4}' | grep -vE '^(127\.|\[::1\]|::1)' | sed 's/^/    /' | head -n 25

# =====================================================================
section "5. CONFIGURATION FILES & LAYOUT"
# =====================================================================
info "Main config dir: $CONF_DIR"
sub "Files loaded (from nginx -T)"
grep -E '^# configuration file ' "$FULLCONF" | sed 's/^# configuration file //; s/:$//' | sort -u | sed 's/^/    /'
sub "Directory tree"
for d in sites-available sites-enabled conf.d snippets modules-enabled; do
  [ -d "$CONF_DIR/$d" ] && { echo "    $CONF_DIR/$d:"; ls -la "$CONF_DIR/$d" | tail -n +4 | sed 's/^/        /'; }
done
sub "Broken symlinks in nginx config dir"
BL=$(find "$CONF_DIR" -xtype l 2>/dev/null)
[ -n "$BL" ] && { fail "Broken symlinks found:"; echo "$BL" | sed 's/^/    /'; } || ok "None"
sub "Sites available but NOT enabled"
if [ -d "$CONF_DIR/sites-available" ] && [ -d "$CONF_DIR/sites-enabled" ]; then
  for f in "$CONF_DIR"/sites-available/*; do
    [ -e "$f" ] || continue; b=$(basename "$f")
    [ -e "$CONF_DIR/sites-enabled/$b" ] || info "disabled: $b"
  done
fi
sub "Core / global settings"
for k in user worker_processes worker_connections worker_rlimit_nofile multi_accept use keepalive_timeout keepalive_requests sendfile tcp_nopush tcp_nodelay types_hash_max_size client_max_body_size client_body_timeout client_header_timeout send_timeout gzip gzip_comp_level brotli error_log access_log; do
  v=$(grep -E "^\s*$k\s" "$CLEAN" | sed -E 's/^\s+//' | sort -u | head -n 4)
  [ -n "$v" ] && echo "$v" | sed 's/^/    /'
done
W=$(grep -E '^\s*worker_processes' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1)
[ "$W" = "auto" ] && ok "worker_processes auto" || info "worker_processes = ${W:-default(1)} (consider 'auto')"

# =====================================================================
section "6. SITES / VIRTUAL HOSTS (parsed from effective config)"
# =====================================================================
awk '
function val(s,k,  t){ t=s; sub("^[ \t]*" k "[ \t]+","",t); sub(/[ \t]*;.*/,"",t); return t }
/^# configuration file /{ f=$4; sub(/:$/,"",f); next }
{
  line=$0; sub(/#.*/,"",line)
  if (!ins && line ~ /^[ \t]*server[ \t]*\{/) {
    ins=1; depth=0; n++; file[n]=f; lis[n]=""; sn[n]=""; rt[n]=""; ssl[n]=""; key[n]=""; px[n]=""; rtn[n]=""; fcgi[n]=""; idx[n]=""; ai[n]=""; al[n]=""; loc[n]=0; auth[n]=""; acl[n]=""
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
  if(!n){ print "  No server blocks found."; exit }
  for(i=1;i<=n;i++){
    printf "\n  [%d] %s\n", i, (sn[i]==""?"(no server_name)":sn[i])
    printf "      file       : %s\n", file[i]
    printf "      listen     : %s\n", lis[i]
    if (rt[i]!="")   printf "      root       : %s\n", rt[i]
    if (px[i]!="")   printf "      proxy_pass : %s\n", px[i]
    if (fcgi[i]!="") printf "      backend    : %s\n", fcgi[i]
    if (rtn[i]!="")  printf "      return     : %s\n", rtn[i]
    if (ssl[i]!="")  printf "      ssl cert   : %s\n      ssl key    : %s\n", ssl[i], key[i]
    if (al[i]!="")   printf "      access_log : %s\n", al[i]
    printf "      locations  : %d   %s %s %s\n", loc[i], (auth[i]?"["auth[i]"]":""), (acl[i]?"["acl[i]"]":""), (ai[i]?"[AUTOINDEX ON]":"")
  }
  printf "\n  Total server blocks: %d\n", n
}' "$FULLCONF"

sub "Domains (unique server_names)"
grep -E '^\s*server_name\s' "$CLEAN" | sed -E 's/^\s*server_name\s+//; s/;//' | tr ' ' '\n' | grep -v '^$' | sort -u | sed 's/^/    /'
sub "Default servers"
DS=$(grep -E 'listen.*default_server' "$CLEAN")
[ -n "$DS" ] && echo "$DS" | sed 's/^/    /' || warn "No explicit default_server - first server block per port answers unknown hosts"
sub "Upstream blocks"
awk '/^[ \t]*upstream[ \t]/{p=1} p{print "    "$0} p&&/\}/{p=0}' "$CLEAN"
sub "Location blocks that proxy / redirect / deny (summary)"
grep -E '^\s*location\s' "$CLEAN" | sed -E 's/^\s+//' | sort | uniq -c | sort -rn | head -n 30 | sed 's/^/    /'
sub "Web root(s): size & owner"
grep -E '^\s*root\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u | while read -r r; do
  if [ -d "$r" ]; then printf '    %-40s %-8s owner=%s perms=%s\n' "$r" "$(du -sh "$r" 2>/dev/null | cut -f1)" "$(stat -c %U:%G "$r")" "$(stat -c %a "$r")"
  else warn "root does not exist: $r"; fi
done

# =====================================================================
section "7. SSL / TLS CERTIFICATES"
# =====================================================================
CERTS=$(grep -E '^\s*ssl_certificate\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u)
if [ -z "$CERTS" ]; then warn "No ssl_certificate directives found - no HTTPS configured?"
elif ! have openssl; then warn "openssl not installed; cannot inspect certificates"
else
  NOW=$(date +%s)
  for c in $CERTS; do
    [ -r "$c" ] || { fail "Cannot read $c"; continue; }
    subj=$(openssl x509 -in "$c" -noout -subject 2>/dev/null | sed 's/subject=//')
    iss=$(openssl x509 -in "$c" -noout -issuer 2>/dev/null | sed 's/issuer=//')
    end=$(openssl x509 -in "$c" -noout -enddate 2>/dev/null | cut -d= -f2)
    san=$(openssl x509 -in "$c" -noout -ext subjectAltName 2>/dev/null | tail -n +2 | tr -d ' \n')
    sig=$(openssl x509 -in "$c" -noout -text 2>/dev/null | awk -F': ' '/Signature Algorithm/{print $2; exit}')
    bits=$(openssl x509 -in "$c" -noout -text 2>/dev/null | awk -F'[()]' '/Public-Key:/{print $2; exit}')
    ts=$(date -d "$end" +%s 2>/dev/null); days=$(( (ts-NOW)/86400 ))
    echo; info "Cert    : $c"; info "  Subject : $subj"; info "  Issuer  : $iss"; info "  SANs    : ${san:-n/a}"
    info "  Expires : $end  ($days days)"; info "  Key/Sig : $bits / $sig"
    if   [ "$days" -lt 0 ];           then fail "  EXPIRED $((-days)) days ago"
    elif [ "$days" -le 7 ];           then fail "  expires in $days days"
    elif [ "$days" -le "$CERT_WARN" ]; then warn "  expires in $days days"
    else ok "  validity OK"; fi
    case "$sig" in *sha1*|*md5*) fail "  weak signature algorithm";; esac
    openssl x509 -in "$c" -noout -checkend 0 >/dev/null 2>&1 || true
  done
  sub "Private key permissions"
  grep -E '^\s*ssl_certificate_key\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u | while read -r k; do
    [ -e "$k" ] || { warn "key missing: $k"; continue; }
    p=$(stat -L -c %a "$k"); o=$(stat -L -c %U:%G "$k")
    case "$p" in 600|400|640|440) ok "$k  ($p $o)";; *) fail "$k has loose perms $p ($o) - should be 600/640";; esac
  done
fi
have certbot && { sub "Certbot certificates"; certbot certificates 2>/dev/null | sed 's/^/    /'; sub "Certbot renewal timer"; systemctl list-timers 2>/dev/null | grep -i certbot | sed 's/^/    /'; }
[ -d /etc/letsencrypt/live ] && info "Let's Encrypt live dir: $(ls /etc/letsencrypt/live 2>/dev/null | tr '\n' ' ')"
[ -f /etc/cron.d/certbot ] && info "certbot cron present"

# =====================================================================
section "8. SECURITY AUDIT (config-based)"
# =====================================================================
chk() { # chk "label" "regex" "good|bad(present=good?)" "message if missing"
  :
}
sub "Information disclosure"
st=$(grep -E '^\s*server_tokens\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | tr '\n' ' ')
if echo "$st" | grep -q off; then ok "server_tokens off"; else warn "server_tokens not 'off' - nginx version is exposed in headers/error pages"; fi
grep -qE 'more_clear_headers\s+.?Server' "$CLEAN" && ok "Server header cleared (headers-more)"
grep -E '^\s*autoindex\s+on' "$CLEAN" >/dev/null && fail "autoindex ON found (directory listing):" && grep -nE 'autoindex\s+on' "$FULLCONF" | sed 's/^/      /'
grep -qE 'proxy_hide_header\s+X-Powered-By' "$CLEAN" && ok "X-Powered-By hidden from upstreams" || info "Consider: proxy_hide_header X-Powered-By;"

sub "TLS protocol & cipher policy"
pr=$(grep -E '^\s*ssl_protocols\s' "$CLEAN" | sed -E 's/^\s*ssl_protocols\s+//; s/;//' | sort -u)
if [ -z "$pr" ]; then info "ssl_protocols not set (nginx default: TLSv1.2 TLSv1.3 on modern builds)"
else
  info "ssl_protocols: $pr"
  echo "$pr" | grep -qE 'SSLv|TLSv1( |$)|TLSv1\.1' && fail "Insecure protocol enabled (SSLv3/TLS1.0/TLS1.1)" || ok "No legacy protocols"
  echo "$pr" | grep -q 'TLSv1.3' && ok "TLSv1.3 enabled" || warn "TLSv1.3 not enabled"
fi
ci=$(grep -E '^\s*ssl_ciphers\s' "$CLEAN" | head -n1)
[ -n "$ci" ] && { info "$(echo "$ci" | sed 's/^\s*//')"; echo "$ci" | grep -qiE 'RC4|3DES|NULL|EXPORT|MD5|aNULL|DES-CBC' && fail "Weak ciphers allowed"; } || info "ssl_ciphers not set (defaults used)"
grep -qE 'ssl_session_cache' "$CLEAN" && ok "ssl_session_cache configured" || warn "ssl_session_cache not set"
grep -qE 'ssl_session_tickets\s+off' "$CLEAN" && ok "ssl_session_tickets off" || info "ssl_session_tickets not disabled (okay unless you need forward-secrecy hardening)"
grep -qE 'ssl_stapling\s+on' "$CLEAN" && ok "OCSP stapling on" || info "OCSP stapling not enabled"
grep -qE 'ssl_dhparam' "$CLEAN" && ok "ssl_dhparam set" || info "ssl_dhparam not set (only matters for DHE ciphers)"

sub "Security headers (add_header)"
for h in "Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" "Content-Security-Policy" "Referrer-Policy" "Permissions-Policy"; do
  if grep -qiE "add_header\s+\"?$h" "$CLEAN"; then ok "$h configured"; else warn "$h not found in config"; fi
done
grep -qiE 'add_header\s+Strict-Transport-Security' "$CLEAN" && ! grep -qiE 'Strict-Transport-Security.*always' "$CLEAN" && info "Tip: add 'always' to add_header so headers are sent on error responses too"

sub "HTTP -> HTTPS redirection"
if grep -qE 'return\s+30[12]\s+https://' "$CLEAN" || grep -qE 'rewrite .*https://.*permanent' "$CLEAN"; then ok "HTTP->HTTPS redirect present"
else grep -qE 'listen\s+(\[::\]:)?80' "$CLEAN" && warn "Port 80 served but no redirect to HTTPS found"; fi
grep -qE 'listen.*443.*http2|http2\s+on' "$CLEAN" && ok "HTTP/2 enabled" || info "HTTP/2 not enabled"

sub "Rate limiting / DoS protection"
grep -qE 'limit_req_zone' "$CLEAN" && ok "limit_req_zone defined" || warn "No limit_req_zone (no request rate limiting)"
grep -qE 'limit_req\s' "$CLEAN" && ok "limit_req applied" || warn "limit_req not applied to any context"
grep -qE 'limit_conn_zone' "$CLEAN" && ok "limit_conn_zone defined" || info "No connection limiting"
cm=$(grep -E '^\s*client_max_body_size' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | tr '\n' ' ')
[ -n "$cm" ] && info "client_max_body_size: $cm" || info "client_max_body_size default (1m)"
echo "$cm" | grep -qE '(^| )0( |$)' && warn "client_max_body_size 0 = unlimited uploads"
for t in client_body_timeout client_header_timeout send_timeout; do grep -qE "^\s*$t" "$CLEAN" || info "$t not set (default 60s)"; done

sub "Dangerous / risky patterns"
grep -nE 'ssl_verify_client\s+off|proxy_ssl_verify\s+off' "$FULLCONF" | sed 's/^/    verify disabled: /'
grep -nE '^\s*if\s*\(' "$FULLCONF" | head -n 10 | sed 's/^/    "if" in config (review - see "If is Evil"): /'
grep -nE 'location\s+[^{]*/[a-z_]+\s*\{' "$FULLCONF" >/dev/null
# off-by-slash alias traversal
grep -nE 'location\s+/[^ /]+\s*\{' "$FULLCONF" | while IFS=: read -r ln _; do :; done
awk '/location[ \t]+\/[A-Za-z0-9_.-]+[ \t]*\{/{loc=$0; inl=1} inl&&/alias[ \t]/{print "    possible off-by-slash alias traversal: " loc " -> " $0; inl=0} /\}/{inl=0}' "$CLEAN"
grep -qE 'proxy_set_header\s+Host\s+\$http_host' "$CLEAN" && info "proxy_set_header Host \$http_host trusts client Host header"
grep -qE 'location\s+~?\s*/\.\s*\{|location\s+~\s+/\\\.' "$CLEAN" && ok "Dotfile (/.git, /.env) location rule present" || warn "No rule blocking dotfiles (/.git, /.env, /.htpasswd)"
grep -qE 'location.*\.(php|bak|sql|old|swp)' "$CLEAN" || info "No explicit blocking of backup/source extensions (.bak .sql .old .swp)"
grep -qE 'stub_status' "$CLEAN" && {
  info "stub_status enabled at:"; grep -nE 'stub_status' "$FULLCONF" | sed 's/^/      /'
  info "  -> ensure it is restricted with allow/deny"; }

sub "Access control"
grep -cE '^\s*auth_basic\s+"' "$CLEAN" | xargs -I{} info "auth_basic locations: {}"
grep -E '^\s*auth_basic_user_file' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | while read -r f; do
  [ -e "$f" ] && info "htpasswd $f perms=$(stat -c %a "$f") owner=$(stat -c %U:%G "$f")  users=$(grep -c . "$f")" || warn "htpasswd file missing: $f"
done
grep -E '^\s*(allow|deny)\s' "$CLEAN" | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'

sub "ModSecurity / WAF"
grep -qE 'modsecurity\s+on' "$CLEAN" && ok "ModSecurity enabled" || info "ModSecurity/WAF not detected in nginx"
grep -qiE 'naxsi' "$CLEAN" && ok "NAXSI detected"

# =====================================================================
section "9. FILE & DIRECTORY PERMISSIONS"
# =====================================================================
for f in "$CONF_PATH"; do info "$f  perms=$(stat -c %a "$f") owner=$(stat -c %U:%G "$f")"; done
WW=$(find "$CONF_DIR" -type f -perm -o+w 2>/dev/null)
[ -n "$WW" ] && { fail "World-writable files in $CONF_DIR:"; echo "$WW" | sed 's/^/    /'; } || ok "No world-writable config files"
WD=$(find "$CONF_DIR" -type d -perm -o+w 2>/dev/null)
[ -n "$WD" ] && fail "World-writable directories: $WD"
sub "Web roots - world-writable files/dirs (top 10)"
grep -E '^\s*root\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | sort -u | while read -r r; do
  [ -d "$r" ] || continue
  out=$(find "$r" -xdev \( -type f -o -type d \) -perm -o+w 2>/dev/null | head -n 10)
  [ -n "$out" ] && { warn "World-writable under $r:"; echo "$out" | sed 's/^/      /'; } || ok "$r - none"
  sens=$(find "$r" -xdev -type f \( -name '.env' -o -name '.git' -o -name '*.bak' -o -name '*.sql' -o -name '*.old' -o -name '*.swp' -o -name 'id_rsa' -o -name '.htpasswd' -o -name 'wp-config.php.*' \) 2>/dev/null | head -n 10)
  [ -n "$sens" ] && { fail "Sensitive-looking files inside web root $r:"; echo "$sens" | sed 's/^/      /'; }
  [ -d "$r/.git" ] && fail "$r/.git directory present in web root"
done
sub "Log dir permissions"
ls -ld /var/log/nginx 2>/dev/null | sed 's/^/    /'

# =====================================================================
section "10. SYSTEM-LEVEL HARDENING"
# =====================================================================
sub "Firewall"
if have ufw; then ufw status 2>/dev/null | sed 's/^/    /'
elif have firewall-cmd; then firewall-cmd --state 2>/dev/null; firewall-cmd --list-all 2>/dev/null | sed 's/^/    /'
elif have nft; then nft list ruleset 2>/dev/null | head -n 40 | sed 's/^/    /'
elif have iptables; then iptables -S 2>/dev/null | head -n 40 | sed 's/^/    /'
else warn "No firewall tool detected"; fi
sub "Fail2ban"
if have fail2ban-client; then
  systemctl is-active --quiet fail2ban && ok "fail2ban active" || warn "fail2ban installed but inactive"
  fail2ban-client status 2>/dev/null | sed 's/^/    /'
  for j in $(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*:\s*//; s/,//g'); do
    case "$j" in *nginx*) fail2ban-client status "$j" 2>/dev/null | sed 's/^/    /';; esac
  done
else warn "fail2ban not installed (consider it for nginx-botsearch / nginx-http-auth jails)"; fi
sub "SELinux / AppArmor"
have getenforce && info "SELinux: $(getenforce)"
have aa-status && aa-status 2>/dev/null | grep -iE 'nginx|profiles are loaded' | sed 's/^/    /'
sub "systemd sandboxing of nginx.service"
have systemd-analyze && systemd-analyze security nginx.service --no-pager 2>/dev/null | tail -n 3 | sed 's/^/    /'
sub "Kernel network tunables relevant to web servers"
for k in net.core.somaxconn net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_syncookies net.ipv4.ip_local_port_range net.ipv4.tcp_tw_reuse fs.file-max; do
  printf '    %-36s %s\n' "$k" "$(sysctl -n $k 2>/dev/null)"
done
sub "Auto security updates"
[ -f /etc/apt/apt.conf.d/20auto-upgrades ] && cat /etc/apt/apt.conf.d/20auto-upgrades | sed 's/^/    /'
have dnf-automatic && info "dnf-automatic installed"
sub "Pending security updates"
have apt && apt list --upgradable 2>/dev/null | grep -i security | head -n 10 | sed 's/^/    /'
[ -f /var/run/reboot-required ] && warn "System reboot required"

# =====================================================================
section "11. LOGS - LOCATIONS, SIZE, ROTATION"
# =====================================================================
ACCESS_LOGS=$(grep -E '^\s*access_log\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | grep -vE '^(off|syslog:)' | sort -u)
ERROR_LOGS=$(grep -E '^\s*error_log\s' "$CLEAN" | awk '{print $2}' | tr -d ';"' | grep -vE '^(syslog:|stderr|memory:)' | sort -u)
[ -z "$ACCESS_LOGS" ] && ACCESS_LOGS=/var/log/nginx/access.log
[ -z "$ERROR_LOGS" ] && ERROR_LOGS=/var/log/nginx/error.log
sub "Log files"
for l in $ACCESS_LOGS $ERROR_LOGS; do
  [ -e "$l" ] && printf '    %-50s %8s  mtime=%s\n' "$l" "$(du -h "$l" | cut -f1)" "$(stat -c %y "$l" | cut -d. -f1)" || warn "log missing: $l"
done
du -sh /var/log/nginx 2>/dev/null | sed 's/^/    total \/var\/log\/nginx: /'
grep -E '^\s*error_log' "$CLEAN" | sort -u | sed 's/^/    /'
grep -qE '^\s*access_log\s+off' "$CLEAN" && info "access_log is disabled in some contexts"
sub "Log formats defined"
grep -E '^\s*log_format' "$CLEAN" | cut -c1-140 | sed 's/^/    /'
sub "logrotate"
if [ -f /etc/logrotate.d/nginx ]; then ok "logrotate config present"; sed 's/^/    /' /etc/logrotate.d/nginx
else warn "/etc/logrotate.d/nginx not found"; fi
BIGL=$(find /var/log/nginx -type f -size +500M 2>/dev/null)
[ -n "$BIGL" ] && warn "Log files over 500MB: $BIGL"

# =====================================================================
section "12. ERROR LOG ANALYSIS"
# =====================================================================
for el in $ERROR_LOGS; do
  [ -r "$el" ] || continue
  echo; info "File: $el"
  sub "Entries by severity (last $LOG_LINES lines)"
  tail -n "$LOG_LINES" "$el" | grep -oE '\[(debug|info|notice|warn|error|crit|alert|emerg)\]' | sort | uniq -c | sort -rn | sed 's/^/    /'
  sub "Top 10 error messages"
  tail -n "$LOG_LINES" "$el" | sed -E 's/^[0-9\/]+ [0-9:]+ //; s/\[[a-z]+\] [0-9#]+: \*[0-9]+ //; s/client: [0-9a-f.:]+/client: X/; s/request: "[^"]*"/request: "..."/; s/, host: "[^"]*"//; s/upstream: "[^"]*"/upstream: "..."/; s/referrer: "[^"]*"//' | cut -c1-120 | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'
  sub "Last 15 error/crit entries"
  tail -n "$LOG_LINES" "$el" | grep -E '\[(error|crit|alert|emerg)\]' | tail -n 15 | cut -c1-220 | sed 's/^/    /'
  tail -n "$LOG_LINES" "$el" | grep -qE 'too many open files|worker_connections are not enough' && fail "Resource limit errors detected (open files / worker_connections)"
  tail -n "$LOG_LINES" "$el" | grep -qE 'upstream (timed out|prematurely closed)|connect\(\) failed' && warn "Upstream/backend connection problems detected"
  tail -n "$LOG_LINES" "$el" | grep -qE 'SSL_do_handshake|certificate' && info "SSL handshake/cert messages present - review"
done

# =====================================================================
section "13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)"
# =====================================================================
for al in $ACCESS_LOGS; do
  [ -r "$al" ] || continue
  total=$(wc -l <"$al"); echo; info "File: $al   (analysing last $LOG_LINES of $total lines)"
  tail -n "$LOG_LINES" "$al" >"$TMPD/acc.log"
  [ -s "$TMPD/acc.log" ] || { info "empty"; continue; }
  first=$(head -n1 "$TMPD/acc.log" | grep -oE '\[[^]]+\]' | head -n1); last=$(tail -n1 "$TMPD/acc.log" | grep -oE '\[[^]]+\]' | head -n1)
  info "Time range: $first  ->  $last"
  sub "HTTP status code distribution"
  awk '{print $9}' "$TMPD/acc.log" | grep -E '^[1-5][0-9][0-9]$' | sort | uniq -c | sort -rn | sed 's/^/    /'
  sub "Status classes"
  awk '$9 ~ /^[1-5][0-9][0-9]$/{c=substr($9,1,1)"xx"; n[c]++; t++} END{for(k in n) printf "    %s  %6d  (%.1f%%)\n",k,n[k],n[k]*100/t}' "$TMPD/acc.log" | sort
  e5=$(awk '$9 ~ /^5/' "$TMPD/acc.log" | wc -l); tt=$(wc -l <"$TMPD/acc.log")
  [ "$tt" -gt 0 ] && [ $((e5*100/tt)) -ge 5 ] && fail "5xx rate >= 5% ($e5 of $tt)"
  sub "Top 15 client IPs"
  awk '{print $1}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 15 | sed 's/^/    /'
  sub "Top 15 requested URLs"
  awk '{print $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 15 | sed 's/^/    /'
  sub "Top 10 URLs returning 404"
  awk '$9==404{print $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'
  sub "Top 10 URLs returning 5xx"
  awk '$9 ~ /^5/{print $9, $7}' "$TMPD/acc.log" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'
  sub "HTTP methods"
  awk '{gsub(/"/,"",$6); print $6}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 8 | sed 's/^/    /'
  sub "Top 10 user agents"
  awk -F'"' '{print $6}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 10 | cut -c1-140 | sed 's/^/    /'
  sub "Bandwidth served in this window"
  awk '$10 ~ /^[0-9]+$/{s+=$10} END{printf "    %.2f MB\n", s/1048576}' "$TMPD/acc.log"
  sub "Requests per hour (busiest 10)"
  awk '{split($4,a,":"); print substr(a[1],2) " " a[2] ":00"}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    /'
  sub "Suspicious probes (scanner / attack signatures)"
  pat='(\.\./|/etc/passwd|wp-login\.php|xmlrpc\.php|phpmyadmin|/\.env|/\.git|/vendor/phpunit|eval\(|union(%20|\+)select|<script|%3Cscript|/cgi-bin/|jndi:|/actuator|/boaform|/HNAP1|shell\.php|\.asp)'
  grep -ciE "$pat" "$TMPD/acc.log" | xargs -I{} info "Matching requests: {}"
  grep -iE "$pat" "$TMPD/acc.log" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 | sed 's/^/    attacker-ip: /'
  grep -iE "$pat" "$TMPD/acc.log" | awk '{print $7}' | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 8 | sed 's/^/    probed-url : /'
  sub "IPs with most 401/403 (brute force indicators)"
  awk '$9==401||$9==403{print $1}' "$TMPD/acc.log" | sort | uniq -c | sort -rn | head -n 8 | sed 's/^/    /'
  sub "Slow requests (if \$request_time is last field; top 10 > 2s)"
  awk '{t=$NF} t ~ /^[0-9]+\.[0-9]+$/ && t>2 {print t, $7}' "$TMPD/acc.log" | sort -rn | head -n 10 | sed 's/^/    /'
done

# =====================================================================
section "14. LIVE ENDPOINT CHECKS (localhost)"
# =====================================================================
if have curl; then
  for u in http://127.0.0.1 https://127.0.0.1; do
    echo; info "$u  (Host: localhost, -k)"
    curl -skI --max-time 5 "$u" 2>/dev/null | head -n 15 | sed 's/^/    /'
  done
  sub "Security headers on first named server over HTTPS"
  d=$(grep -E '^\s*server_name\s' "$CLEAN" | sed -E 's/^\s*server_name\s+//; s/;//' | tr ' ' '\n' | grep -E '^[a-zA-Z0-9.-]+\.[a-z]{2,}$' | head -n 1)
  if [ -n "$d" ]; then
    info "Testing $d via --resolve to 127.0.0.1"
    H=$(curl -skI --max-time 8 --resolve "$d:443:127.0.0.1" "https://$d/" 2>/dev/null)
    echo "$H" | head -n 20 | sed 's/^/    /'
    echo "$H" | grep -qi '^server:.*nginx/[0-9]' && warn "Server header discloses nginx version"
    echo "$H" | grep -qi 'strict-transport' && ok "HSTS header served" || warn "HSTS header not served"
  fi
  if grep -qE 'stub_status' "$CLEAN"; then
    sub "stub_status"
    for p in /nginx_status /status /stub_status /basic_status; do
      o=$(curl -s --max-time 3 "http://127.0.0.1$p" 2>/dev/null | head -n 4); echo "$o" | grep -q 'Active connections' && { echo "    http://127.0.0.1$p"; echo "$o" | sed 's/^/      /'; }
    done
  fi
else info "curl not installed - skipped"; fi
if have openssl; then
  sub "TLS handshake test on 127.0.0.1:443"
  for v in tls1 tls1_1 tls1_2 tls1_3; do
    if echo | timeout 5 openssl s_client -connect 127.0.0.1:443 -"$v" >/dev/null 2>&1; then
      case $v in tls1|tls1_1) fail "$v ACCEPTED (should be disabled)";; *) ok "$v accepted";; esac
    else info "$v rejected / unavailable"; fi
  done
fi

# =====================================================================
section "15. PERFORMANCE & CAPACITY HINTS"
# =====================================================================
WC=$(grep -E '^\s*worker_connections' "$CLEAN" | awk '{print $2}' | tr -d ';' | head -n1); WC=${WC:-512}
[ "$W" = "auto" ] && WN=$(nproc) || WN=${W:-1}
info "Theoretical max clients ~ worker_processes($WN) x worker_connections($WC) = $((WN*WC))   (halve for reverse proxy)"
RN=$(grep -E '^\s*worker_rlimit_nofile' "$CLEAN" | awk '{print $2}' | tr -d ';')
[ -z "$RN" ] && info "worker_rlimit_nofile not set - ensure ulimit >= 2 x worker_connections"
grep -qE '^\s*gzip\s+on' "$CLEAN" && ok "gzip on" || warn "gzip not enabled"
grep -qE 'gzip_types' "$CLEAN" || info "gzip_types not set (only text/html compressed)"
grep -qE 'proxy_cache_path|fastcgi_cache_path' "$CLEAN" && ok "Caching configured" || info "No proxy/fastcgi cache configured"
grep -qE 'expires|Cache-Control' "$CLEAN" && ok "Static caching headers present" || info "No expires/Cache-Control rules for static assets"
grep -qE 'keepalive\s' "$CLEAN" && info "upstream keepalive configured" 
grep -qE '^\s*sendfile\s+on' "$CLEAN" && ok "sendfile on" || info "sendfile not on"
sub "nginx memory (RSS)"
ps -C nginx -o rss= 2>/dev/null | awk '{s+=$1} END{printf "    total RSS: %.1f MB across %d processes\n", s/1024, NR}'
sub "Top 5 processes by memory"
ps aux --sort=-%mem 2>/dev/null | head -n 6 | cut -c1-140 | sed 's/^/    /'
have lsof && { sub "Files/sockets open by nginx"; lsof -c nginx 2>/dev/null | wc -l | xargs -I{} info "{} descriptors (lsof)"; }

# =====================================================================
section "16. BACKENDS & RELATED SERVICES"
# =====================================================================
sub "Upstream/proxy targets reachability"
grep -E '^\s*(proxy_pass|fastcgi_pass|uwsgi_pass|grpc_pass)\s' "$CLEAN" | awk '{print $2}' | tr -d ';' | sort -u | while read -r t; do
  case "$t" in
    unix:*) s=${t#unix:}; [ -S "$s" ] && ok "socket $s exists" || fail "socket missing: $s";;
    http://*|https://*|*:*)
      hp=$(echo "$t" | sed -E 's#^https?://##; s#/.*##'); h=${hp%:*}; p=${hp##*:}
      [[ "$p" =~ ^[0-9]+$ ]] || p=$(echo "$t" | grep -q '^https' && echo 443 || echo 80)
      case "$h" in *'$'*) info "$t (dynamic variable)"; continue;; esac
      if timeout 3 bash -c "exec 3<>/dev/tcp/$h/$p" 2>/dev/null; then ok "$h:$p reachable"; else fail "$h:$p NOT reachable"; fi;;
    *) info "$t (upstream group)";;
  esac
done
sub "Common companion services"
for s in php-fpm php7.4-fpm php8.1-fpm php8.2-fpm php8.3-fpm mysql mariadb postgresql redis-server redis memcached docker fail2ban certbot.timer; do
  systemctl list-unit-files 2>/dev/null | grep -q "^$s" && printf '    %-18s %s\n' "$s" "$(systemctl is-active "$s" 2>/dev/null)"
done
sub "Cron jobs mentioning nginx / certbot"
grep -rEl 'nginx|certbot' /etc/cron* /var/spool/cron 2>/dev/null | sed 's/^/    /'

# =====================================================================
section "17. CONFIG BACKUP & CHANGE TRACKING"
# =====================================================================
info "Config last modified:"
find "$CONF_DIR" -type f -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort -r | head -n 10 | sed 's/^/    /'
[ -d "$CONF_DIR/.git" ] && ok "Config dir is under git" || info "Config not under version control (consider etckeeper or git)"
find "$CONF_DIR" -type f \( -name '*.bak' -o -name '*~' -o -name '*.old' -o -name '*.orig' -o -name '*.save' \) 2>/dev/null | sed 's/^/    stray backup file inside config dir: /'

# =====================================================================
section "SUMMARY"
# =====================================================================
printf '  %sOK: %d%s   %sWARN: %d%s   %sFAIL: %d%s\n' "$G" "$OK_COUNT" "$N" "$Y" "$WARN_COUNT" "$N" "$R" "$FAIL_COUNT" "$N"
echo "  Review all [FAIL] items first, then [WARN]."
echo "  Full effective config can be dumped with:  sudo nginx -T > nginx-full-config.txt"
[ -n "$REPORT" ] && echo "  Report saved to: $REPORT"
echo
