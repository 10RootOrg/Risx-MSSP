#!/bin/bash
# Deploy MISP using the official misp-docker repository
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

service_name="misp"

MISP_VERSION=${MISP_VERSION:-"2.4.176"}

printf "Cloning misp-docker repository with tag %s...\n" "$MISP_VERSION"
if [ -d "${workdir}/${service_name}" ]; then
  print_red "The directory ${workdir}/${service_name} already exists. Please remove it before running the script."
  print_yellow "./cleanup.sh --app ${service_name}"
  exit 1
fi

git clone --branch "$MISP_VERSION" --single-branch --depth 1 \
  https://github.com/MISP/misp-docker "${workdir}/${service_name}"

pre_install "$service_name" false

cd "${workdir}/${service_name}"

# Use provided .env file from the repository
# If a local configuration exists in resources/misp/.env copy it first
if [ -f "$src_dir/.env" ]; then
  cp "$src_dir/.env" .
fi
if [ ! -f .env ] && [ -f .env.sample ]; then
  cp .env.sample .env
fi

if [ ! -f .env ] && [ -f example.env ]; then
  cp example.env .env
fi

if [ ! -f .env ]; then
  print_yellow ".env file not found in the misp-docker repository"
  touch .env
fi

replace_envs "${workdir}/${service_name}/.env"

printf "Starting the service...\n"
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started" "successfully"

