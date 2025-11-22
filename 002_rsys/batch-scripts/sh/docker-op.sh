#!/bin/bash

# This script provides a simplified command-line interface for common Docker operations.
# It handles service management, image operations, and container management.

# --- Help Function ---
# This function displays the available commands and their syntax.
help_menu() {
    echo "Usage: ./docker.sh <command> [<subcommand>] [<argument>]"
    echo ""
    echo "Available Commands:"
    echo "  status                  - Check the status of the Docker daemon."
    echo ""
    echo "  image <subcommand>"
    echo "    image ls              - List all local Docker images."
    echo "    image pull <image>    - Pull an image from Docker Hub."
    echo "    image search <term>   - Search for remote images on Docker Hub."
    echo "    image build <path>    - Build an image from Dockerfile at specified path."
    echo ""
    echo "  container <subcommand>"
    echo "    container list        - List all containers (running and stopped)."
    echo "    container create <name> <image> - Create and start a new container from an image."
    echo "    container start <name/id> - Start a stopped container."
    echo "    container stop <name/id>  - Stop a running container."
    echo "    container rm <name/id> - Remove a container."
    echo "    container connect <name/id>- connect to container in bash."
    echo ""
    echo "  help                    - Display this help menu."
}

# --- Functions for Docker Operations ---

# Function to check Docker service status
check_docker_status() {
    echo "Checking Docker service status..."
    sudo systemctl status docker
}

# Function to validate Dockerfile existence
validate_dockerfile() {
    local dockerfile_path="$1"

    # Check if path exists
    if [ ! -d "$dockerfile_path" ] && [ ! -f "$dockerfile_path" ]; then
        echo "Error: Path '$dockerfile_path' does not exist."
        return 1
    fi

    # If it's a directory, check for Dockerfile
    if [ -d "$dockerfile_path" ]; then
        if [ ! -f "$dockerfile_path/Dockerfile" ]; then
            echo "Error: No Dockerfile found in directory '$dockerfile_path'"
            return 1
        fi
        echo "Dockerfile found at: $dockerfile_path/Dockerfile"
        return 0
    fi

    # If it's a file, check if it's named Dockerfile
    if [ -f "$dockerfile_path" ]; then
        local filename=$(basename "$dockerfile_path")
        if [ "$filename" != "Dockerfile" ] && [ "$filename" != "dockerfile" ]; then
            echo "Error: File '$dockerfile_path' is not a Dockerfile"
            return 1
        fi
        echo "Dockerfile found at: $dockerfile_path"
        return 0
    fi

    return 1
}

# Function to handle image-related operations
handle_image_ops() {
    case "$1" in
        "ls")
            echo "Listing Docker images..."
            docker images
            ;;
        "pull")
            if [ -z "$2" ]; then
                echo "Error: Please provide an image name to pull."
                help_menu
                exit 1
            fi
            echo "Pulling image '$2' from Docker Hub..."
            docker pull "$2"
            ;;
        "search")
            if [ -z "$2" ]; then
                echo "Error: Please provide a search term."
                help_menu
                exit 1
            fi
            echo "Searching for images with term '$2'..."
            docker search "$2"
            ;;
        "build")
            if [ -z "$2" ]; then
                echo "Error: Please provide a path to Dockerfile or directory containing Dockerfile."
                help_menu
                exit 1
            fi

            # Validate Dockerfile exists
            if ! validate_dockerfile "$2"; then
                exit 1
            fi

            # Determine build context and Dockerfile path
            if [ -d "$2" ]; then
                build_context="$2"
                dockerfile_path="$2/Dockerfile"
            else
                build_context=$(dirname "$2")
                dockerfile_path="$2"
            fi

            # Ask for image name
            read -p "Enter image name (e.g., myapp:latest): " image_name
            if [ -z "$image_name" ]; then
                echo "Error: Image name is required."
                exit 1
            fi

            echo "Building image '$image_name' from $dockerfile_path..."
            echo "Build context: $build_context"

            # Build the image
            docker build -t "$image_name" -f "$dockerfile_path" "$build_context"

            if [ $? -eq 0 ]; then
                echo "Image '$image_name' built successfully!"
            else
                echo "Error: Failed to build image."
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown image subcommand: '$1'"
            help_menu
            exit 1
            ;;
    esac
}

