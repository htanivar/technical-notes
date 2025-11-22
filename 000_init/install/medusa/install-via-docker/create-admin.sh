#!/bin/bash



# Check if the output of 'id -u' is not equal to 0
if [ "$(id -u)" -ne 0 ]; then
    echo "🚨 This script must be run with root privileges (e.g., using 'sudo')." >&2
    exit 1
fi

# Check for valid environment parameter
if [ $# -ne 1 ]; then
    echo "Usage: $0 [dev|tst|uat|prd]"
    exit 1
fi

ENV=$1
VALID_ENVS=("dev" "tst" "uat" "prd")

# Check if the provided environment is valid
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENV} " ]]; then
    echo "🚨 Invalid environment '$ENV'. Must be one of: ${VALID_ENVS[*]}"
    exit 1
fi

echo "Root privileges detected. Continuing script execution for '$ENV' environment..."

# Set variables
MEDUSA_ADMIN=""
MEDUSA_ADMIN_PASSWORD=""

# Function to execute a command and check for errors
exec_cmd() {
    log STEP "Executing: $1"
    eval "$1"
    if [ $? -ne 0 ]; then
        log ERROR "Command failed: $1"
        exit 1
    fi
}


# Try to read from the .env file first
ENV_FILE="infra/${ENV}/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Reading credentials from $ENV_FILE"
    # Source the .env file to get the variables
    set -a
    source "$ENV_FILE"
    set +a
    MEDUSA_ADMIN=${MEDUSA_ADMIN:-""}
    MEDUSA_ADMIN_PASSWORD=${MEDUSA_ADMIN_PASSWORD:-""}
fi

# If still empty, try environment variables
if [ -z "$MEDUSA_ADMIN" ]; then
    MEDUSA_ADMIN=${MEDUSA_ADMIN:-""}
fi

if [ -z "$MEDUSA_ADMIN_PASSWORD" ]; then
    MEDUSA_ADMIN_PASSWORD=${MEDUSA_ADMIN_PASSWORD:-""}
fi

# Check if variables are set
if [ -z "$MEDUSA_ADMIN" ]; then
    echo "🚨 MEDUSA_ADMIN is not set. Please set it using:"
    echo "   export MEDUSA_ADMIN=your_admin_email@example.com"
    exit 1
fi

if [ -z "$MEDUSA_ADMIN_PASSWORD" ]; then
    echo "🚨 MEDUSA_ADMIN_PASSWORD is not set. Please set it using:"
    echo "   export MEDUSA_ADMIN_PASSWORD=your_secure_password"
    exit 1
fi

PROJECT_DIR="${ENV}-medusa-store"
log STEP "2. Changing directory to $PROJECT_DIR..."
exec_cmd "cd $PROJECT_DIR"

echo "Creating admin user with email: $MEDUSA_ADMIN"

# Run the docker command
docker compose run --rm medusa npx medusa user -e "$MEDUSA_ADMIN" -p "$MEDUSA_ADMIN_PASSWORD"