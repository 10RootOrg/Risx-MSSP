#!/usr/bin/env bash
set -eo pipefail

source libs/main.sh
source libs/host-dirs.sh
define_env
define_paths
initialize_container_runtime

# You can provide this variable from the main default.env file like it works for the APPS_TO_INSTALL var
# Ex: "portainer elk"
APPS_TO_RESTART=${APPS_TO_RESTART:-"portainer"}
APPS_TO_RESTART=($APPS_TO_RESTART)

printf "Post deployment steps:\n"
function restart_app() {
  local app_name=$1
  if [[ -z "$app_name" ]]; then
    printf "App name is not provided\n"
    print_red "Usage: %s --app <app_name>\n" "$0"
    exit 1
  fi

  # Find all compose files and restart the services
  while IFS= read -r -d '' file; do
    printf "Restarting the %s app...\n" "$app_name"
    cd "$(dirname "$file")" || exit
    container_compose restart
    cd - || exit
  done < <(find "${workdir}/${app_name}" -maxdepth 2 -name docker-compose.yaml -print0 -o -name docker-compose.yml -print0 -o -name compose.yaml -print0)
}

function restart_apps() {
  for app in "${APPS_TO_RESTART[@]}"; do
    if [[ " ${APPS_TO_INSTALL[@]} " =~ "$app" ]]; then
      restart_app "$app"
    fi
  done
  restart_app "nginx"
}
