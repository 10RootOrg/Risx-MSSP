#!/bin/bash
# Reference: https://github.com/MISP/misp-docker

set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "misp" false

# Step 2: Clone MISP docker repository
if [[ ! -d "misp-docker" ]]; then
  git clone https://github.com/MISP/misp-docker misp-docker
fi

# Step 3: Update .env with provided MISP_VERSION if set
if [[ -n "${MISP_VERSION:-}" && -f "misp-docker/.env" ]]; then
  if grep -q '^MISP_TAG=' "misp-docker/.env"; then
    sed -i "s/^MISP_TAG=.*/MISP_TAG=${MISP_VERSION}/" "misp-docker/.env"
  elif grep -q '^MISP_VERSION=' "misp-docker/.env"; then
    sed -i "s/^MISP_VERSION=.*/MISP_VERSION=${MISP_VERSION}/" "misp-docker/.env"
  else
    echo "MISP_TAG=${MISP_VERSION}" >> "misp-docker/.env"
  fi
fi

# Step 4: Start the service
replace_envs "${workdir}/${service_name}/.env"
printf "Starting the service...\n"
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started." "Successfully"
