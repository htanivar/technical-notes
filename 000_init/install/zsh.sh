#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Zsh installation and setup..."

# Update system
echo "Updating package list..."
sudo apt update -y

# Install Zsh
echo "Installing Zsh..."
sudo apt install -y zsh

# Change default shell to Zsh
echo "Changing default shell to Zsh..."
chsh -s $(which zsh)

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended

# Install Powerlevel10k theme
echo "Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install plugins: autosuggestions & syntax highlighting
echo "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure .zshrc
echo "Configuring .zshrc..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# Enable plugins
sed -i 's/plugins=(git)/plugins=(git golang node npm zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# Apply changes
echo "Applying changes..."
source ~/.zshrc

echo "Zsh installation and setup completed successfully!"
echo "Restart your terminal or run 'zsh' to start using it."
