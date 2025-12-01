#!/usr/bin/env bash
set -euo pipefail

# medusa.sh <env> <up|down|start|stop>
# Valid envs   : dev, tst, uat, prd
# Valid actions: up, down, start, stop

VALID_ENVS=("dev" "tst" "uat" "prd")
VALID_ACTIONS=("up" "down" "start" "stop")

if [[ "${1-}" == "" || "${2-}" == "" ]]; then
  echo "Usage: $0 <dev|tst|uat|prd> <up|down|start|stop>"
  exit 1
fi

ENV="$1"
ACTION="$2"
PROJECT_DIR="${ENV}-medusa-store"

if [[ ! " ${VALID_ENVS[*]} " =~ " ${ENV} " ]]; then
  echo "Invalid environment: $ENV"
  echo "Valid: dev, tst, uat, prd"
  exit 1
fi

if [[ ! " ${VALID_ACTIONS[*]} " =~ " ${ACTION} " ]]; then
  echo "Invalid action: $ACTION"
  echo "Valid: up, down, start, stop"
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project directory '$PROJECT_DIR' not found."
  exit 1
fi

cd "$PROJECT_DIR"

case "$ACTION" in
  up)
    npm run docker:up
    ;;
  down)
    npm run docker:down
    ;;
  start)
    npm run docker:start
    ;;
  stop)
    npm run docker:stop
    ;;
esac
