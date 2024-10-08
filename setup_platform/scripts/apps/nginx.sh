#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Copy the stack configs
pre_install "nginx"

# Step 2: Prepare nginx configs
for app in "${APPS_TO_INSTALL[@]}"; do
  # replace app in the nginx config to include conf.d/$app.conf;, otherwise replace to empty
  if [ -f "etc/nginx/conf.d/$app.conf" ]; then
    sed -i "s/#include conf.d\/$app.conf;/include conf.d\/$app.conf;/g" "etc/nginx/nginx.conf"
  fi
done

# Step 3: Start
printf "Starting the %s service...\n" "$service_name"
source ./.env
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started" "successfully"
