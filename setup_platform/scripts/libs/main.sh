#!/usr/bin/env bash
# --- The minimal set of functions which uses almost everywhere in the scripts

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

# Function to define env variables
define_env() {
  local env_file=${1:-".env"}
  local default_env_file="${resources_dir}/default.env"

  if [ -f "$env_file" ]; then
    source "$env_file"
  else
    print_red "An env file $env_file is not found, applying the $default_env_file env file"
    source "$default_env_file"
  fi
}

# Function to define path's
define_paths() {
  # username should be defined in the .env file
  # If the username is not defined, then ask user to enter the username
  if [ -z "$username" ]; then
    current_user=$(whoami)
    read -p "Enter username for home directory setup (default: $current_user): " username
    username=${username:-$current_user}
  fi

  home_path="/home/$username/setup_platform"
  resources_dir="$home_path/resources"
  scripts_dir="$home_path/scripts"
  workdir="$home_path/workdir"
}

