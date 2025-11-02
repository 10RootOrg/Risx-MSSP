#!/bin/bash
set -eo pipefail

DOCKER_VERSION=${DOCKER_VERSION:-"27.3"}
# TODO: Deprecated, because now it's a part of the Docker CLI
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-"2.29.7"}

PKG_MANAGER=""

function detect_package_manager() {
  if [[ -n "$PKG_MANAGER" ]]; then
    return
  fi

  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
  elif command -v dnf5 &>/dev/null; then
    PKG_MANAGER="dnf5"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
  else
    echo "Unsupported package manager. Please install dependencies manually." >&2
    exit 1
  fi
}

function pkg_update() {
  detect_package_manager
  case "$PKG_MANAGER" in
  apt)
    sudo apt-get update
    ;;
  dnf5)
    sudo dnf5 makecache --refresh
    ;;
  dnf)
    sudo dnf makecache --refresh
    ;;
  yum)
    sudo yum makecache
    ;;
  esac
}

function pkg_install() {
  detect_package_manager
  local packages=("$@")
  local filtered=()
  for pkg in "${packages[@]}"; do
    if [[ -n "$pkg" ]]; then
      filtered+=("$pkg")
    fi
  done
  packages=("${filtered[@]}")
  if ((${#packages[@]} == 0)); then
    return
  fi
  case "$PKG_MANAGER" in
  apt)
    sudo apt-get install --yes "${packages[@]}"
    ;;
  dnf5)
    sudo dnf5 install -y "${packages[@]}"
    ;;
  dnf)
    sudo dnf install -y "${packages[@]}"
    ;;
  yum)
    sudo yum install -y "${packages[@]}"
    ;;
  esac
}

function pkg_remove() {
  detect_package_manager
  local packages=("$@")
  local filtered=()
  for pkg in "${packages[@]}"; do
    if [[ -n "$pkg" ]]; then
      filtered+=("$pkg")
    fi
  done
  packages=("${filtered[@]}")
  if ((${#packages[@]} == 0)); then
    return
  fi
  case "$PKG_MANAGER" in
  apt)
    sudo apt-get remove --purge -y "${packages[@]}" || true
    ;;
  dnf5)
    sudo dnf5 remove -y "${packages[@]}" || true
    ;;
  dnf)
    sudo dnf remove -y "${packages[@]}" || true
    ;;
  yum)
    sudo yum remove -y "${packages[@]}" || true
    ;;
  esac
}

function pkg_autoremove() {
  detect_package_manager
  case "$PKG_MANAGER" in
  apt)
    sudo apt-get autoremove -y
    ;;
  dnf5)
    sudo dnf5 autoremove -y
    ;;
  dnf)
    sudo dnf autoremove -y
    ;;
  yum)
    if yum help autoremove >/dev/null 2>&1; then
      sudo yum autoremove -y
    else
      echo "Skipping yum autoremove (command not available)"
    fi
    ;;
  esac
}

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
  pkg_remove \
    docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin || true
  pkg_autoremove || true
  sudo rm -rf /usr/local/lib/docker/cli-plugins || true
  sudo rm -rf "$HOME/.docker" || true
  printf "\n###\nDocker cleanup finished.\n###\n"
}

# shellcheck disable=SC2120
function cleanup_dependencies() {
  ENV_FILE=${1:-"../resources/default.env"}
  source "$ENV_FILE"
  # Cleanup dependencies
  echo "Cleaning up dependencies..."
  pkg_remove "${REQUIRED_PACKAGES[@]}"
  pkg_autoremove || true
  printf "\n###\nDependencies cleanup finished.\n###\n"
}

# shellcheck disable=SC2120
function add_docker_as_sudoer() {
  ENV_FILE=${1:-"../resources/default.env"}
  source "$ENV_FILE"
  local username=${username:-$USER}
  # Check if the current user is in the docker group
  if ! groups | grep -q "\bdocker\b"; then
    echo "Adding \"$username\" user to the docker group..."
    # Add the current user to the docker group
    sudo usermod -aG docker "$username"
    printf "User '%s' added to the docker group successfully.\n" "$username"
    printf "Please logout and login again to apply the changes.\n"
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

  if [[ ! -x "$(command -v docker-compose)" || ! -x "$(command -v docker compose)" ]]; then
    printf "Docker compose plugins installation failed.\n"
    exit 1
  fi

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
    echo "Docker Compose is not installed. Installing Docker Compose..."
    install_docker_compose_plugin
  else
    echo "Docker Compose is already installed."
  fi
}

function create_docker_network() {
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
  printf "Creating Docker network: %s\n" "$NETWORK_NAME"
  # Create Docker network
  if [[ $(docker network ls --format '{{.Name}}' | grep -w "$NETWORK_NAME") ]]; then
    echo "Network '$NETWORK_NAME' already exists. Skipping creation..."
  else
    docker network create "$NETWORK_NAME"
    printf "Docker network '%s' created successfully.\n" "$NETWORK_NAME"
  fi
}

# Install dependencies which defined in the .env file
# shellcheck disable=SC2120
function install_dependencies() {
  local ENV_FILE=${1:-"../resources/default.env"}
  local install_dependencies="false"
  source "$ENV_FILE"
  # remove docker and docker-compose from the list
  dependencies=("${REQUIRED_PACKAGES[@]/docker-compose/}")
  dependencies=("${dependencies[@]/docker/}")
  # If at least one package is not installed, install all
  for package in "${dependencies[@]}"; do
      if [[ -n $package ]] && [[ ! -x "$(command -v "$package")" ]]; then
      printf "Installing %s...\n" "$package"
      install_dependencies="true"
      break
    fi
  done
  if [[ "$install_dependencies" == "false" ]]; then
    printf "All dependencies are already installed.\n"
    return
  fi
  printf "Installing dependencies...\n"
  pkg_update
  pkg_install "${dependencies[@]}"
}

function default_func() {
  printf "Default: Install dependencies...\n"
  install_dependencies
  install_docker
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
    cleanup_dependencies
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
