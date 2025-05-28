#!/bin/bash
# Reference: https://github.com/MISP/misp-docker

set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "misp" false

# Step 2: Clone misp-docker if not exists
if [ ! -d "misp-docker" ]; then
  git clone https://github.com/MISP/misp-docker.git misp-docker
fi

# Step 3: Load environment variables if .env exists
if [ -f "misp-docker/.env" ]; then
  replace_envs "misp-docker/.env"
fi

# Step 4: Start the service from within misp-docker
pushd misp-docker >/dev/null

docker compose up -d --force-recreate

popd >/dev/null

print_green_v2 "$service_name deployment started." "Successfully"
