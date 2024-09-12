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
SCRIPTS_DIR=$(pwd)
GIT_COMMIT=${GIT_COMMIT_VELOCIRAPTOR:-6da375b2ad9bb1f7ea2105967742a04bd485c9d8}
OVERWRITE_DEFAULT=${OVERWRITE_DEFAULT:-"yes"}

# --- Function get env value from .env file
# Inputs:
# $1 - key to get the value
# $2[optional] - env file path
function get_env_value() {
  local key=$1
  local env_file=${2:-"${SCRIPTS_DIR}/${SERVICE_NAME}/.env"}
  local value=$(grep "$key" "$env_file" | cut -d '=' -f2)
  echo "$value"
}

# --- Replace the default values in the .env file which uses by docker-compose file
# Inputs:
# $1 - env file path to replace the values
# $2 - key to replace
function replace_env() {
  local env_file=$1
  local key=$2

  if [[ -v $key ]]; then
    sed -i "s|${key}=.*|${key}=\"${!key}\"|" "$env_file"
  else
    echo "The env variable $key is not provided"
  fi
}


printf "Preparing the %s:%s stack...\n" "$SERVICE_NAME" "$GIT_COMMIT"
git clone https://github.com/weslambert/velociraptor-docker "$SERVICE_NAME"
cd "$SERVICE_NAME"
git checkout "$GIT_COMMIT"
cp "${SRC_DIR}/docker-compose.yaml" .
cp "${SRC_DIR}/entrypoint" .
cp "${SRC_DIR}/.env" .

GLOBAL_ENV="${home_path}/scripts/.env"
source "$GLOBAL_ENV"
replace_env ".env" "VELOX_USER"
replace_env ".env" "VELOX_PASSWORD"

sudo docker compose build
sudo docker compose up -d
printf "Waiting for the %s service to start...\n" "$SERVICE_NAME"
sleep 5

sudo chmod 777 -R "${SCRIPTS_DIR}/${SERVICE_NAME}/velociraptor"
sudo chmod 777 -R "${SCRIPTS_DIR}/${SERVICE_NAME}/velociraptor/clients"
cd velociraptor
cp -R "${SRC_DIR}/custom/" .
sudo docker restart "${SERVICE_NAME}"
printf "Velociraptor deployment completed successfully.\n"


# --- Show login credentials
_VELOX_USER=$(get_env_value 'VELOX_USER')
_VELOX_PASSWORD=$(get_env_value 'VELOX_PASSWORD')
echo "############################################"
echo "$SERVICE_NAME credentials:"
echo "Username: $_VELOX_USER"
echo "Password: $_VELOX_PASSWORD"
echo "############################################"

# If the VELOX_USER is not defined in the global .env, then add creds to the .env file
if [[ -z $VELOX_USER ]]; then
    echo "Velociraptor credentials added to the .env file"
    echo "### Generated by Velociraptor scripts ###" >> "$home_path/scripts/.env"
    echo "VELOCIRAPTOR_USERNAME=$_VELOX_USER" >> "$home_path/scripts/.env"
    echo "VELOCIRAPTOR_PASSWORD=$_VELOX_PASSWORD" >> "$home_path/scripts/.env"
fi
