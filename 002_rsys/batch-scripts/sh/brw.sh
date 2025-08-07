#!/bin/bash

# Define site mappings (associative array for easier lookup)
declare -A SITES
SITES["abacus"]="https://apps.abacus.ai"
SITES["chatgpt"]="https://chatgpt.com"
SITES["gemini"]="https://gemini.google.com"
SITES["aistudio"]="https://aistudio.google.com"
SITES["google"]="https://google.com"
SITES["github"]="https://github.com"
SITES["gitlab"]="https://gitlab.com"
SITES["vikatan"]="https://vikatan.com"
SITES["learn"]="https://learn.jaganathan.co.uk"
SITES["hdfc"]="https://www.hdfcbank.com"
SITES["veda"]="https://veda.jaganathan.co.uk"
SITES["local-taga"]="https://localhost:1703"
SITES["taga"]="https://taga.jaganathan.co.uk:1703"
SITES["devtaga"]="http://localhost:8080"

# Check for argument
if [ -z "$1" ]; then
    echo "Usage: brw [site]"
    exit 1
fi

# Normalize to lowercase (using Bash parameter expansion)
site_key="${1,,}"

# Get URL from the associative array
url="${SITES[$site_key]}"

if [ -z "$url" ]; then
    echo "Site \"$1\" not found."
    exit 1
fi

# Open the URL in the default web browser
xdg-open "$url" &

exit 0
