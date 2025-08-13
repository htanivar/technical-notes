#!/bin/bash

read -p "Enter image name or ID: " image

# Check if image exists
if ! docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -qw "$image"; then
    echo "Image '$image' not found."
    exit 1
fi

# Delete image
docker rmi -f "$image"
echo "Image '$image' deleted."