# Function to handle multiple port mappings
setup_port_mappings() {
    local port_mappings=""

    echo "Setting up port mappings (leave empty to finish):"

    while true; do
        read -p "Container port (or press Enter to finish): " container_port
        if [ -z "$container_port" ]; then
            break
        fi

        read -p "Host port for container port $container_port: " host_port
        if [ -z "$host_port" ]; then
            echo "Error: Host port is required for container port $container_port"
            continue
        fi

        # Validate ports are numbers
        if ! [[ "$container_port" =~ ^[0-9]+$ ]] || ! [[ "$host_port" =~ ^[0-9]+$ ]]; then
            echo "Error: Ports must be numeric values."
            continue
        fi

        port_mappings="$port_mappings -p $host_port:$container_port"
        echo "Added port mapping: $host_port -> $container_port"
    done

    # Return only the port mappings without any echo messages
    echo "$port_mappings"
}

# Function to handle container-related operations
handle_container_ops() {
    case "$1" in
        "list")
            echo "Listing all Docker containers..."
            docker ps -a
            ;;
        "create")
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "Error: Please provide a container name and an image name."
                help_menu
                exit 1
            fi

            container_name="$2"
            image_name="$3"

            # Set up multiple port mappings
            echo "=== Port Mapping Configuration ==="
            # Capture only the actual port mappings, not the echo messages
            port_mappings=$(setup_port_mappings 2>/dev/null | tail -1)

            # Ask for volume mounting
            volume_mount=""
            read -p "Do you want to mount a volume? (y/N): " mount_choice
            if [[ "$mount_choice" =~ ^[Yy]$ ]]; then
                read -p "Enter host directory path: " host_path
                read -p "Enter container directory path: " container_path

                # Validate host path exists
                if [ ! -d "$host_path" ]; then
                    echo "Error: Host directory '$host_path' does not exist."
                    exit 1
                fi

                volume_mount="-v $host_path:$container_path"
                echo "Volume will be mounted: $host_path -> $container_path"
            fi

            # Build docker run command
            cmd="docker run --name \"$container_name\" -d"

            # Add port mappings if provided
            if [ -n "$port_mappings" ]; then
                cmd="$cmd $port_mappings"
                echo "Port mappings configured: $port_mappings"
            else
                echo "No port mappings configured."
            fi

            # Add volume mount if provided
            if [ -n "$volume_mount" ]; then
                cmd="$cmd $volume_mount"
            fi

            # Add image and command
            cmd="$cmd \"$image_name\" tail -f /dev/null"

            echo "Creating a new container named '$container_name' from image '$image_name'..."
            echo "Executing: $cmd"
            eval $cmd
            ;;
        "start"|"stop"|"rm")
            if [ -z "$2" ]; then
                echo "Error: Please provide a container name or ID."
                help_menu
                exit 1
            fi
            echo "Executing docker "$1" on container '$2'..."
            docker "$1" "$2"
            ;;
        "connect")
            if [ -z "$2" ]; then
                echo "Error: Please provide a container name or ID."
                help_menu
                exit 1
            fi

            # Check if the container is running
            if [ -z "$(docker ps -q -f name=^$2$ -f status=running)" ]; then
                echo "Container '$2' is not running. Starting it now..."
                # Attempt to start the container. The output of this command will be displayed.
                docker start "$2"
                # Check the exit code of the previous command to see if the start was successful
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to start container '$2'. Cannot connect."
                    exit 1
                fi
            fi

            echo "Attempting to connect with /bin/bash..."
            if ! docker exec -it "$2" /bin/bash; then
                echo "Bash not found in container, falling back to /bin/sh..."
                echo "Attempting to connect with /bin/sh..."
                docker exec -it "$2" /bin/sh
            fi
            ;;
        *)
            echo "Error: Unknown container subcommand: '$1'"
            help_menu
            exit 1
            ;;
    esac
}

# --- Main Logic ---
if [ "$#" -eq 0 ]; then
    help_menu
    exit 1
fi

case "$1" in
    "status")
        check_docker_status
        ;;
    
    "image")
        handle_image_ops "${@:2}"
        ;;

    "container")
        handle_container_ops "${@:2}"
        ;;
    
    "help")
        help_menu
        ;;
    
    *)
        echo "Error: Unknown command: '$1'"
        help_menu
        exit 1
        ;;
esac
