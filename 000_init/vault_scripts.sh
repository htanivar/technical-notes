#!/bin/bash

# Variables
VAULT_VERSION="1.15.1"
APPLICATION_DIR="/opt/vault"
LOG_DIR="/var/log/vault"
VAULT_BINARY="$APPLICATION_DIR/vault"
VAULT_PORT=8200
VALID_COMMANDS=("start" "stop" "status" "debug")

# Function to verify Vault installation and report information
function verify_vault() {
  if command -v vault &> /dev/null; then
    vault_version=$(vault version)
    echo "Vault is installed: $vault_version"
    echo "Installation Location: $APPLICATION_DIR"
    echo "Log Location: $LOG_DIR"
    echo "Running Port Number: $VAULT_PORT"
  else
    echo "Vault is not installed."
  fi
}

# Function to start Vault
function start_vault() {
  echo "Starting Vault..."
  nohup $VAULT_BINARY server -config=$APPLICATION_DIR/config.hcl > $LOG_DIR/vault.log 2>&1 &
  echo "Vault started."
}

# Function to stop Vault
function stop_vault() {
  echo "Stopping Vault..."
  pkill vault
  echo "Vault stopped."
}

# Function to check the status of Vault
function status_vault() {
  if pgrep -x "vault" > /dev/null; then
    echo "Vault is running."
  else
    echo "Vault is not running."
  fi
}

# Function to run Vault in debug mode
function debug_vault() {
  echo "Running Vault in debug mode..."
  $VAULT_BINARY server -config=$APPLICATION_DIR/config.hcl -log-level=debug
}

# Main script logic
if [ $# -eq 0 ]; then
  verify_vault
elif [ $# -eq 1 ]; then
  case "$1" in
    start)
      start_vault
      ;;
    stop)
      stop_vault
      ;;
    status)
      status_vault
      ;;
    debug)
      debug_vault
      ;;
    *)
      echo "Invalid command. Valid commands are: ${VALID_COMMANDS[*]}"
      exit 1
      ;;
  esac
else
  echo "Only one command is allowed at a time. Valid commands are: ${VALID_COMMANDS[*]}"
  exit 1
fi
