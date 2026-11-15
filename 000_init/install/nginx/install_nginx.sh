#!/bin/bash

# --- Global Variables & Logging Setup ---
SCRIPT_NAME="install_nginx.sh"
TS="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/nginx_install_${TS}.log"
STATE_FILE="/tmp/nginx_install_state_${TS}.tar.gz"
CONFIG_SCRIPT="./configure_nginx.sh"
ROLLBACK_NEEDED=0
ROLLBACK_DONE=0
NGINX_PREINSTALLED=0
SHIM_DIR=""

# Fall back to /tmp if /var/log is not writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/nginx_install_${TS}.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Pre-Checks (no rollback needed: nothing has been changed yet) ---
abort_early() {
    log "!!! FATAL: $1"
    exit 1
}

log "--- Starting $SCRIPT_NAME ---"

# 1. Root check
if [[ $EUID -ne 0 ]]; then
    abort_early "This script must be run as root."
fi
log "✅ User check passed (running as root)."

# 2. OS check
if [[ "$(uname)" != "Linux" ]]; then
    abort_early "Operating System is not Linux. Aborting."
fi
log "✅ OS check passed (Linux)."

# 3. Distribution / package manager
if command -v apt &>/dev/null; then
    DISTRO="DEBIAN"
    INSTALL_CMD_UPDATE="apt update -y"
    INSTALL_CMD_INSTALL="apt install -y"
    REMOVE_CMD="apt purge -y 'nginx*' && apt autoremove -y"
elif command -v dnf &>/dev/null; then
    DISTRO="RHEL"
    INSTALL_CMD_UPDATE=""
    INSTALL_CMD_INSTALL="dnf install -y"
    REMOVE_CMD="dnf remove nginx -y"
elif command -v yum &>/dev/null; then
    DISTRO="RHEL"
    INSTALL_CMD_UPDATE=""
    INSTALL_CMD_INSTALL="yum install -y"
    REMOVE_CMD="yum remove nginx -y"
elif command -v pacman &>/dev/null; then
    DISTRO="ARCH"
    INSTALL_CMD_UPDATE="pacman -Sy"
    INSTALL_CMD_INSTALL="pacman -S --noconfirm"
    REMOVE_CMD="pacman -Rns --noconfirm nginx"
elif command -v apk &>/dev/null; then
    DISTRO="ALPINE"
    INSTALL_CMD_UPDATE="apk update"
    INSTALL_CMD_INSTALL="apk add"
    REMOVE_CMD="apk del nginx"
elif command -v zypper &>/dev/null; then
    DISTRO="SUSE"
    INSTALL_CMD_UPDATE="zypper refresh"
    INSTALL_CMD_INSTALL="zypper install -y"
    REMOVE_CMD="zypper remove -y nginx"
else
    abort_early "Unsupported Linux distribution (apt/dnf/yum/pacman/apk/zypper not found)."
fi
PACKAGE_LIST="nginx openssl curl"
log "✅ Detected distribution family: $DISTRO. Using: $INSTALL_CMD_INSTALL"

# Remember whether nginx was already installed, so rollback never removes a pre-existing install
if command -v nginx &>/dev/null; then
    NGINX_PREINSTALLED=1
    log "ℹ️  NGINX was already installed before this run; rollback will not remove it."
fi

# --- Init system handling (systemd vs SysVinit/OpenRC/containers/WSL) ---
setup_init_compat() {
    if [ -d /run/systemd/system ]; then
        log "✅ systemd detected as init system."
        return
    fi

    log "⚠️  systemd is not running (non-systemd init detected). Enabling systemctl compatibility shim."
    SHIM_DIR="$(mktemp -d /tmp/systemctl_shim.XXXXXX)"
    cat > "$SHIM_DIR/systemctl" <<'SHIM'
#!/bin/bash
# Minimal systemctl -> service/update-rc.d translator for non-systemd hosts
action=""
units=()
for arg in "$@"; do
    case "$arg" in
        -*) ;;                       # ignore options like --now, -q
        *)  if [ -z "$action" ]; then action="$arg"; else units+=("${arg%.service}"); fi ;;
    esac
