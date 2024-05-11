#!/bin/bash

# Check if at least one filename argument is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <base64_file> [output_file]"
    exit 1
fi

# Assign base64 file from command-line argument
base64_file="$1"

# Check if the base64 file exists
if [ ! -f "$base64_file" ]; then
    echo "Error: File '$base64_file' not found."
    exit 1
fi

# Decode the Base64 content
decoded_content=$(base64 -d "$base64_file")

# Determine the output filename
if [ "$#" -ge 2 ]; then
    # Use the specified output filename if provided
    output_filename="$2"
else
    # Extract the filename without extension
    filename=$(basename "$base64_file" | sed 's/\..*$//')

    # Extract the extension from the input filename
    extension=$(basename "$base64_file" | sed 's/^.*\.//' | grep -o '^[^.]*$')

    # Check if the output filename already exists
    if [ -f "$filename.$extension" ]; then
        # Extract the version number from the filename
        version=$(echo "$filename" | grep -o '[0-9]*$')
        if [ -z "$version" ]; then
            # If no version number found, set it to 1
            version=1
        else
            # Increment the version number
            version=$((version + 1))
        fi
        # Append the version number to the filename
        filename="${filename}${version}"
    else
        # If the output filename does not exist, use it as is
        filename="${filename}"
    fi

    # Append the extension if it exists
    if [ ! -z "$extension" ]; then
        filename="${filename}.${extension}"
    fi

    # Set the output filename
    output_filename="$filename"
fi

# Write the decoded content to the output file
echo "$decoded_content" > "$output_filename"

echo "Base64 file '$base64_file' decoded and saved as '$output_filename'."
