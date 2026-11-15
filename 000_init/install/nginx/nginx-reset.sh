#!/usr/bin/env bash
#
# nginx-reset.sh - remove the listed nginx sites/configs so you can start fresh.
#
# Usage:
#   sudo ./nginx-reset.sh --dry-run            # show what would happen
#   sudo ./nginx-reset.sh                      # remove configs (asks to confirm)
#   sudo ./nginx-reset.sh --certs              # also delete SSL certs
#   sudo ./nginx-reset.sh --webroots           # also delete site folders/logs
#   sudo ./nginx-reset.sh --certs --webroots --yes
#
set -uo pipefail

DRY_RUN=0; DEL_CERTS=0; DEL_ROOTS=0; ASSUME_YES=0
for a in "$@"; do
  case "$a" in
    --dry-run)  DRY_RUN=1 ;;
    --certs)    DEL_CERTS=1 ;;
    --webroots) DEL_ROOTS=1 ;;
    -y|--yes)   ASSUME_YES=1 ;;
    -h|--help)  sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $a"; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }

# ---- What to remove --------------------------------------------------------
CONF_FILES=(
  /etc/nginx/conf.d/nginx.localhost.com.conf
  /etc/nginx/sites-enabled/default
  /etc/nginx/sites-enabled/rbot.jaganathan.co.uk.conf
  /etc/nginx/sites-enabled/task.jaganathan.co.uk.conf
  # sites-available counterparts (the symlink targets), if they exist
  /etc/nginx/sites-available/default
  /etc/nginx/sites-available/rbot.jaganathan.co.uk.conf
  /etc/nginx/sites-available/task.jaganathan.co.uk.conf
)

LE_CERT_NAMES=(
  chitta.jaganathan.co.uk
  maya.jaganathan.co.uk
  rbot.jaganathan.co.uk
  task.jaganathan.co.uk
)

SELF_SIGNED_DIR=/etc/ssl/certs/nginx

WEB_ROOTS=(
  /var/www/html/nginx.localhost.com
  /test-apps/rbot
  /test-apps/task
)

LOG_FILES=(
  /var/log/nginx/nginx.localhost.com.access.log
  /var/log/nginx/rbot.jaganathan.co.uk.access.log
)

# ---- Helpers ---------------------------------------------------------------
run() {
  if (( DRY_RUN )); then echo "  [dry-run] $*"; else echo "  + $*"; "$@"; fi
}

# ---- Summary + confirmation ------------------------------------------------
echo "== nginx reset =="
echo "Config files to remove:"
for f in "${CONF_FILES[@]}"; do [[ -e $f || -L $f ]] && echo "  $f"; done
(( DEL_CERTS )) && { echo "Certs to remove: ${LE_CERT_NAMES[*]} and $SELF_SIGNED_DIR"; }
(( DEL_ROOTS )) && { echo "Web roots/logs to remove:"; printf '  %s\n' "${WEB_ROOTS[@]}" "${LOG_FILES[@]}"; }
echo

if (( ! DRY_RUN && ! ASSUME_YES )); then
  read -r -p "Proceed? Type 'yes' to continue: " ans
  [[ $ans == yes ]] || { echo "Aborted."; exit 1; }
fi

# ---- 1. Backup -------------------------------------------------------------
BACKUP=/root/nginx-backup-$(date +%Y%m%d-%H%M%S).tar.gz
echo "[1/5] Backing up /etc/nginx -> $BACKUP"
run tar -czf "$BACKUP" -C / etc/nginx

# ---- 2. Remove configs -----------------------------------------------------
echo "[2/5] Removing site configs"
for f in "${CONF_FILES[@]}"; do
  if [[ -e $f || -L $f ]]; then run rm -f -- "$f"; fi
done

# ---- 3. Certificates (optional) --------------------------------------------
if (( DEL_CERTS )); then
  echo "[3/5] Removing certificates"
  if command -v certbot >/dev/null 2>&1; then
    for c in "${LE_CERT_NAMES[@]}"; do
      if [[ -d /etc/letsencrypt/live/$c ]]; then
        run certbot delete --cert-name "$c" --non-interactive
      fi
    done
  else
    echo "  certbot not found; skipping Let's Encrypt certs"
  fi
  [[ -d $SELF_SIGNED_DIR ]] && run rm -rf -- "$SELF_SIGNED_DIR"
else
  echo "[3/5] Skipping certificates (use --certs to remove)"
fi

# ---- 4. Web roots and logs (optional) --------------------------------------
if (( DEL_ROOTS )); then
  echo "[4/5] Removing web roots and logs"
  for d in "${WEB_ROOTS[@]}"; do [[ -d $d ]] && run rm -rf -- "$d"; done
  for l in "${LOG_FILES[@]}"; do [[ -f $l ]] && run rm -f -- "$l"; done
else
  echo "[4/5] Skipping web roots/logs (use --webroots to remove)"
fi

# ---- 5. Validate + reload --------------------------------------------------
echo "[5/5] Testing and reloading nginx"
if (( DRY_RUN )); then
  echo "  [dry-run] nginx -t && systemctl reload nginx"
else
  if nginx -t; then
    systemctl reload nginx && echo "nginx reloaded."
  else
    echo "nginx -t failed. Check /etc/nginx/nginx.conf; backup is at $BACKUP"
    exit 1
  fi
fi

echo
echo "Done. Backup: $BACKUP"
echo "Restore with: sudo tar -xzf $BACKUP -C /"
