#!/bin/bash
set -eo pipefail

DOCKER_VERSION=${DOCKER_VERSION:-"27.3"}
# TODO: Deprecated, because now it's a part of the Docker CLI
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-"2.29.7"}

# HELP describe output and options
function show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --reinstall-docker Cleanup Docker and reinstall"
  echo "  --reinstall Cleanup all dependencies and reinstall"
  echo "  --help Show help"
  echo "######################"
  echo "Default: Install dependencies for the script."
}

function cleanup_docker() {
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
  # Cleanup Docker
  echo "Cleaning up Docker and deps..."
  docker rm "$NETWORK_NAME" || true
  sudo apt-get remove --purge -y \
    docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin || true
  sudo apt-get autoremove -y
  sudo rm -rf /usr/local/lib/docker/cli-plugins || true
  sudo rm -rf "$HOME/.docker" || true
  printf "\n###\nDocker cleanup finished.\n###\n"
}

function add_docker_as_sudoer() {
  local username="$USER"
  # Check if the current user is in the docker group
  if ! groups | grep -q "\bdocker\b"; then
    echo "Adding \"$username\" user to the docker group..."
    # Add the current user to the docker group
    sudo usermod -aG docker "$username"
    # Reload current session to apply the group changes
    newgrp docker
  else
    echo "Current user is already a member of the docker group."
  fi
}

# TODO: Deprecated, because now it's a part of the Docker CLI
function install_docker_compose_plugin() {
  echo "Installing docker compose plugin"

  # Legacy docker-compose command
  sudo curl --show-error --silent --location --output /usr/local/bin/docker-compose \
    https://github.com/docker/compose/releases/download/v"${DOCKER_COMPOSE_VERSION}"/docker-compose-$(uname -s)-$(uname -m)
  sudo chmod +x /usr/local/bin/docker-compose

  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  printf "Docker compose plugins installed successfully.\n"
}

function install_docker() {
  # Check if Docker is installed
  if [[ ! -x "$(command -v docker)" ]]; then
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh --version "$DOCKER_VERSION"
    rm -f /tmp/get-docker.sh
    add_docker_as_sudoer
  else
    echo "Docker is already installed."
  fi

  if [[ ! -x "$(command -v docker-compose)" || ! -x "$(command -v docker compose)" ]]; then
    install_docker_compose_plugin
  fi
}

function create_docker_network() {
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
  printf "Creating Docker network: %s\n" "$NETWORK_NAME"
  # Create Docker network
  if [[ $(docker network ls --format '{{.Name}}' | grep -w "$NETWORK_NAME") ]]; then
    echo "Network '$NETWORK_NAME' already exists. Skipping creation..."
  else
    sudo docker network create "$NETWORK_NAME"
    printf "Docker network '%s' created successfully.\n" "$NETWORK_NAME"
  fi
}

# Install dependencies which defined in the .env file
install_dependencies() {
  ENV_FILE=${1:-"../workdir/.env"}
  dependencies=$(grep -E "^REQUIRED_PACKAGES=" "$ENV_FILE" | cut -d'=' -f2)
  for dependency in "${dependencies[@]}"; do
    # skip if it's docker or docker-compose
    echo "Installing $dependency..."
    sudo apt-get install -y "$dependency"
  done
}

function default_func() {
  printf "Default: Install dependencies...\n"
  sudo apt-get update
  install_docker
  install_docker_compose_plugin
  create_docker_network
}

# Check flags arguments and call related function
if [[ "$#" -eq 0 ]]; then
  default_func
  exit 0
fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
  --reinstall-docker)
    cleanup_docker
    default_func
    ;;
  --reinstall)
    #cleanup
    cleanup_docker
    default_func
    ;;
  --help)
    show_help
    ;;
  *)
    printf "Unknown parameter passed: \"%s\"\n" "$1"
    show_help
    exit 1
    ;;
  esac
  shift
done
