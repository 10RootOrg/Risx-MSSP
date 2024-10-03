#!/usr/bin/env bash
set -eo pipefail

source .env
# If the username is not defined, then ask user to enter the username
if [ -z "$username" ]; then
  current_user=$(whoami)
  read -p "Enter username for home directory setup (default: $current_user): " username
  username=${username:-$current_user}
fi
scripts_path="/home/$username/setup_platform/scripts"

# docker compose down
app_down() {
  local app_name=$1
  printf "Stopping the %s app...\n" "$app_name"

  # Find all docker-compose.yml files and stop the services
  for file in $(find "${scripts_path}" -name "docker-compose.yml" | grep "$app_name"); do
    sudo docker compose -f "$file" down --volumes --remove-orphans --timeout 5
  done
}

# function to delete app dirs
delete_app_dirs() {
  local app_name=$1
  printf "Deleting the %s app...\n" "$app_name"
  sudo rm -rf "${scripts_path}/${app_name}"
}

# Iterate over APPS_TO_INSTALL and delete the app dirs
for app in $APPS_TO_INSTALL; do
  app_down "$app"
  delete_app_dirs "$app"
done

delete_app_dirs ".env"
app_down "nginx"
delete_app_dirs "nginx"
sudo docker network prune --force

printf "####\nCleanup finished\n"
