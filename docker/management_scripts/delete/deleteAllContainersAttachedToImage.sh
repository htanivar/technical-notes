#!/bin/bash

read -p "Enter image name: " image

# Allow without tag (defaults to latest)
if [[ "$image" != *:* ]]; then
    image="$image:latest"
fi

# Check if image exists locally
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
    echo "Image '$image' not found locally."
    exit 1
fi

# Find containers attached to this image
containers=$(docker ps -a --filter "ancestor=$image" --format "{{.ID}}")

if [ -z "$containers" ]; then
    echo "No containers found for image '$image'."
    exit 0
fi

# Delete them
echo "Deleting containers attached to image '$image'..."
docker rm -f $containers
echo "Deleted."
