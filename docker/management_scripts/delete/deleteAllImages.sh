#!/bin/bash

images=$(docker images -q)

if [ -z "$images" ]; then
    echo "No images to delete."
    exit 0
fi

echo "Deleting all images..."
docker rmi -f $images
echo "All images deleted."
