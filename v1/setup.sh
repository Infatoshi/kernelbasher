#!/bin/bash

set -e  # Exit on error

echo "Starting setup script. This assumes a Debian-based Linux (e.g., Ubuntu 22.04). Sudo may prompt for your password."

# Update and upgrade system packages
sudo apt update -y
sudo apt upgrade -y

# Install dialog for checklists and other prerequisites
sudo apt install -y dialog curl git software-properties-common

# Check if CUDA is installed
cuda_installed=false
if command -v nvcc >/dev/null 2>&1; then
  cuda_installed=true
fi

# Build checklist items
items=()
if ! $cuda_installed; then
  items+=("CUDA" "Install CUDA 12.8" OFF)
fi
items+=("Docker" "Install Docker" ON)

# Show checklist
selections=$(dialog --clear --title "Setup Options" --checklist "Select what to install:" 15 50 $((${#items[@]} / 3)) "${items[@]}" 2>&1 >/dev/tty)

clear

# Process selections
install_cuda=false
install_docker=false
for selection in $selections; do
  case $selection in
    CUDA) install_cuda=true ;;
    Docker) install_docker=true ;;
  esac
done

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

# Install Docker if selected
if $install_docker; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm get-docker.sh
  # Start and enable Docker service
  sudo systemctl start docker
  sudo systemctl enable docker
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
echo "Test installations: docker --version (if installed), uv --version, ffmpeg -version, nvim --version"
echo "Customize ~/.bashrc for more env vars/aliases and ~/.config/nvim/init.vim for Neovim config."
echo "If on a non-Debian distro (e.g., Fedora), modify apt commands to dnf/yum equivalents."
echo "If using Ubuntu 24.04, you may need to adjust the CUDA repo to ubuntu2404."

