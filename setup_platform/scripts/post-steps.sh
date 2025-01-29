#!/usr/bin/env bash
set -eo pipefail

source libs/main.sh
source libs/host-dirs.sh
define_env
define_paths

APPS_TO_RESTART=${APPS_TO_RESTART:-"portainer nginx"}
APPS_TO_RESTART=($APPS_TO_RESTART)

printf "Post deployment steps:\n"
function restart_app() {
  local app_name=$1
  if [[ -z "$app_name" ]]; then
    printf "App name is not provided\n"
    print_red "Usage: %s --app <app_name>\n" "$0"
    exit 1
  fi

  # Find all docker-compose.yml files and stop the services
  while IFS= read -r -d '' file; do
    printf "Restarting the %s app...\n" "$app_name"
    cd "$(dirname "$file")" || exit
    docker compose restart
    cd - || exit
  done < <(find "${workdir}/${app_name}" -maxdepth 2 -name docker-compose.yaml -print0 -o -name docker-compose.yml -print0 -o -name compose.yaml -print0)
}

function restart_apps() {
  for app in "${APPS_TO_RESTART[@]}"; do
    if [[ " ${APPS_TO_INSTALL[@]} " =~ "$app" ]]; then
      restart_app "$app"
    fi
  done
}
