#!/usr/bin/env bash
# Check if the output of 'id -u' is not equal to 0
if [ "$(id -u)" -ne 0 ]; then
    echo "🚨 This script must be run with root privileges (e.g., using 'sudo')." >&2
    exit 1
fi

# The rest of your script
echo "Root privileges detected. Continuing script execution..."

set -euo pipefail

# delete-medusa.sh
# Usage:
#   delete-medusa.sh <env-or-project> [-y]
# Examples:
#   delete-medusa.sh dev
#   delete-medusa.sh dev-medusa-store
#   delete-medusa.sh prod -y

if [[ "${1-}" == "" ]]; then
  cat <<USAGE
Usage: $0 <env-or-project> [-y]
  <env-or-project>  : short env (e.g. "dev") or full project name (e.g. "dev-medusa-store")
  -y                : skip confirmation
USAGE
  exit 1
fi

ARG="$1"
shift || true

FORCE=false
while [[ "${1-}" != "" ]]; do
  case "$1" in
    -y|--yes|--force) FORCE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# If user passed "dev", convert to "dev-medusa-store"
if [[ "$ARG" == *"-"* ]]; then
  PROJECT_NAME="$ARG"
else
  PROJECT_NAME="${ARG}-medusa-store"
fi

PROJECT_DIR="$(pwd)/${PROJECT_NAME}"

echo "Project       : $PROJECT_NAME"
echo "Project folder: $PROJECT_DIR"

if ! $FORCE; then
  read -r -p "This will delete containers, volumes, networks, images AND project folder '$PROJECT_DIR'. Continue? [y/N] " yn
  case "$yn" in
    [Yy]* ) ;;
    * ) echo "Aborted."; exit 0 ;;
  esac
fi

echo "Stopping and removing Docker Compose resources..."
docker compose -p "$PROJECT_NAME" down --remove-orphans --rmi local -v || true

echo "Removing stray containers..."
mapfile -t CTS < <(docker ps -a --format '{{.ID}} {{.Names}}' | awk -v p="${PROJECT_NAME}_" '$2 ~ ("^"p) {print $1}')
if (( ${#CTS[@]} > 0 )); then
  docker rm -f "${CTS[@]}" || true
fi

echo "Removing networks..."
mapfile -t NWS < <(docker network ls --format '{{.Name}}' | grep -E "^${PROJECT_NAME}_" || true)
if (( ${#NWS[@]} > 0 )); then
  docker network rm "${NWS[@]}" || true
fi

echo "Removing volumes..."
mapfile -t VOLS < <(docker volume ls --format '{{.Name}}' | grep -E "^${PROJECT_NAME}_" || true)
if (( ${#VOLS[@]} > 0 )); then
  docker volume rm -f "${VOLS[@]}" || true
fi

echo "Pruning unused images..."
docker image prune -f || true

if [[ -d "$PROJECT_DIR" ]]; then
  echo "Deleting project folder: $PROJECT_DIR"
  rm -rf "$PROJECT_DIR"
else
  echo "Project folder does not exist, skipping."
fi

echo "Cleanup completed for '$PROJECT_NAME'."
