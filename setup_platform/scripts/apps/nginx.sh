#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
source "./libs/install-helper.sh"
# Check if home_path is provided
check_home_path "$1"

home_path=$1
source .env
home_path=$1
SERVICE_NAME="nginx"
SRC_DIR="$home_path/resources/$SERVICE_NAME"
CURR_DIR=$(pwd)

mkdir -p "${CURR_DIR}/${SERVICE_NAME}"
cd "${CURR_DIR}/${SERVICE_NAME}"

# Step 1: Copy the stack configs
printf "Copying the %s stack configs...\n" "$SERVICE_NAME"
rsync -av "${SRC_DIR}/" .

# Step 2: Prepare nginx configs
for app in "${APPS_TO_INSTALL[@]}"; do
  # replace app in the nginx config to include conf.d/$app.conf;, otherwise replace to empty
  if [ -f "conf.d/$app.conf" ]; then
    sed -i "s/#include conf.d\/$app.conf;/include conf.d\/$app.conf;/g" "nginx.conf"
  fi
done

# Step 3: Start
printf "Starting the %s service...\n" "$SERVICE_NAME"
source ./.env
docker compose up -d

print_green_v2 "Nginx deployment completed" "successfully"
