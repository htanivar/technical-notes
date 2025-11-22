#!/bin/bash

# --- Function Definitions ---

# Function to display colored messages
log() {
    local type=$1
    local message=$2
    local color_code

    case "$type" in
        INFO) color_code='\033[0;32m' ;; # Green
        WARN) color_code='\033[0;33m' ;; # Yellow
        ERROR) color_code='\033[0;31m' ;; # Red
        STEP) color_code='\033[0;36m' ;; # Cyan
        *) color_code='\033[0m' ;;    # Reset
    esac

    echo -e "${color_code}[$(date +'%Y-%m-%d %H:%M:%S')] $type: $message\033[0m"
}

# Function to execute a command and check for errors
exec_cmd() {
    log STEP "Executing: $1"
    eval "$1"
    if [ $? -ne 0 ]; then
        log ERROR "Command failed: $1"
        exit 1
    fi
}

# Function to print usage guide
usage() {
    log INFO "Usage: $0 <ENVIRONMENT_NAME>"
    log INFO ""
    log INFO "  <ENVIRONMENT_NAME> : e.g., dev, tst, uat, prd. Used for directory name and container names."
    log INFO ""
    log INFO "Example: $0 dev"
    exit 1
}

# --- Script Execution Start ---

# Check for required arguments
if [ "$#" -lt 1 ]; then
    log ERROR "Missing required arguments."
    usage
fi


# --- Parameter Assignment ---
ENV_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for paths/names
PROJECT_DIR="${ENV_NAME}-shop"


## 1. Clone the Medusa starter repository
log STEP "1. Cloning Shop Starter repository into $PROJECT_DIR..."
exec_cmd "git clone https://github.com/medusajs/nextjs-starter-medusa.git --depth=1 $PROJECT_DIR"


## 2. Change into the project directory
log STEP "2. Changing directory to $PROJECT_DIR..."
exec_cmd "cd $PROJECT_DIR"
