#!/bin/bash
#Reference https://github.com/Velocidex/velociraptor and https://github.com/weslambert/velocistack

# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
SERVICE_NAME="velociraptor"
SRC_DIR="$home_path/resources/$SERVICE_NAME"
CURR_DIR=$(pwd)
GIT_COMMIT=${GIT_COMMIT_VELOCIRAPTOR:-6da375b2ad9bb1f7ea2105967742a04bd485c9d8}
OVERWRITE_DEFAULT=${OVERWRITE_DEFAULT:-"yes"}


printf "Preparing the %s:%s stack...\n" "$SERVICE_NAME" "$GIT_COMMIT"
# Check if the directory with the git repository already exists
if [ -d "$SERVICE_NAME" ] && [ "$(ls -A $SERVICE_NAME)" ]; then
  read -p "The $SERVICE_NAME directory already exists. Would you like to overwrite it? (y/n)(default:$OVERWRITE_DEFAULT): " overwrite
  overwrite=${overwrite:-$OVERWRITE_DEFAULT}
  if [[ "$overwrite" == "y" || "$overwrite" == "yes" ]]; then
    sudo rm -rf "$SERVICE_NAME"
  else
    printf "Exiting the script...\n"
    exit 1
  fi
fi

git clone https://github.com/weslambert/velociraptor-docker "$SERVICE_NAME"
cd "$SERVICE_NAME"
git checkout "$GIT_COMMIT"
cp "${SRC_DIR}/docker-compose.yaml" .
cp "${SRC_DIR}/entrypoint" .

sudo docker compose build
sudo docker compose up -d
sleep 5

sudo chmod 777 -R "${CURR_DIR}/${SERVICE_NAME}/velociraptor"
sudo chmod 777 -R "${CURR_DIR}/${SERVICE_NAME}/velociraptor/clients"
cd velociraptor
cp -R "${SRC_DIR}/custom/" .
sudo docker restart "${SERVICE_NAME}"
printf "Velociraptor deployment completed successfully.\n"
