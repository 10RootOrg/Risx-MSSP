#!/usr/bin/env bash
set -eo pipefail

source libs/main.sh
source libs/host-dirs.sh
define_env
define_paths
initialize_container_runtime

# HELP describe output and options
function show_help() {
  print_with_border "Help for cleanup.sh"
  printf "Usage: %s [OPTIONS]\n" "$0"
  printf "Options:\n"
  printf "  --force Cleanup all docker services and networks on the host\n"
  printf "  --app <app_name>\tCleanup specific app\n"
  printf "  --help\t\tShow help\n"
  printf "######################\n"
  print_green "Default: Cleanup all services defined in the .env file"
}

# Helper to run compose down for an application
app_down() {
  local app_name=$1
  # Find all compose files and stop the services
  while IFS= read -r -d '' file; do
    printf "Stopping the %s app...\n" "$app_name"
    cd "$(dirname "$file")" || exit
    container_compose down --volumes --remove-orphans --timeout 1
    cd - || exit
  done < <(find "${workdir}/${app_name}" -maxdepth 2 -name docker-compose.yaml -print0 -o -name docker-compose.yml -print0 -o -name compose.yaml -print0)
}

cleanup_all_force() {
  local engine="$CONTAINER_ENGINE"
  if [ -z "$engine" ]; then
    initialize_container_runtime
    engine="$CONTAINER_ENGINE"
  fi
  print_yellow "Cleaning up FORCE all container instances and related files ..."
  local containers
  containers=$("$engine" container ls -aq)
  if [ -n "$containers" ]; then
    "$engine" container stop $containers || print_yellow "No containers to stop"
    "$engine" container rm $containers || print_yellow "No containers to remove"
  else
    print_yellow "No containers to stop"
  fi

  local networks
  networks=$("$engine" network ls -q)
  if [ -n "$networks" ]; then
    "$engine" network rm $networks || true
  fi

  local volumes
  volumes=$("$engine" volume ls -q)
  if [ -n "$volumes" ]; then
    "$engine" volume rm $volumes || true
  fi

  printf "Cleaning up related workdir...\n"
  sudo rm -rf "${workdir}"/*
  sudo rm -rf "${workdir}"/.env
  print_green_v2 "Cleanup force" "finished"
}

# function to delete app dirs and files
delete_app_dirs() {
  local app_name=$1
  if [ -z "$app_name" ]; then
    printf "App name is not provided\n"
    print_red "Usage: %s --app <app_name>\n" "$0"
    exit 1
  fi
  printf "Deleting the %s app files ...\n" "$app_name"
  sudo rm -rf "${workdir}/${app_name}"
}

# Default function
default_cleanup() {
  printf "Default: Cleaning up the container services...\n"
  # Iterate over APPS_TO_INSTALL and delete the app dirs
  for app in "${APPS_TO_INSTALL[@]}"; do
    app_down "$app"
    delete_app_dirs "$app"
  done

  delete_app_dirs ".env"
  app_down "nginx"
  delete_app_dirs "nginx"
  cleanup_common_dirs

  # If defined NETWORK_NAME , then remove DEFAULT network
  if [ -n "$NETWORK_NAME" ]; then
    printf "Removing the %s network\n" "$NETWORK_NAME"
    if [ "$CONTAINER_ENGINE" = "docker" ]; then
      # Fix an issue with removing the default Docker network.
      print_yellow "Restarting the docker service."
      sudo systemctl restart docker
    fi
    "$CONTAINER_ENGINE" network rm "$NETWORK_NAME" --force || true
  fi
  "$CONTAINER_ENGINE" network prune --force

  print_green_v2 "Cleanup" "finished"
}

# Check flags arguments and call related function
if [[ "$#" -eq 0 ]]; then
  default_cleanup
  exit 0
fi

# Check flags arguments and call related function
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --help)
    show_help
    exit 0
    ;;
  --app)
    app_name=$2
    app_down "$app_name"
    delete_app_dirs "$app_name"
    shift 2
    ;;
  --force)
    cleanup_all_force
    shift
    ;;
  *)
    printf "Unknown argument: %s\n" "$1"
    show_help
    exit 0
    ;;
  esac
done
