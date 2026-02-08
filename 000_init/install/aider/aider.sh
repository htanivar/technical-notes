#!/usr/bin/env bash
set -euo pipefail

APP="aider"
LOG_FILE="/tmp/aider_install_$(date +%Y%m%d%H%M%S).log"

log() {
  echo "$(date '+%F %T') [$1] ${*:2}" | tee -a "$LOG_FILE"
}

fail() {
  log ERROR "$1"
  exit 1
}

# --- Root check ---
if [ "$EUID" -eq 0 ]; then
  fail "Do NOT run this script as root. Run as a normal user."
fi

# --- Prerequisites ---
log INFO "Checking prerequisites"

for cmd in python3 git; do
  command -v "$cmd" >/dev/null || fail "Missing required command: $cmd"
done

# --- Install pipx if needed ---
if ! command -v pipx >/dev/null; then
  log INFO "Installing pipx via apt"
  sudo apt update
  sudo apt install -y pipx
fi

pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

command -v pipx >/dev/null || fail "pipx not found in PATH"

# --- Install aider ---
log INFO "Installing aider-chat via pipx"

if pipx list | grep -q aider-chat; then
  pipx reinstall aider-chat
else
  pipx install aider-chat
fi

# --- Verify ---
log INFO "Verifying installation"

command -v aider >/dev/null || fail "aider not found in PATH"

aider --version | tee -a "$LOG_FILE"

log SUCCESS "aider installed successfully"
log INFO "Log file: $LOG_FILE"
