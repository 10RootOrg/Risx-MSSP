#!/bin/bash

. ./_library.sh

function install_docker(){
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        
        # Install Docker using the appropriate package manager
        # For Ubuntu/Debian:
        nx_script.shsudo apt-get update
        sudo apt-get install -y docker.io

        # For other distributions, please consult Docker's installation guide.
    else
        echo "Docker is already installed."
    fi
}


function install_docker_compose_plugin() {
    echo "Installing docker compose plugin"
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"

    # Verification code
    if [ -x "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
        echo "Docker Compose plugin installed successfully."
    else
        echo "Error: Docker Compose plugin installation failed."
    fi
}    

function add_docker_as_sudoer(){
    # Check if the current user is in the docker group
    if ! groups | grep -q "\bdocker\b"; then
        echo "Adding current user to the docker group..."
        
        # Add the current user to the docker group
        sudo usermod -aG docker $USER
        
        echo "Please log out and log back in for the changes to take effect."
    else
        echo "Current user is already a member of the docker group."
    fi
}

function create_docker_network(){
    local NETWORK_NAME="main_network"
    # Create Docker network
    sudo docker network create $NETWORK_NAME
    if docker network ls | grep -q $NETWORK_NAME; then
        echo "Network '$NETWORK_NAME' created successfully."
    else
        echo "Failed to create network '$NETWORK_NAME'."
    fi
}

function make_scripts_executable() {
    chmod ugo+x *.sh
}

make_scripts_executable
install_docker
install_docker_compose_plugin
create_docker_network


