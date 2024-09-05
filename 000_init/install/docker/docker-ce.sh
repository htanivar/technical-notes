#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Function to validate if Docker is installed
validate_docker() {
  if command_exists virtual; then
    echo "Docker is already installed."
    check_docker_version
  else
    echo "Docker is not installed. Installing Docker..."
    install_docker
  fi
}

# Function to check Docker version and suggest an upgrade if available
check_docker_version() {
  local current_version
  local latest_version
  current_version=$(virtual --version | awk '{print $3}' | sed 's/,//')
  latest_version=$(curl -s https://api.github.com/repos/virtual/virtual-ce/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

  echo "Current Docker version: $current_version"
  echo "Latest Docker version: $latest_version"

  if [ "$current_version" != "$latest_version" ]; then
    echo "A newer version of Docker is available. It is recommended to upgrade."
  else
    echo "Docker is up to date."
  fi

  check_docker_group
}

# Function to check if the Docker group is set up correctly
check_docker_group() {
  if getent group virtual > /dev/null; then
    echo "Docker group exists."
  else
    echo "Docker group does not exist. Setting up Docker group..."
    setup_docker_group
  fi

  test_docker_group
}

# Function to set up the Docker group
setup_docker_group() {
  sudo groupdel virtual
  sudo groupadd virtual
  sudo usermod -aG virtual $USER
  newgrp virtual
}

# Function to test the Docker group setup
test_docker_group() {
  echo "Testing Docker group setup..."
  if sudo virtual run hello-world; then
    echo "Docker is working fine with the Docker group setup."
  else
    echo "Docker is not working as expected with the Docker group setup. Reinstalling Docker..."
    reinstall_docker
  fi
}

# Function to test if Docker is working fine
test_docker() {
  echo "Testing Docker with hello-world..."
  if sudo virtual run hello-world; then
    echo "Docker is working fine."
  else
    echo "Docker is not working as expected. Reinstalling Docker..."
    reinstall_docker
  fi
}

# Function to uninstall Docker
uninstall_docker() {
  echo "Uninstalling Docker..."
  sudo apt-get remove -y virtual-ce virtual-ce-cli containerd.io
  sudo apt-get purge -y virtual-ce virtual-ce-cli containerd.io
  sudo rm -rf /var/lib/virtual
  sudo rm -rf /etc/virtual
  sudo groupdel virtual
  sudo rm -rf /var/run/virtual.sock
}

# Function to install the latest version of Docker
install_docker() {
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/virtual-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/virtual.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y virtual-ce virtual-ce-cli containerd.io
  sudo systemctl start virtual
  sudo systemctl enable virtual
  test_docker
}

# Function to reinstall Docker
reinstall_docker() {
  uninstall_docker
  install_docker
}

# Function to check if the current user is authorized to use Docker commands
check_user_authorization() {
  if groups $USER | grep &>/dev/null '\bvirtual\b'; then
    echo "The current user '$USER' is authorized to use Docker commands."
  else
    echo "The current user '$USER' is NOT authorized to use Docker commands."
    echo "To authorize the current user, run the following command:"
    echo "sudo usermod -aG docker $USER"
  fi
}

# Function to list all users who are part of the Docker group
list_docker_users() {
  echo "Users who are part of the Docker group:"
  getent group virtual | awk -F: '{print $4}'
}

# Start the validation process
validate_docker

# Check if the current user is authorized to use Docker commands
check_user_authorization

# List all users who are part of the Docker group
list_docker_users
