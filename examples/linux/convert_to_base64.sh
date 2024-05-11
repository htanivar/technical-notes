#!/bin/bash

# Check if the filename argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Assign filename from command-line argument
filename="$1"

# Check if the file exists
if [ ! -f "$filename" ]; then
    echo "Error: File '$filename' not found."
    exit 1
fi

# Base64 encode the file content
base64_content=$(base64 "$filename")

# Create the output filename with .base64 extension
output_filename="${filename}.base64"

# Write the Base64 content to the output file
echo "$base64_content" > "$output_filename"

echo "File '$filename' converted to Base64 and saved as '$output_filename'."
