#!/bin/bash
# Reference: https://github.com/MISP/misp-docker

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"
pre_install "misp"

replace_envs "${workdir}/${service_name}/.env"

# Step 2: Start the service
printf "Starting the service...\n"
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started." "Successfully"