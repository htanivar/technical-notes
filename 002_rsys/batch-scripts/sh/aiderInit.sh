#!/bin/bash

# Define the required environment variables
REQUIRED_VARS=("DEEPSEEK_API_KEY" "DEEPSEEK_MODEL" "OPENAI_API_BASE")

# --- Function to check environment variables ---
check_env_vars() {
    echo "Checking for required environment variables..."
    local missing_vars=()
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        echo -e "\nError: The following environment variables are not set:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo -e "\nPlease set these variables and try again."
        echo "Example: export DEEPSEEK_API_KEY=\"<your_key>\""
        return 1
    fi

    echo "All required environment variables are set."
    return 0
}

# --- Function to launch Aider ---
launch_aider() {
    echo -e "\nLaunching Aider with DeepSeek model: $DEEPSEEK_MODEL"
    echo "Using API base: $OPENAI_API_BASE"

    # Launch aider with the correct parameters
    exec aider --model "openai/$DEEPSEEK_MODEL" \
        --openai-api-base "$OPENAI_API_BASE" \
        --openai-api-key "$DEEPSEEK_API_KEY" \
        "$@"
}

# --- Main script logic ---
if check_env_vars; then
    echo -e "\nVerification complete. Launching Aider..."
    # Launch aider with all arguments passed to this script
    launch_aider "$@"
fi