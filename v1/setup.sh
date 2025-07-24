#!/bin/bash

set -e  # Exit on error

echo "Starting setup script. This assumes a Debian-based Linux (e.g., Ubuntu 22.04). Sudo may prompt for your password."

# Update and upgrade system packages
sudo apt update -y
sudo apt upgrade -y

# Install prerequisites (e.g., curl, git, etc., if not present)
sudo apt install -y curl git software-properties-common ripgrep

# Check if Docker is installed
docker_installed=false
if docker --version >/dev/null 2>&1; then
  docker_installed=true
fi

# Ask to install Docker if not installed
install_docker=false
if ! $docker_installed; then
  echo "Docker not detected. Do you want to install Docker? (y/n)"
  read -r answer < /dev/tty
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    install_docker=true
  fi
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

# Fix NVIDIA Container Toolkit keyring if applicable
echo "Checking and fixing NVIDIA Container Toolkit configuration..."
sudo rm -f /etc/apt/sources.list.d/nvidia-container*.list
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update -y
sudo apt install -y nvidia-container-toolkit || true  # Install if not already, ignore if no GPU

# Check if CUDA is installed
cuda_installed=false
if nvcc -V >/dev/null 2>&1 || nvidia-smi >/dev/null 2>&1; then
  cuda_installed=true
fi

# Ask to install CUDA if not installed
install_cuda=false
if ! $cuda_installed; then
  echo "CUDA not detected. Do you want to install CUDA 12.8? (y/n)"
  read -r answer < /dev/tty
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    install_cuda=true
  fi
fi

# Install CUDA if selected
if $install_cuda; then
  echo "Installing CUDA 12.8..."
  # Remove duplicate or old CUDA repos
  sudo rm -f /etc/apt/sources.list.d/cuda*.list /etc/apt/sources.list.d/archive_uri-https_developer_download_nvidia_com_compute_cuda_repos_ubuntu2204_x86_64_-*.list
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  rm cuda-keyring_1.1-1_all.deb
  sudo apt-get update -y
  sudo apt-get install -y cuda-toolkit-12-8
  # Add to .bashrc
  echo 'export PATH="/usr/local/cuda-12.8/bin${PATH:+:${PATH}}"' >> ~/.bashrc
  echo 'export LD_LIBRARY_PATH="/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"' >> ~/.bashrc
fi

# Install default packages without asking: FFmpeg
sudo apt install -y ffmpeg

# Install latest Neovim via PPA
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update -y
sudo apt install -y neovim

# Set up NvChad with custom config from repo
echo "Setting up Neovim with NvChad and custom config..."
rm -rf ~/.config/nvim
git clone https://github.com/infatoshi/kernelbasher.git ~/kernelbasher_temp
cp -r ~/kernelbasher_temp/v1/nvim ~/.config/nvim
rm -rf ~/kernelbasher_temp

# Check if uv is installed
uv_installed=false
if uv --version >/dev/null 2>&1; then
  uv_installed=true
fi

# Ask to install uv if not installed
install_uv=false
if ! $uv_installed; then
  echo "uv not detected. Do you want to install uv (Python package manager)? (y/n)"
  read -r answer < /dev/tty
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    install_uv=true
  fi
fi

# Install uv if selected
if $install_uv; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

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

# Reload Bash config by starting a new bash shell
bash

# Final instructions (this will run after exiting the new bash shell)
echo "Setup complete!"
if $install_cuda; then
  echo "CUDA installed. A reboot may be required for full functionality. Test with: nvcc --version"
fi
if $install_docker; then
  echo "Docker installed. Test with: docker --version"
fi
if $install_uv; then
  echo "uv installed. Test with: uv --version"
fi
echo "Test installations: ffmpeg -version, nvim --version"
echo "For Neovim: Run 'nvim' to let Lazy.nvim install plugins. Then run ':MasonInstallAll' if prompted."
echo "Customize ~/.bashrc for more env vars/aliases."
echo "If on a non-Debian distro (e.g., Fedora), modify apt commands to dnf/yum equivalents."
echo "If using Ubuntu 24.04, you may need to adjust the CUDA repo to ubuntu2404."

