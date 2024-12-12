#!/bin/bash

# Define environment URLs
dev_url="https://dev.example.com"
int_url="https://int.example.com"
stg_url="https://stg.example.com"
prd_url="https://prd.example.com"

# Check that environment variables are set and not empty
check_env_var() {
  local env_name="$1"
  local env_value="$2"

  if [ -z "$env_value" ]; then
    echo "Error: Environment variable $env_name is not set or is empty."
    exit 1
  fi
}

# Validate URLs
check_valid_url() {
  local url="$1"
  if [[ ! "$url" =~ ^https?:// ]]; then
    echo "Error: Invalid URL configured: $url"
    exit 1
  fi
}

# Check environment variables for dev, int, stg, prd
check_env_var "DEV" "$dev_url"
check_env_var "INT" "$int_url"
check_env_var "STG" "$stg_url"
check_env_var "PRD" "$prd_url"

# Check if the URLs are valid
check_valid_url "$dev_url"
check_valid_url "$int_url"
check_valid_url "$stg_url"
check_valid_url "$prd_url"

# Function to accept input safely
safe_input() {
  read -p "Enter the environment (dev, int, stg, prd): " env
  if [[ "$env" != "dev" && "$env" != "int" && "$env" != "stg" && "$env" != "prd" ]]; then
    echo "Error: Invalid environment. Only dev, int, stg, and prd are allowed."
    exit 1
  fi

  read -p "Enter the rotation ID: " rotation_id
  if [ -z "$rotation_id" ]; then
    echo "Error: Rotation ID cannot be empty."
    exit 1
  fi

  # Select URL based on the environment
  case "$env" in
    dev) url="$dev_url" ;;
    int) url="$int_url" ;;
    stg) url="$stg_url" ;;
    prd) url="$prd_url" ;;
  esac

  # Issue a curl request
  curl "$url/v1/rotation/$rotation_id"
}

# Call the safe input function
safe_input
