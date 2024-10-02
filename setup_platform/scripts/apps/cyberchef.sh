#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
SERVICE_NAME="cyberchef"
SRC_DIR="$home_path/resources/$SERVICE_NAME"
CURR_DIR=$(pwd)

mkdir -p "${CURR_DIR}/${SERVICE_NAME}"
cd "${CURR_DIR}/${SERVICE_NAME}"

# Step 1: Copy app related files
printf "Copying app related files from %s...\n" "$SRC_DIR"
rsync -av "$SRC_DIR/" .

# Step 2: Start the service
printf "Starting the service...\n"
sudo docker-compose up -d

printf "CyberChef deployment completed successfully.\n"
