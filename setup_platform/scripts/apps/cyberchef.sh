#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "cyberchef"

# Step 2: Start the service
printf "Starting the service...\n"
sudo docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started." "Successfully"
