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
  echo ""
  echo "  container <subcommand>"
  echo "    container list        - List all containers (running and stopped)."
  echo "    container start <name/id> - Start a stopped container."
  echo "    container stop <name/id>  - Stop a running container."
  echo "    container delete <name/id>- Delete a container."
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
            echo "Pulling image '$2'..."
            docker pull "$2"
            ;;
        "search")
            if [ -z "$2" ]; then
                echo "Error: Please provide a search term."
                help_menu
                exit 1
            fi
            echo "Searching for images matching '$2'..."
            docker search "$2"
            ;;
        *)
            echo "Error: Unknown image subcommand: '$1'"
            help_menu
            exit 1
            ;;
    esac
}

# Function to handle container-related operations
handle_container_ops() {
    case "$1" in
        "list")
            echo "Listing all Docker containers..."
            docker ps -a
            ;;
        "start"|"stop"|"delete")
            if [ -z "$2" ]; then
                echo "Error: Please provide a container name or ID."
                help_menu
                exit 1
            fi
            echo "Executing docker $1 on container '$2'..."
            docker "$1" "$2"
            ;;
        "connect")
            if [ -z "$2" ]; then
                echo "Error: Please provide a container name or ID."
                help_menu
                exit 1
            fi
            echo "Connecting to docker container $1 on container '$2'..."
            docker exec -it $2 /bin/bash
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
        handle_image_ops "$2" "$3"
        ;;

    "container")
        handle_container_ops "$2" "$3"
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

