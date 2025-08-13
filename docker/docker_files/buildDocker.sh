#!/bin/bash

read -p "Enter image name: " image

# Check if folder exists
if [ ! -d "$image" ]; then
    echo "Folder '$image' not found."
    exit 1
fi

# Check if Dockerfile exists in the folder
if [ ! -f "$image/Dockerfile" ]; then
    echo "Dockerfile not found in folder '$image'."
    exit 1
fi

# Build image
docker build -t "$image" "$image"
echo "Image '$image' built successfully."
