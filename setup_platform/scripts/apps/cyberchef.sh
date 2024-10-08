#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
source "./libs/install-helper.sh"
define_paths
define_env

# Step 1: Pre-installation
pre_install "cyberchef"

# Step 2: Start the service
printf "Starting the service...\n"
sudo docker compose up -d --force-recreate

print_green_v2 "CyberChef deployment completed." "Successfully"
