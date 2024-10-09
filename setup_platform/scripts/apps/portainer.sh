#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Copy the stack configs
pre_install "portainer"

# Step 2: Use Docker Compose to bring up the services in detached mode
printf "Starting the service...\n"
docker compose up -d --force-recreate
printf "Sleeping for 15 seconds to let the service start...\n"
sleep 15

print_green_v2 "$service_name deployment started" "successfully"
