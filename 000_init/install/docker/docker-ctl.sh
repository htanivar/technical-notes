#!/usr/bin/env bash
# docker-ctl.sh — Unified entrypoint for Docker installation, status, diagnostics, and lifecycle management.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  all          Run full lifecycle: pre -> install -> status
  pre          Prepare host, configure repos/keys, and cache packages (pre.sh)
  install      Install Docker Engine and start services (install_docker.sh)
  status       Display comprehensive Docker status report (status.sh)
  diagnose     Run 12-point diagnostic check (diagnose.sh)
  repair       Run diagnostics with automatic self-healing (diagnose.sh --fix)
  uninstall    Stop services and remove Docker packages (uninstall_docker.sh)
  unpre        Undo repository, keyring, cache, and group changes (unpre.sh)
  purge        Full removal: uninstall --purge-data + unpre
  help         Show this help message

Examples:
  sudo ./docker-ctl.sh all
  sudo ./docker-ctl.sh install --verify-container
  ./docker-ctl.sh status
  ./docker-ctl.sh status --json
  ./docker-ctl.sh diagnose
  sudo ./docker-ctl.sh repair
  sudo ./docker-ctl.sh purge
EOF
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  all)
    "${SCRIPT_DIR}/pre.sh" "$@"
    "${SCRIPT_DIR}/install_docker.sh"
    "${SCRIPT_DIR}/status.sh"
    ;;
  pre)
    exec "${SCRIPT_DIR}/pre.sh" "$@"
    ;;
  install)
    exec "${SCRIPT_DIR}/install_docker.sh" "$@"
    ;;
  status)
    exec "${SCRIPT_DIR}/status.sh" "$@"
    ;;
  diagnose|diag)
    exec "${SCRIPT_DIR}/diagnose.sh" "$@"
    ;;
  repair|fix)
    exec "${SCRIPT_DIR}/diagnose.sh" --fix "$@"
    ;;
  uninstall|remove)
    exec "${SCRIPT_DIR}/uninstall_docker.sh" "$@"
    ;;
  unpre|clean)
    exec "${SCRIPT_DIR}/unpre.sh" "$@"
    ;;
  purge)
    "${SCRIPT_DIR}/uninstall_docker.sh" --purge-data "$@"
    "${SCRIPT_DIR}/unpre.sh"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    log_err "Unknown command: ${cmd}"
    usage
    exit 1
    ;;
esac