done

svc() {  # svc <unit> <action>
    if command -v service &>/dev/null; then
        service "$1" "$2"
    elif [ -x "/etc/init.d/$1" ]; then
        "/etc/init.d/$1" "$2"
    elif command -v rc-service &>/dev/null; then
        rc-service "$1" "$2"
    else
        return 1
    fi
}

rc=0
case "$action" in
    start)
        for u in "${units[@]}"; do svc "$u" start || svc "$u" restart || rc=1; done ;;
    stop|restart|reload|status)
        for u in "${units[@]}"; do svc "$u" "$action" || rc=1; done ;;
    is-active)
        svc "${units[0]}" status >/dev/null 2>&1 || rc=3 ;;
    is-enabled)
        ls /etc/rc?.d/S*"${units[0]}" >/dev/null 2>&1 || rc=1 ;;
    enable)
        for u in "${units[@]}"; do
            if command -v update-rc.d &>/dev/null; then update-rc.d "$u" defaults >/dev/null 2>&1
            elif command -v rc-update &>/dev/null; then rc-update add "$u" default >/dev/null 2>&1
            elif command -v chkconfig &>/dev/null; then chkconfig "$u" on >/dev/null 2>&1
            fi
        done ;;
    disable)
        for u in "${units[@]}"; do
            if command -v update-rc.d &>/dev/null; then update-rc.d -f "$u" remove >/dev/null 2>&1
            elif command -v rc-update &>/dev/null; then rc-update del "$u" default >/dev/null 2>&1
            elif command -v chkconfig &>/dev/null; then chkconfig "$u" off >/dev/null 2>&1
            fi
        done ;;
    daemon-reload|reset-failed|mask|unmask) ;;   # no-ops
    *) ;;                                        # unknown: succeed quietly
esac
exit $rc
SHIM
    chmod +x "$SHIM_DIR/systemctl"
    export PATH="$SHIM_DIR:$PATH"
    log "   Shim installed at $SHIM_DIR/systemctl"
}

# --- Rollback ---
rollback() {
    # Run at most once, even if called from both fail_and_rollback and the EXIT trap
    [ "$ROLLBACK_DONE" -eq 1 ] && return
    ROLLBACK_DONE=1

    if [ "$ROLLBACK_NEEDED" -eq 1 ]; then
        log "!!! Performing rollback..."

        if command -v nginx &>/dev/null || dpkg -l 2>/dev/null | grep -q '^ii  nginx'; then
            if [ -d /run/systemd/system ]; then
                systemctl stop nginx 2>/dev/null
                systemctl disable nginx 2>/dev/null
            else
                service nginx stop 2>/dev/null || /etc/init.d/nginx stop 2>/dev/null || killall nginx 2>/dev/null
            fi

            if [ "$NGINX_PREINSTALLED" -eq 0 ] && [ -n "$REMOVE_CMD" ]; then
                eval "$REMOVE_CMD"
                log "   NGINX stopped and removed."
            else
                log "   NGINX stopped (kept: it was installed before this run)."
            fi
        fi

        if [ -f "$STATE_FILE" ]; then
            log "   Restoring files from $STATE_FILE..."
            tar -xzf "$STATE_FILE" -C / 2>/dev/null
            log "   Files restored."
        fi

        rm -f "$STATE_FILE" /tmp/installed_packages_before.list
        log "   Temporary files cleaned."
        log "!!! Rollback COMPLETE."
    else
        log "No rollback required."
    fi

    [ -n "$SHIM_DIR" ] && rm -rf "$SHIM_DIR"
}

fail_and_rollback() {
    log "!!! FATAL: $1"
    ROLLBACK_NEEDED=1
    log "Initiating Rollback procedure..."
    rollback
    exit 1
}

