#!/bin/bash
#Reference https://timesketch.org/developers/getting-started/

# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
SERVICE_NAME="nightingale"
SRC_DIR="$home_path/resources/$SERVICE_NAME"
CURR_DIR=$(pwd)

mkdir -p "${CURR_DIR}/${SERVICE_NAME}"
cd "${CURR_DIR}/${SERVICE_NAME}"

# Step 1: Copy the Nightingale stack configs
printf "Copying the Nightingale stack configs...\n"
rsync -av "${SRC_DIR}/" .

# Step 2: Start the Nightingale service
printf "Starting the Nightingale service...\n"
docker-compose up -d

printf "Nightingale deployment completed successfully.\n"
