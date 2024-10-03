#!/usr/bin/env bash
set -eo pipefail

source libs/main.sh
define_paths
define_env

# HELP describe output and options
function show_help() {
  printf "######################\n"
  print_green "Cleanup the docker services"
  printf "######################\n"
  printf "Usage: %s [OPTIONS]\n" "$0"
  printf "Options:\n"
  printf "  --force\t\t\tCleanup all the docker services on the host\n"
  printf "  --app <app_name>\tCleanup specific app\n"
  printf "  --help\t\tShow help\n"
  print_green "Default: Cleanup all the services defined in the .env"
  printf "######################\n"
}

# docker compose down
app_down() {
  local app_name=$1
  # Find all docker-compose.yml files and stop the services
  for file in $(find "${workdir}" -maxdepth 2 -name "docker-compose.yaml" -name "docker-compose.yml" -name "compose.yaml" | grep "$app_name"); do
    printf "Stopping the %s app...\n" "$app_name"
    docker compose -f "$file" down --volumes --remove-orphans --timeout 1
  done
}

cleanup_all_containers() {
  docker container stop $(docker container ls -aq)
  docker container rm $(docker container ls -aq)
}

# function to delete app dirs
delete_app_dirs() {
  local app_name=$1
  printf "Deleting the %s app dir ...\n" "$app_name"
  sudo rm -rf "${workdir}/${app_name}"
}

# Default function
default_cleanup() {
  # Iterate over APPS_TO_INSTALL and delete the app dirs
  for app in "${APPS_TO_INSTALL[@]}"; do
    app_down "$app"
    delete_app_dirs "$app"
  done

  delete_app_dirs ".env"
  app_down "nginx"
  delete_app_dirs "nginx"
  sudo docker network prune --force

  print_green_v2 "Cleanup" "finished"
}

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
    cleanup_all_containers
    shift
    ;;
  *)
    default_cleanup
    exit 0
    ;;
  esac
done

print_green_v2 "Cleanup" "finished"
