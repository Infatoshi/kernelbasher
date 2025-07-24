#!/bin/bash

set -e  # Exit on error

echo "Starting setup script. This assumes a Debian-based Linux (e.g., Ubuntu 22.04). Sudo may prompt for your password."

# Update and upgrade system packages
sudo apt update -y
sudo apt upgrade -y

# Install prerequisites (e.g., curl, git, etc., if not present)
sudo apt install -y curl git software-properties-common

# Install Docker immediately
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh
# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check if CUDA is installed
cuda_installed=false
if nvcc -V >/dev/null 2>&1 || nvidia-smi >/dev/null 2>&1; then
  cuda_installed=true
fi

# Ask to install CUDA if not installed
install_cuda=false
if ! $cuda_installed; then
  echo "CUDA not detected. Do you want to install CUDA 12.8? (y/n)"
  read -r answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    install_cuda=true
  fi
fi

# Install CUDA if selected
if $install_cuda; then
  echo "Installing CUDA 12.8..."
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  rm cuda-keyring_1.1-1_all.deb
  sudo apt-get update -y
  sudo apt-get install -y cuda-toolkit-12-8
  # Add to .bashrc
  echo 'export PATH="/usr/local/cuda-12.8/bin${PATH:+:${PATH}}"' >> ~/.bashrc
  echo 'export LD_LIBRARY_PATH="/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"' >> ~/.bashrc
fi

# Install default packages without asking: FFmpeg, Neovim, uv
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

# Add example env vars and aliases to .bashrc (customize these)
echo '# Custom env vars and aliases' >> ~/.bashrc
echo 'export PATH="$HOME/.cargo/bin:$PATH"  # For uv and other Rust tools' >> ~/.bashrc
echo 'export EDITOR=nvim  # Set Neovim as default editor' >> ~/.bashrc
echo 'alias ll="ls -la"' >> ~/.bashrc
echo 'alias dockerps="docker ps -a"' >> ~/.bashrc
echo 'alias update="sudo apt update && sudo apt upgrade -y"' >> ~/.bashrc
echo 'alias sv="source .venv/bin/activate"' >> ~/.bashrc
echo 'alias uvs="uv venv && source .venv/bin/activate && uv pip install -r requirements.txt"' >> ~/.bashrc
echo 'alias uvv="uv venv"' >> ~/.bashrc
echo 'alias uvi="uv pip install"' >> ~/.bashrc
echo 'alias uvir="uv pip install -r requirements.txt"' >> ~/.bashrc
echo 'alias rf="rm -rf"' >> ~/.bashrc

# Reload Bash config
source ~/.bashrc

# Final instructions
echo "Setup complete!"
if $install_cuda; then
  echo "CUDA installed. A reboot may be required for full functionality. Test with: nvcc --version"
fi
echo "Test installations: docker --version, uv --version, ffmpeg -version, nvim --version"
echo "Customize ~/.bashrc for more env vars/aliases and ~/.config/nvim/init.vim for Neovim config."
echo "If on a non-Debian distro (e.g., Fedora), modify apt commands to dnf/yum equivalents."
echo "If using Ubuntu 24.04, you may need to adjust the CUDA repo to ubuntu2404.
