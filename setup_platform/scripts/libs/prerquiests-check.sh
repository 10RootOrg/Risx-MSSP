#!/usr/bin/env bash
set -eo pipefail
# Verify if the required packages are installed

# List of required packages
REQUIRED_PACKAGES=${REQUIRED_PACKAGES:-("curl" "git" "docker" "docker-compose")}

# Function to check if a package is installed
check_package_installed() {
  local package=$1
  case "$package" in
    docker-compose)
      if command -v docker-compose &>/dev/null; then
        echo "docker-compose is installed."
        return
      fi

      if command -v docker &>/dev/null && docker compose version &>/dev/null; then
        echo "docker compose plugin is available."
        return
      fi

      echo "Docker Compose (docker compose) is not installed."
      exit 1
      ;;
    *)
      if command -v "$package" &> /dev/null; then
        echo "$package is installed."
      else
        echo "$package is not installed."
        exit 1
      fi
      ;;
  esac
}

# Function to check a list of required packages
check_required_packages() {
  local packages=("$@")
  printf "Checking required packages...\n"
  for package in "${packages[@]}"; do
    check_package_installed "$package"
  done
  print_green "All required packages are installed."
}

# Check if the required packages are installed
check_required_packages "${REQUIRED_PACKAGES[@]}"
