#!/bin/bash
set -eo pipefail

DOCKER_VERSION=${DOCKER_COMPOSE_VERSION:-"27.3"}
# TODO: Deprecated, because now it's a part of the Docker CLI
#DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-"2.26.0"}

function install_docker(){
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh ./get-docker.sh --version "$DOCKER_VERSION"
        rm -f get-docker.sh
    else
        echo "Docker is already installed."
    fi
}

function cleanup_docker(){
    # Cleanup Docker
    echo "Cleaning up Docker..."
    sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin
}

# TODO: Deprecated, because now it's a part of the Docker CLI
function install_docker_compose_plugin() {
  local DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    echo "Installing docker compose plugin"
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    download_external_file https://github.com/docker/compose/releases/download/v"${DOCKER_COMPOSE_VERSION}"/docker-compose-linux-x86_64 \
      "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"

    # Verification code
    if [ -x "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
        echo "Docker Compose plugin installed successfully."
    else
        echo "Error: Docker Compose plugin installation failed."
    fi
}    

function add_docker_as_sudoer(){
  local username=${1:-$USER}
    # Check if the current user is in the docker group
    if ! groups | grep -q "\bdocker\b"; then
        echo "Adding current user to the docker group..."
        # Add the current user to the docker group
        sudo usermod -aG docker "$username"
        echo "Please log out and log back in for the changes to take effect."
    else
        echo "Current user is already a member of the docker group."
    fi
}

function create_docker_network(){
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
    # Create Docker network
    if docker network ls | grep -q "$NETWORK_NAME"; then
        echo "Network '$NETWORK_NAME' already exists."
    else
        sudo docker network create "$NETWORK_NAME"
    fi
}

# TODO: Deprecated, because now it's a part of the Docker CLI
# install_docker_compose_plugin
install_docker
create_docker_network
