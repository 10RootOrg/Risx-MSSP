#!/bin/bash
set -eo pipefail

CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-"podman"}

PKG_MANAGER=""
for candidate in dnf dnf-3 yum apt-get zypper; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PKG_MANAGER="$candidate"
    break
  fi
done

if [[ -z "$PKG_MANAGER" ]]; then
  echo "No supported package manager found (dnf, yum, apt-get, zypper)." >&2
  exit 1
fi

function pkg_install() {
  local packages=("$@")
  [[ ${#packages[@]} -eq 0 ]] && return
  case "$PKG_MANAGER" in
  apt-get)
    sudo apt-get update
    sudo apt-get install --yes "${packages[@]}"
    ;;
  dnf|dnf-3)
    sudo "$PKG_MANAGER" install -y "${packages[@]}"
    ;;
  yum)
    sudo yum install -y "${packages[@]}"
    ;;
  zypper)
    sudo zypper --non-interactive install --no-confirm "${packages[@]}"
    ;;
  esac
}

function pkg_remove() {
  local packages=("$@")
  [[ ${#packages[@]} -eq 0 ]] && return
  case "$PKG_MANAGER" in
  apt-get)
    sudo apt-get remove --purge -y "${packages[@]}" || true
    ;;
  dnf|dnf-3)
    sudo "$PKG_MANAGER" remove -y "${packages[@]}" || true
    ;;
  yum)
    sudo yum remove -y "${packages[@]}" || true
    ;;
  zypper)
    sudo zypper --non-interactive remove --clean-deps --no-confirm "${packages[@]}" || true
    ;;
  esac
}

function pkg_autoremove() {
  case "$PKG_MANAGER" in
  apt-get)
    sudo apt-get autoremove -y || true
    ;;
  dnf|dnf-3)
    sudo "$PKG_MANAGER" autoremove -y || true
    ;;
  yum)
    sudo yum autoremove -y || true
    ;;
  zypper)
    :
    ;;
  esac
}

# HELP describe output and options
function show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --reinstall-docker Cleanup container runtime packages and reinstall"
  echo "  --reinstall Cleanup all dependencies and reinstall"
  echo "  --help Show help"
  echo "######################"
  echo "Default: Install dependencies for the script."
}

function cleanup_docker() {
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
  # Cleanup container runtime packages
  echo "Cleaning up container runtime and dependencies..."
  if command -v docker >/dev/null 2>&1; then
    docker network rm "$NETWORK_NAME" 2>/dev/null || true
  elif command -v podman >/dev/null 2>&1; then
    podman network rm "$NETWORK_NAME" 2>/dev/null || true
  fi
  pkg_remove docker.io docker-doc docker-compose docker-compose-v2 containerd runc docker-ce docker-ce-cli \
    containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin podman podman-compose crun
  pkg_autoremove
  sudo rm -rf /usr/local/lib/docker/cli-plugins || true
  sudo rm -rf "$HOME/.docker" || true
  printf "\n###\nContainer runtime cleanup finished.\n###\n"
}

# shellcheck disable=SC2120
function cleanup_dependencies() {
  ENV_FILE=${1:-"../resources/default.env"}
  source "$ENV_FILE"
  # Cleanup dependencies
  echo "Cleaning up dependencies..."
  pkg_remove "${REQUIRED_PACKAGES[@]}"
  pkg_autoremove
  printf "\n###\nDependencies cleanup finished.\n###\n"
}

function install_container_runtime() {
  if [[ ! -x "$(command -v podman)" ]]; then
    echo "Podman is not installed. Installing Podman..."
    pkg_install podman podman-compose
  else
    echo "Podman is already installed."
  fi

  if [[ ! -x "$(command -v podman-compose)" ]]; then
    echo "Installing podman-compose for compose compatibility..."
    pkg_install podman-compose
  fi

  if [[ ! -x "$(command -v docker-compose)" ]]; then
    echo "Creating docker-compose shim backed by podman compose..."
    sudo tee /usr/local/bin/docker-compose >/dev/null <<'EOS'
#!/bin/bash
if podman compose --help >/dev/null 2>&1; then
  exec podman compose "$@"
elif command -v podman-compose >/dev/null 2>&1; then
  exec podman-compose "$@"
else
  echo "podman compose support is not available. Install podman-compose." >&2
  exit 1
fi
EOS
    sudo chmod +x /usr/local/bin/docker-compose
  fi

  if [[ ! -x "/usr/local/lib/docker/cli-plugins/docker-compose" ]]; then
    echo "Ensuring docker compose plugin wrapper exists..."
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
  fi
}

function create_docker_network() {
  local NETWORK_NAME=${NETWORK_NAME:-"main_network"}
  printf "Creating container network: %s\n" "$NETWORK_NAME"
  local cli_cmd="${CONTAINER_RUNTIME}"
  if command -v docker >/dev/null 2>&1; then
    cli_cmd="docker"
  fi
  # Create container network
  if [[ $($cli_cmd network ls --format '{{.Name}}' | grep -w "$NETWORK_NAME") ]]; then
    echo "Network '$NETWORK_NAME' already exists. Skipping creation..."
  else
    $cli_cmd network create "$NETWORK_NAME"
    printf "Container network '%s' created successfully.\n" "$NETWORK_NAME"
  fi
}

# Install dependencies which defined in the .env file
# shellcheck disable=SC2120
function install_dependencies() {
  local ENV_FILE=${1:-"../resources/default.env"}
  local install_dependencies="false"
  source "$ENV_FILE"
  # remove container runtime packages from the list (handled separately)
  local runtime_packages=(
    docker
    docker.io
    docker-ce
    docker-ce-cli
    docker-ce-rootless-extras
    docker-compose
    docker-compose-plugin
    docker-compose-v2
    docker-buildx-plugin
    podman
    podman-compose
    podman-docker
    containerd
    containerd.io
    runc
    crun
  )
  local filtered_dependencies=()
  for package in "${REQUIRED_PACKAGES[@]}"; do
    [[ -z "$package" ]] && continue
    if [[ "$package" == -* ]]; then
      continue
    fi
    local skip="false"
    for runtime_package in "${runtime_packages[@]}"; do
      if [[ "$package" == "$runtime_package" ]]; then
        skip="true"
        break
      fi
    done
    [[ "$skip" == "true" ]] && continue
    filtered_dependencies+=("$package")
  done
  # If at least one package is not installed, install all
  for package in "${filtered_dependencies[@]}"; do
    if [[ ! -x "$(command -v "$package")" ]]; then
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
  pkg_install "${filtered_dependencies[@]}"
}

function default_func() {
  printf "Default: Install dependencies...\n"
  install_dependencies
  install_container_runtime
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