# --- Steps ---
capture_system_state() {
    log "[STEP 1/4] Capturing current system state for rollback..."

    case "$DISTRO" in
        DEBIAN) dpkg --get-selections > /tmp/installed_packages_before.list ;;
        RHEL|SUSE) rpm -qa > /tmp/installed_packages_before.list ;;
        ARCH) pacman -Q > /tmp/installed_packages_before.list ;;
        ALPINE) apk info > /tmp/installed_packages_before.list ;;
    esac

    tar -czf "$STATE_FILE" /etc/nginx /etc/ssl/certs/nginx /tmp/installed_packages_before.list /etc/hosts 2>/dev/null
    log "✅ System state captured to $STATE_FILE."
}

verify_and_install_dependencies() {
    log "[STEP 2/4] Verifying and installing dependencies ($PACKAGE_LIST)..."

    if [ -n "$INSTALL_CMD_UPDATE" ]; then
        log "   Updating package lists..."
        $INSTALL_CMD_UPDATE || true
    fi

    if ! $INSTALL_CMD_INSTALL $PACKAGE_LIST; then
        fail_and_rollback "Failed to install required packages: $PACKAGE_LIST."
    fi
    log "✅ Dependencies installed/verified."
}

run_configuration() {
    log "[STEP 3/4] Starting NGINX configuration script ($CONFIG_SCRIPT)..."

    if [ ! -f "$CONFIG_SCRIPT" ]; then
        fail_and_rollback "Configuration script not found: $CONFIG_SCRIPT"
    fi

    if ! bash "$CONFIG_SCRIPT" "$LOG_FILE"; then
        fail_and_rollback "Configuration script failed. Initiating full rollback."
    fi
    log "✅ Configuration complete."
}

test_installation() {
    log "[STEP 4/4] Testing NGINX setup..."

    local site_conf
    site_conf="$(ls -t /etc/nginx/conf.d/*.conf 2>/dev/null | grep -v '00-production-hardening.conf' | head -n 1)"

    local test_domain="nginx.localhost.com"
    local test_proto="https"
    local test_port="443"

    if [[ -n "$site_conf" && -f "$site_conf" ]]; then
        test_domain="$(awk '/^[[:space:]]*server_name[[:space:]]+/{gsub(/;/,"",$2); print $2; exit}' "$site_conf")"
        if grep -qE '^[[:space:]]*listen[[:space:]]+[0-9]+[[:space:]]+ssl' "$site_conf"; then
            test_proto="https"
            test_port="$(awk '/^[[:space:]]*listen[[:space:]]+[0-9]+[[:space:]]+ssl/{print $2; exit}' "$site_conf")"
        else
            test_proto="http"
            test_port="$(awk '/^[[:space:]]*listen[[:space:]]+[0-9]+/{gsub(/;/,"",$2); print $2; exit}' "$site_conf")"
        fi
    fi

    local attempt
    for attempt in 1 2 3 4 5; do
        if curl -s -k -o /dev/null -w '%{http_code}' -H "Host: ${test_domain}" "${test_proto}://127.0.0.1:${test_port}/healthz" | grep -q '^200$'; then
            log "✅ Installation Test SUCCESSFUL. ${test_proto^^} site (${test_domain}) is live."
            return
        fi
        log "   Attempt $attempt/5: site (${test_domain} on ${test_proto}:${test_port}) not ready yet, retrying..."
        sleep 2
    done
    fail_and_rollback "Installation Test FAILED. ${test_proto^^} site (${test_domain}) did not return HTTP 200 on /healthz."
}

# --- Main Execution Flow ---
trap 'rollback' EXIT

setup_init_compat
capture_system_state
verify_and_install_dependencies
run_configuration
test_installation

log "--- NGINX Installation & Configuration COMPLETED SUCCESSFULLY ---"

# Success: no rollback; just clean up temp files (the EXIT trap removes the shim)
ROLLBACK_NEEDED=0
rm -f "$STATE_FILE" /tmp/installed_packages_before.list