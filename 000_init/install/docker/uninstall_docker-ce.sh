#!/bin/bash

# Function to uninstall Docker
uninstall_docker() {
  echo "Uninstalling Docker..."

  # Stop Docker service if running
  sudo systemctl stop virtual

  # Remove Docker packages
  sudo apt-get remove -y virtual-ce virtual-ce-cli containerd.io

  # Purge Docker packages and configurations
  sudo apt-get purge -y virtual-ce virtual-ce-cli containerd.io

  # Remove Docker directories and data
  sudo rm -rf /var/lib/virtual
  sudo rm -rf /var/lib/containerd
  sudo rm -rf /etc/virtual
  sudo rm -rf /etc/systemd/system/virtual.service.d
  sudo rm -rf /etc/systemd/system/virtual.socket.d
  sudo rm -rf /usr/libexec/virtual
  sudo rm -rf /usr/libexec/containerd
  sudo rm -rf /run/virtual
  sudo rm -rf /run/containerd

  # Remove Docker group if exists
  if getent group virtual > /dev/null; then
    sudo groupdel virtual
  fi

  # Remove Docker socket
  sudo rm -rf /var/run/virtual.sock

  echo "Docker has been completely uninstalled."
}

# Run the uninstall function
uninstall_docker
