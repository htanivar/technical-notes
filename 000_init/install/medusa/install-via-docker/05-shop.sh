#!/usr/bin/env bash
# 05-shop.sh <env> <action>

# Set strict error checking
set -euo pipefail

# --- Configuration ---
VALID_ENVS=("dev" "tst" "uat" "prd")
DETACHED_ACTIONS=("dev" "start")
FOREGROUND_ACTIONS=("build" "lint" "analyze")
VALID_ACTIONS=("${DETACHED_ACTIONS[@]}" "${FOREGROUND_ACTIONS[@]}" "stop")

PID_FILE="pid.log"
LOG_FILE_SUFFIX=".log"

# --- Helper Functions ---

# Function to check if the script is run with sudo
check_sudo() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be executed with 'sudo'."
    exit 1
  fi
}

# Function to validate environment and action arguments
validate_args() {
  if [[ "$1" == "stop" ]]; then
    ACTION="stop"
    return
  fi

  if [[ "${1-}" == "" || "${2-}" == "" ]]; then
    echo "Usage: $0 <dev|tst|uat|prd> <dev|start|build|lint|analyze>"
    echo "To stop a running process: $0 stop"
    exit 1
  fi

  if ! printf '%s\n' "${VALID_ENVS[@]}" | grep -q -P "^$1$"; then
    echo "Error: Invalid environment '$1'."
    echo "Valid environments: ${VALID_ENVS[*]}"
    exit 1
  fi

  if ! printf '%s\n' "${VALID_ACTIONS[@]}" | grep -q -P "^$2$"; then
    echo "Error: Invalid action '$2'."
    echo "Valid actions: ${VALID_ACTIONS[*]}"
    exit 1
  fi
}

# Function to stop the background process
stop_process() {
  if [[ -f "${PID_FILE}" ]]; then
    PID=$(cat "${PID_FILE}")

    if ps -p "${PID}" > /dev/null; then
      echo "Stopping process with PID: ${PID}"
      sudo kill "${PID}"
      echo "Process killed."
      rm "${PID_FILE}"
    else
      echo "No running process found with PID ${PID} recorded in ${PID_FILE}. Removing stale PID file."
      rm "${PID_FILE}"
    fi
  else
    echo "Error: ${PID_FILE} not found. No running process started by this script to stop."
    exit 1
  fi
}

# --- Main Logic ---

# 1. Check for sudo
check_sudo

# 2. Validate arguments
validate_args "$1" "$2"

# Assign validated arguments
ENV="${1-}"
ACTION="${2-}"
PROJECT_DIR="${ENV}-shop"

echo "--- Executing action '${ACTION}' for environment '${ENV}' ---"

# 3. Handle 'stop' action
if [[ "${ACTION}" == "stop" ]]; then
  stop_process
  exit 0
fi

# 4. Change directory (required for all remaining actions)
echo "Moving to project directory: ${PROJECT_DIR}"
if ! cd "${PROJECT_DIR}"; then
  echo "Error: Directory ${PROJECT_DIR} not found. Ensure the directory exists."
  exit 1
fi

# 5. Execute action

# Check if the action is one that should run in detached mode
if printf '%s\n' "${DETACHED_ACTIONS[@]}" | grep -q -P "^${ACTION}$"; then

    echo "Action: ${ACTION}. Starting service in detached mode..."

    # Check for existing PID to prevent running multiple services
    if [[ -f "${PID_FILE}" ]]; then
        echo "Error: A process is already running. Check ${PID_FILE} or run '$0 stop'."
        exit 1
    fi

    # Issue the command in detached mode and capture PID
    LOG_FILE="${PROJECT_DIR}${LOG_FILE_SUFFIX}"

    # nohup runs the command in the background
    nohup npm run "${ACTION}" > "${LOG_FILE}" 2>&1 &

    SERVICE_PID=$!

    # Log the PID to the file
    echo "${SERVICE_PID}" > "${PID_FILE}"

    echo "Service started in detached mode."
    echo "Process ID (PID) recorded in ${PID_FILE}: ${SERVICE_PID}"

    # --- NEW STEP: Monitor the log file ---
    echo "Opening log file for live monitoring (Press Ctrl+C to exit monitoring):"

    # Use exec to replace the shell process with tail -f
    exec tail -f "${LOG_FILE}"

# If not a detached action, run it in the foreground
elif printf '%s\n' "${FOREGROUND_ACTIONS[@]}" | grep -q -P "^${ACTION}$"; then
    echo "Action '${ACTION}' is a one-time task. Running in foreground."
    exec npm run "${ACTION}"

else
    echo "Error: Unknown action type."
    exit 1
fi