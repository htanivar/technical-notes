#!/usr/bin/env bash
# unpre.sh — Undo preparation performed by pre.sh:
# - Reverts docker group/user membership if created/added by pre.sh
# - Removes Docker APT/RPM repository and GPG keyring files
# - Removes cached package artifacts (/var/cache/docker-install) and state (/var/lib/docker-install)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

require_root "$@"

if [[ -f "$STATE_FILE" ]]; then
  state_load || true
else
  log_warn "State file ($STATE_FILE) not found; performing best-effort cleanup using default paths..."
fi

detect_os_and_arch
mkdir -p "$LOG_DIR"
setup_logging "unpre.sh"

export DEBIAN_FRONTEND=noninteractive

TARGET_USER="${TARGET_USER:-$(detect_target_user)}"
USER_ADDED_TO_DOCKER="${USER_ADDED_TO_DOCKER:-0}"
DOCKER_GROUP_CREATED="${DOCKER_GROUP_CREATED:-0}"
DOCKER_LIST="${DOCKER_LIST:-${APT_REPO_DIR}/docker.list}"
DOCKER_KEYRING="${DOCKER_KEYRING:-${KEYRING_DIR}/docker.gpg}"
DOCKER_YUM_REPO="${DOCKER_YUM_REPO:-${YUM_REPO_DIR}/docker-ce.repo}"

########################
# 1. Revert User / Group
########################
log_step "Reverting user/group changes..."
if [[ "$USER_ADDED_TO_DOCKER" == "1" && -n "$TARGET_USER" ]]; then
  if id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    if command -v gpasswd >/dev/null 2>&1 && gpasswd -d "$TARGET_USER" docker >/dev/null 2>&1; then
      log_ok "Removed '${TARGET_USER}' from 'docker' group"
    elif command -v delgroup >/dev/null 2>&1 && delgroup "$TARGET_USER" docker >/dev/null 2>&1; then
      log_ok "Removed '${TARGET_USER}' from 'docker' group"
    else
      log_warn "Could not remove '${TARGET_USER}' from 'docker' group"
    fi
  fi
fi

if [[ "$DOCKER_GROUP_CREATED" == "1" ]]; then
  if getent group docker >/dev/null 2>&1; then
    if [[ -z "$(getent group docker | awk -F: '{print $4}')" ]]; then
      if command -v groupdel >/dev/null 2>&1 && groupdel docker 2>/dev/null; then
        log_ok "Deleted group 'docker'"
      elif command -v delgroup >/dev/null 2>&1 && delgroup docker 2>/dev/null; then
        log_ok "Deleted group 'docker'"
      else
        log_warn "Failed to delete 'docker' group"
      fi
    else
      log_info "'docker' group still has members; skipping group deletion"
    fi
  fi
fi

########################
# 2. Remove Repos & Keyrings
########################
log_step "Removing Docker repository and keyring configurations..."
if [[ -f "$DOCKER_LIST" || -f "$DOCKER_KEYRING" ]]; then
  rm -f "$DOCKER_LIST" "$DOCKER_KEYRING"
  log_ok "Removed ${DOCKER_LIST} and ${DOCKER_KEYRING}"
  if [[ "$PKG_FAMILY" == "apt" ]]; then
    apt-get update -y >/dev/null 2>&1 || true
  fi
fi

if [[ -f "$DOCKER_YUM_REPO" ]]; then
  rm -f "$DOCKER_YUM_REPO"
  log_ok "Removed ${DOCKER_YUM_REPO}"
fi

########################
# 3. Remove Cache & State
########################
log_step "Removing package cache (${CACHE_DIR}) and state (${STATE_DIR})..."
rm -rf "$CACHE_DIR"
rm -f "${MANIFEST_FILE:-}"
rm -rf "$STATE_DIR"
log_ok "Cleaned cache and state directories."

log_ok "unpre.sh completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
