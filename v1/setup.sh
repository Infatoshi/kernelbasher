#!/bin/bash

set -e  # Exit on error

echo "Starting setup script. This assumes a Debian-based Linux (e.g., Ubuntu). Sudo may prompt for your password."

# Update and upgrade system packages
sudo apt update -y
sudo apt upgrade -y

# Install prerequisites (e.g., curl, git, etc., if not present)
sudo apt install -y curl git software-properties-common

# Install Zsh
sudo apt install -y zsh

# Install Oh My Zsh in unattended mode
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Docker via official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Install FFmpeg
sudo apt install -y ffmpeg

# Install latest Neovim via PPA
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update -y
sudo apt install -y neovim

# Set up a basic custom Neovim config (example: line numbers, syntax highlighting, and a plugin manager placeholder)
mkdir -p ~/.config/nvim
cat << EOF > ~/.config/nvim/init.vim
" Basic settings
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
syntax on
filetype plugin indent on

" Example: Add plugins via vim-plug (uncomment and run :PlugInstall after setup)
" call plug#begin()
" Plug 'junegunn/vim-easy-align'  " Example plugin
" call plug#end()

" Add your custom mappings, colorschemes, etc. here
EOF

# Install vim-plug for Neovim plugins (optional; customize as needed)
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add example env vars and aliases to .zshrc (customize these)
echo '# Custom env vars and aliases' >> ~/.zshrc
echo 'export PATH="$HOME/.cargo/bin:$PATH"  # For uv and other Rust tools' >> ~/.zshrc
echo 'export EDITOR=nvim  # Set Neovim as default editor' >> ~/.zshrc
echo 'alias ll="ls -la"' >> ~/.zshrc
echo 'alias dockerps="docker ps -a"' >> ~/.zshrc
echo 'alias update="sudo apt update && sudo apt upgrade -y"' >> ~/.zshrc

# Reload Zsh config
source ~/.zshrc

# Final instructions
echo "Setup complete!"
echo "To switch to Zsh as your default shell, run: chsh -s \$(which zsh)"
echo "Then log out and log back in."
echo "If chsh prompts for a password, enter it."
echo "Test installations: zsh --version, docker --version, uv --version, ffmpeg -version, nvim --version"
echo "Customize ~/.zshrc for more env vars/aliases and ~/.config/nvim/init.vim for Neovim config."
echo "If on a non-Debian distro (e.g., Fedora), modify apt commands to dnf/yum equivalents."
