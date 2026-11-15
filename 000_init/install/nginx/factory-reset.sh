#!/usr/bin/env bash
#
# nginx-factory-reset.sh - wipe nginx completely (Debian/Ubuntu) and reinstall
# a pristine default install.
#
# Usage:
#   sudo ./nginx-factory-reset.sh --dry-run        # preview only
#   sudo ./nginx-factory-reset.sh                  # purge + reinstall nginx
#   sudo ./nginx-factory-reset.sh --letsencrypt    # also wipe /etc/letsencrypt
#   sudo ./nginx-factory-reset.sh --no-reinstall   # purge only, leave nginx removed
#   sudo ./nginx-factory-reset.sh --yes            # skip confirmation
#
set -uo pipefail

DRY_RUN=0; WIPE_LE=0; REINSTALL=1; ASSUME_YES=0
for a in "$@"; do
  case "$a" in
    --dry-run)      DRY_RUN=1 ;;
    --letsencrypt)  WIPE_LE=1 ;;
    --no-reinstall) REINSTALL=0 ;;
    -y|--yes)       ASSUME_YES=1 ;;
    -h|--help)      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $a"; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }
command -v apt-get >/dev/null || { echo "This script needs apt (Debian/Ubuntu)."; exit 1; }

run() {
  if (( DRY_RUN )); then echo "  [dry-run] $*"; else echo "  + $*"; "$@"; fi
}

# Everything that gets deleted after the packages are purged
WIPE_PATHS=(
  /etc/nginx
  /var/log/nginx
  /var/lib/nginx
  /var/cache/nginx
  /usr/share/nginx
  /var/www/html
  /etc/ssl/certs/nginx
  /etc/logrotate.d/nginx
)
if (( WIPE_LE )); then
  WIPE_PATHS+=( /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt )
fi

echo "== nginx FACTORY RESET =="
echo "Will purge packages: nginx*"
echo "Will delete:"
printf '  %s\n' "${WIPE_PATHS[@]}"
(( REINSTALL )) && echo "Will then reinstall a fresh nginx and start it." \
                || echo "nginx will be left uninstalled."
(( WIPE_LE ))   || echo "(Let's Encrypt data is kept; use --letsencrypt to wipe it.)"
echo "NOT touched: /test-apps, firewall rules, certbot package itself."
echo

if (( ! DRY_RUN && ! ASSUME_YES )); then
  read -r -p "This cannot be undone (except via backup). Type 'RESET' to continue: " ans
  [[ $ans == RESET ]] || { echo "Aborted."; exit 1; }
fi

# ---- 1. Backup -------------------------------------------------------------
BACKUP=/root/nginx-factory-backup-$(date +%Y%m%d-%H%M%S).tar.gz
echo "[1/5] Backing up to $BACKUP"
TO_BACKUP=()
for p in "${WIPE_PATHS[@]}"; do
  [[ $p == /var/log/* ]] && continue          # skip logs to keep backup small
  [[ -e $p ]] && TO_BACKUP+=( "${p#/}" )
done
if (( ${#TO_BACKUP[@]} )); then
  run tar -czf "$BACKUP" -C / "${TO_BACKUP[@]}"
else
  echo "  nothing to back up"
fi

# ---- 2. Stop nginx ---------------------------------------------------------
echo "[2/5] Stopping nginx"
run systemctl stop nginx
run systemctl disable nginx
run pkill -x nginx

# ---- 3. Purge packages -----------------------------------------------------
echo "[3/5] Purging nginx packages"
if (( DRY_RUN )); then
  echo "  [dry-run] apt-get purge -y 'nginx*' && apt-get autoremove -y"
else
  PKGS=$(dpkg -l | awk '/^.i|^.c/ && $2 ~ /^(nginx|libnginx|python3-certbot-nginx)/ {print $2}' | grep -v '^python3-certbot-nginx$' || true)
  if [[ -n $PKGS ]]; then
    echo "  + apt-get purge -y $PKGS"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y $PKGS
  fi
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
fi

# ---- 4. Delete leftovers ---------------------------------------------------
echo "[4/5] Deleting leftover files"
for p in "${WIPE_PATHS[@]}"; do
  [[ -e $p || -L $p ]] && run rm -rf -- "$p"
done

# ---- 5. Reinstall ----------------------------------------------------------
if (( REINSTALL )); then
  echo "[5/5] Reinstalling nginx"
  if (( DRY_RUN )); then
    echo "  [dry-run] apt-get update && apt-get install -y nginx"
  else
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    systemctl enable --now nginx
    nginx -t && echo "nginx is installed with the stock default config."
    systemctl --no-pager --lines=0 status nginx | head -n 3
  fi
else
  echo "[5/5] Skipping reinstall (--no-reinstall)"
fi

echo
echo "Done. Backup: $BACKUP"
echo "Restore configs with: sudo tar -xzf $BACKUP -C /"