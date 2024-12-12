#!/bin/bash

# Associative array (map) of commands and URLs
declare -A url_map=(
  ["google"]="https://www.google.co.uk"
  ["yahoo"]="https://www.yahoo.com"
  ["github"]="https://github.com"
  ["stackoverflow"]="https://stackoverflow.com"
)

# Function to open URL based on the command
nav() {
  local url=${url_map[$1]}

  if [ -n "$url" ]; then
    chrome "$url"
  else
    echo "Command not found. Available commands: ${!url_map[@]}"
  fi
}
