#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "reconftw"
replace_envs "${workdir}/${service_name}/.env"

# Step 2: Create Recon output directory
mkdir -p "${workdir}/${service_name}/Recon"
chmod 755 "${workdir}/${service_name}/Recon"

# Step 3: Start the service
printf "Starting the service...\n"
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started." "Successfully"
