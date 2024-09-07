#!/bin/bash
###
# TODO:Why do we need to build ELK from the source code instead of using the official Docker image?
###
# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
ELK_GIT_COMMIT=${ELK_GIT_COMMIT:-"629aea4"}
# Step 1: Clone only the specific commit "629aea4" from the repository
printf "Cloning the repository and checking out commit %s...\n" "$ELK_GIT_COMMIT"
git clone --branch main --single-branch --depth 1 https://github.com/deviantony/docker-elk.git
cd docker-elk
git fetch --depth 1 origin "$ELK_GIT_COMMIT"
git checkout "$ELK_GIT_COMMIT"

# Step 2: Copy the docker-compose.yml file from the specified home_path
printf "Copying docker-compose.yml from %s...\n" "$home_path"
cp "$home_path/resources/docker-elk/docker-compose.yml" .

# Step 3: Use Docker Compose to bring up the setup service and then the rest of the services in detached mode
printf "Bringing up the setup service...\n"
sudo docker compose up setup

printf "Bringing up the rest of the services in detached mode...\n"
sudo docker compose up -d

printf "Kibana(ELK) deployment completed successfully.\n"
