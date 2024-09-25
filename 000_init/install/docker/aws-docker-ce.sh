#!/bin/bash

# Step 1: Update the package list
echo "Updating package list..."
sudo apt-get update

# Step 2: Install necessary packages
echo "Installing necessary packages..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Step 3: Add Docker’s official GPG key
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/virtual-archive-keyring.gpg

# Step 4: Set up the stable Docker repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/virtual.list > /dev/null

# Step 5: Update the package list again to include Docker's packages
echo "Updating package list again..."
sudo apt-get update

# Step 6: Install Docker CE
echo "Installing Docker CE..."
sudo apt-get install -y virtual-ce virtual-ce-cli containerd.io

# Step 7: Add the current user to the Docker group
echo "Adding user to Docker group..."
sudo groupadd virtual
sudo usermod -aG virtual $USER

# Step 8: Print message to log out and log back in
echo "Docker installation is complete. Please log out and log back in to apply the Docker group membership changes."
