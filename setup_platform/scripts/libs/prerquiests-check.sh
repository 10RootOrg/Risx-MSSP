#!/usr/bin/env bash
set -eo pipefail
# Verify if the required packages are installed

# Ensure shared helpers are available when the script is sourced directly
if ! declare -f print_green >/dev/null 2>&1; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=setup_platform/scripts/libs/main.sh
  source "$script_dir/main.sh"
fi

# Resolve the list of required packages while tolerating legacy formats
default_required_packages=("curl" "git" "podman")

if declare -p REQUIRED_PACKAGES >/dev/null 2>&1; then
  if [[ $(declare -p REQUIRED_PACKAGES) == "declare -a"* ]]; then
    REQUIRED_PACKAGES_LIST=("${REQUIRED_PACKAGES[@]}")
  else
    read -r -a REQUIRED_PACKAGES_LIST <<< "${REQUIRED_PACKAGES}"
  fi
else
  REQUIRED_PACKAGES_LIST=("${default_required_packages[@]}")
fi

# Clean up empty entries and replace deprecated dependencies
sanitized_packages=()
for package in "${REQUIRED_PACKAGES_LIST[@]}"; do
  package="${package//\"/}"
  package="${package//\'/}"
  if [[ -z "$package" ]]; then
    continue
  fi

  if [[ "$package" == -* ]]; then
    continue
  fi

  if [[ "$package" == "podman-docker" ]]; then
    print_yellow "Skipping deprecated dependency 'podman-docker'; Podman is used directly."
    continue
  fi

  sanitized_packages+=("$package")
done

if [[ ${#sanitized_packages[@]} -eq 0 ]]; then
  sanitized_packages=("${default_required_packages[@]}")
fi

REQUIRED_PACKAGES_LIST=("${sanitized_packages[@]}")

# Function to check if a package is installed
check_package_installed() {
  local package=$1
  if command -v "$package" &> /dev/null; then
    echo "$package is installed."
  else
    echo "$package is not installed."
    exit 1
  fi
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
check_required_packages "${REQUIRED_PACKAGES_LIST[@]}"

# Ensure a supported container runtime and compose interface are available
if declare -f initialize_container_runtime >/dev/null 2>&1; then
  initialize_container_runtime
  print_green "Using container runtime: ${CONTAINER_ENGINE}"
else
  if command -v podman >/dev/null 2>&1; then
    print_green "Using container runtime: podman"
  elif command -v docker >/dev/null 2>&1; then
    print_green "Using container runtime: docker"
  else
    print_red "No supported container runtime found (podman or docker)."
    exit 1
  fi
fi

if command -v podman >/dev/null 2>&1; then
  if podman compose version >/dev/null 2>&1 || podman compose --help >/dev/null 2>&1 || command -v podman-compose >/dev/null 2>&1; then
    print_green "Podman compose support is available."
  else
    print_red "Podman compose support is not available. Install podman-compose or enable podman compose."
    exit 1
  fi
else
  if command -v docker >/dev/null 2>&1; then
    if docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
      print_green "Docker compose compatibility is available."
    else
      print_red "Docker compose compatibility is not available. Install docker compose plugin or shim."
      exit 1
    fi
  fi
fi
