#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
mkdir -p portainer
cd portainer

# Step 1: Copy the docker-compose.yaml file from the specified home_path
printf "Copying docker-compose.yml from %s...\n" "$home_path"
cp "${home_path}/resources/portainer/docker-compose.yaml" .

# Step 2: Use Docker Compose to bring up the services in detached mode
printf "Bringing up the services in detached mode...\n"
sudo docker compose up -d # TODO: Why do we need sudo here?

printf "Portainer deployment completed successfully.\n"
