#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Copy the stack configs
pre_install "misp"
replace_envs "${workdir}/${service_name}/.env"

# Step 2: Clone the official misp-docker repository
if [ ! -d misp-docker ]; then
  git clone --depth 1 https://github.com/MISP/misp-docker misp-docker
else
  print_yellow "misp-docker repository already exists. Skipping clone."
fi

# Step 3: Prepare environment and start the service
cp .env misp-docker/.env
cd misp-docker

printf "Starting the service...\n"
docker compose up -d --build

print_green_v2 "$service_name deployment started." "Successfully"
