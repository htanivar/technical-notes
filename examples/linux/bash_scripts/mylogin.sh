#!/bin/bash

CONFIG_FILE="config.txt"

# Function to validate parameters
validate_params() {
    local service="$1"
    local dc="$2"
    local environment="$3"
    local oc_task="$4"

    # Validate service
    if ! grep -q "$service" <<< "OneService TwoService ThreeService FourService FiveService SixService SevenService EightService NineService TenService"; then
        echo "Invalid service: $service"
        exit 1
    fi

    # Validate data center
    if ! grep -q "$dc" <<< "AB CD XY ZY"; then
        echo "Invalid data center: $dc"
        exit 1
    fi

    # Validate environment
    if ! grep -q "$environment" <<< "dev int stg prd"; then
        echo "Invalid environment: $environment"
        exit 1
    fi

    # Validate oc_task
    if ! grep -q "$oc_task" <<< "rsh logs config"; then
        echo "Invalid oc_task: $oc_task"
        exit 1
    fi
}

# Function to get project ID and API URL
get_project_details() {
    local service="$1"
    local dc="$2"
    local environment="$3"

    local project_id=$(echo "$project_info" | cut -d',' -f4)
    local api_url=$(echo "$project_info" | cut -d',' -f5 | tr -d '\r')

    # Check if the URL is valid
    if ! [[ $api_url =~ ^https?:// ]]; then
        echo "Invalid API URL: $api_url"
        exit 1
    fi

    if [[ -z "$project_id" || -z "$api_url" ]]; then
        echo "Project details not found for $service, $dc, $environment"
        exit 1
    fi

    echo "$project_id $api_url"
}

# Main script
if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 <service> <dc> <environment> <oc_task>"
    exit 1
fi

service="$1"
dc="$2"
environment="$3"
oc_task="$4"

# Validate parameters
validate_params "$service" "$dc" "$environment" "$oc_task"

# Get project ID and API URL
read project_id api_url < <(get_project_details "$service" "$dc" "$environment")

# Get username and password from environment variables
username="$OC_USERNAME"
password="$OC_PASSWORD"

if [[ -z "$username" || -z "$password" ]]; then
    echo "Username or password environment variables are not set"
    exit 1
fi

# Perform the specified oc_task
oc login "$api_url" -u "$username" -p "$password"
if [[ $? -ne 0 ]]; then
    echo "Login failed"
    exit 1
fi

case "$oc_task" in
    rsh)
        oc rsh -n "$project_id" ;;
    logs)
        oc logs -n "$project_id" ;;
    config)
        oc get config -n "$project_id" ;;
    *)
        echo "Invalid oc_task: $oc_task"
        exit 1
        ;;
esac

echo "Task $oc_task completed for service $service, data center $dc, environment $environment"
