#!/bin/bash

# Function to sanitize and encode a URL
sanitize_and_encode_url() {
    local url="$1"

    # Remove non-printable characters
    local clean_url=$(echo "$url" | sed 's/[^[:print:]]//g')

    # Encode the URL using Python's urllib
    local encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$clean_url'''))")

    echo "$encoded_url"
}

# Example usage
url="http://example.com/path with spaces and invalid chars\x00\x01"
encoded_url=$(sanitize_and_encode_url "$url")
echo "Sanitized and encoded URL: $encoded_url"
