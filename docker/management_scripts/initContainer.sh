#!/bin/bash

read -p "Enter image name: " image

# Check if a container exists for this image
container_id=$(docker ps -a --filter "ancestor=$image" --format "{{.ID}}" | head -n 1)

if [ -n "$container_id" ]; then
    read -p "Container already exists. Create new? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        docker run -it "$image" /bin/sh
    else
        docker start -ai "$container_id"
    fi
else
    docker run -it "$image" /bin/sh
fi
