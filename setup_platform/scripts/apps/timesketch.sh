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
SERVICE_NAME="timesketch"
SRC_DIR="$home_path/resources/$SERVICE_NAME"
CURR_DIR=$(pwd)

mkdir -p "${CURR_DIR}/${SERVICE_NAME}"
cd "${CURR_DIR}/${SERVICE_NAME}"

printf "Copying the Timesketch stack configs...\n"
cp "${SRC_DIR}/deploy_timesketch.sh" .
cp "${SRC_DIR}/config.env" .
cp "${SRC_DIR}/docker-compose.yml" .

sudo chmod 755 deploy_timesketch.sh
sudo ./deploy_timesketch.sh "$home_path"
