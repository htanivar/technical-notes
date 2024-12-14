#!/bin/bash

# Function to validate the URL
validate_url() {
    if [[ "$1" =~ ^https?://[a-zA-Z0-9./?=_-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Read the URL as input
read -p "Enter the URL: " URL

# Validate the URL
if ! validate_url "$URL"; then
    echo "Invalid URL. Please enter a valid URL."
    exit 1
fi

# Send the GET request and store the response
response=$(curl -s -X GET "$URL")

# Check if curl encountered an error
if [ $? -ne 0 ]; then
    echo "Failed to retrieve data from the URL."
    exit 1
fi

# Declare an associative array to hold the key-value pairs
declare -A json_data

# Extract all key-value pairs from the JSON response and store them in the associative array
while IFS=":" read -r key value; do
    # Remove double quotes and spaces
    key=$(echo "$key" | tr -d '"' | tr -d ' ')
    value=$(echo "$value" | tr -d '"' | tr -d ' ')

    # Store in the associative array
    json_data["$key"]="$value"
done < <(echo "$response" | grep -o '"[^"]*":[^,}]*')

# Example: Access the values in the array
for key in "${!json_data[@]}"; do
    echo "Key: $key, Value: ${json_data[$key]}"
done

# You can now use the associative array for further processing
