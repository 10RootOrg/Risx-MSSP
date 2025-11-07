#!/usr/bin/env bash
# --- The minimal set of functions which uses almost everywhere in the scripts

set -eo pipefail

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print green message
print_green() {
  local message=$1
  printf "${GREEN}%s${NC}\n" "$message"
}

print_green_v2() {
  local message=$1
  local action=$2
  printf "${GREEN}✔${NC} %s ${GREEN}%s${NC}\n" "$message" "$action"
}

# Function to print red message
print_red() {
  local message=$1
  printf "${RED}%s${NC}\n" "$message"
}

# Function to print yellow message
print_yellow() {
  local message=$1
  printf "${YELLOW}%s${NC}\n" "$message"
}

print_with_border() {
  local input_string="$1"
  local length=${#input_string}
  local border="===================== "
  # Calculate the length of the border
  local border_length=$(((80 - length - ${#border}) / 2))
  # Print the top border
  printf "%s" "$border"
  for ((i = 0; i < border_length; i++)); do
    printf "="
  done
  printf " %s " "$input_string"
  for ((i = 0; i < border_length; i++)); do
    printf "="
  done
  printf "%s\n" "$border"
}

### Business functions ###
# Function to define env variables
define_env() {
  local env_file=${1:-"../workdir/.env"}

  if [ -f "$env_file" ]; then
    source "$env_file"
    printf "%s is loaded\n" "$env_file"
  else
    print_red "Can't find the .env:\"$env_file\" file. Continue without an .env file."
    print_yellow "Try load from the default.env file"
    define_env ../resources/default.env
  fi
}

# Function to define path's
define_paths() {
  local home_path=${1}
  # username should be defined in the .env file
  # If the username is not defined, then ask user to enter the username
  if [ -z "$username" ]; then
    current_user=$(whoami)
    read -p "Enter username for home directory setup (default: $current_user): " username
    username=${username:-$current_user}
  fi
  if [ -z "$home_path" ]; then
    home_path="/home/$username/setup_platform"
  fi

  printf "Home path %s \n" "$home_path"
  resources_dir="$home_path/resources"
  scripts_dir="$home_path/scripts"
  workdir="$home_path/workdir"
}

# Ensure the default container network exists for the detected engine
ensure_container_network() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    return
  fi

  local network_name="${NETWORK_NAME:-main_network}"
  if [ -z "$network_name" ]; then
    return
  fi

  if [ -n "$CONTAINER_NETWORK_READY" ] && [ "$CONTAINER_NETWORK_READY" = "$network_name" ]; then
    return
  fi

  if [ "$CONTAINER_ENGINE" = "podman" ]; then
    if "$CONTAINER_ENGINE" network exists "$network_name" >/dev/null 2>&1; then
      CONTAINER_NETWORK_READY="$network_name"
      return
    fi
  else
    if "$CONTAINER_ENGINE" network inspect "$network_name" >/dev/null 2>&1; then
      CONTAINER_NETWORK_READY="$network_name"
      return
    fi
  fi

  print_yellow "Creating container network '$network_name'"
  if "$CONTAINER_ENGINE" network create "$network_name" >/dev/null 2>&1; then
    CONTAINER_NETWORK_READY="$network_name"
    print_green "Container network '$network_name' is ready."
  else
    print_red "Failed to create container network '$network_name'."
    exit 1
  fi
}

# Function to detect and initialize the container runtime commands
initialize_container_runtime() {
  local preferred_engine=${CONTAINER_ENGINE:-}
  local engine=""

  if [ -n "$preferred_engine" ] && command -v "$preferred_engine" >/dev/null 2>&1; then
    engine="$preferred_engine"
  else
    for candidate in podman docker; do
      if command -v "$candidate" >/dev/null 2>&1; then
        engine="$candidate"
        break
      fi
    done
  fi

  if [ -z "$engine" ]; then
    print_red "No supported container runtime found (podman or docker)."
    exit 1
  fi

  CONTAINER_ENGINE="$engine"

  if [ "$CONTAINER_ENGINE" = "podman" ]; then
    if command -v podman-compose >/dev/null 2>&1; then
      CONTAINER_COMPOSE=(podman-compose)
    else
      CONTAINER_COMPOSE=("$CONTAINER_ENGINE" compose)
    fi
  else
    CONTAINER_COMPOSE=("$CONTAINER_ENGINE" compose)
  fi

  ensure_container_network
}

container_compose() {
  if [ ${#CONTAINER_COMPOSE[@]} -eq 0 ]; then
    initialize_container_runtime
  fi

  case "$1" in
  up|start|create|run)
    ensure_container_network
    ;;
  esac

  "${CONTAINER_COMPOSE[@]}" "$@"
}

container_exec() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    initialize_container_runtime
  fi

  "$CONTAINER_ENGINE" exec "$@"
}

container_run() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    initialize_container_runtime
  fi

  "$CONTAINER_ENGINE" run "$@"
}

container_restart() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    initialize_container_runtime
  fi

  "$CONTAINER_ENGINE" restart "$@"
}

