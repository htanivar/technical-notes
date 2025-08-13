#!/bin/bash

read -p "Enter image name: " image

# Allow user to enter without tag (defaults to latest)
if [[ "$image" != *:* ]]; then
    image="$image:latest"
fi

# Check if image exists locally
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
    echo "Image '$image' not found locally."
    exit 1
fi

# List containers attached to the image
containers=$(docker ps -a --filter "ancestor=$image" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}")

if [ -z "$containers" ]; then
    echo "No containers found for image '$image'."
else
    echo "Containers for image '$image':"
    echo "$containers"
fi
