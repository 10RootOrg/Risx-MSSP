#!/bin/bash
# Reference: https://github.com/prowler-cloud/prowler/

# Exit immediately if a command exits with a non-zero status 
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "prowler"
# replace_env "PROWLER_IMAGE_TAG"
# replace_env "PROWLER_COMMAND"

# Step 2: Start the service
printf "Starting the service...\n"
docker compose up -d --force-recreate

# Step 3: Post-installation output
# Add output from the prowler README.md
docker run --rm -it -e "TERM=xterm-256color" -v "${workdir}/${service_name}":/tmp ghcr.io/charmbracelet/glow:v2.0 /tmp/README.md
print_green_v2 "$service_name deployment started." "Successfully"
