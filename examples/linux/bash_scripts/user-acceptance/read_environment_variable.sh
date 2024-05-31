#!/bin/bash

# Define the environment variable name
env_var_name="SALT_PASSWORD"

# Check if the environment variable is set and not empty
if [ -z "${!env_var_name}" ]; then
  # Prompt the user to enter the value for the environment variable
  read -p "Enter the value for $env_var_name: " env_var_value

  # Check if the user entered a value
  if [ -z "$env_var_value" ]; then
    echo "No value entered. Cannot proceed."
    exit 1
  else
    export $env_var_name="$env_var_value"
  fi
else
  env_var_value="${!env_var_name}"
fi

# Display the environment variable value
echo "$env_var_name is set to: $env_var_value"
