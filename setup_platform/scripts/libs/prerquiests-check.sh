#!/usr/bin/env bash
# Verify if the required packages are installed

set -eo pipefail
# List of required packages
REQUIRED_PACKAGES=${REQUIRED_PACKAGES:-("curl" "git" "docker" "docker-compose")}


# Function to check if a package is installed
check_package_installed() {
  local package=$1
  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q '^install ok installed$'; then
    echo "$package is installed."
  else
    echo "$package is not installed."
    exit 1
  fi
}

# Function to check a list of required packages
check_required_packages() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    check_package_installed "$package"
  done
}

# Check if the required packages are installed
check_required_packages "${REQUIRED_PACKAGES[@]}"
