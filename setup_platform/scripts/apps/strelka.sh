#!/bin/bash
# Reference: https://github.com/target/strelka/

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "strelka"

# Step 2: Start the service
printf "Starting the service...\n"
docker compose up -d --force-recreate

# Step 3: Update the YARA rules
# App specific variables
# Replace the original configs/python/backend/yara/*
GITHUB_COMMIT_YARAHQ=${GITHUB_COMMIT_YARAHQ:-"20240922"} # Default to the latest commit
GITHUB_URL_YARAHQ="https://github.com/YARAHQ/yara-forge/releases/download/${GITHUB_COMMIT_YARAHQ}/yara-forge-rules-full.zip"
TMP_DIR=$(mktemp -d)
printf "Downloading the %s YARA rules from YARA Forge...\n" "${GITHUB_COMMIT_YARAHQ}"
curl -o "${TMP_DIR}"/yara-forge-rules-full.zip -Ls "${GITHUB_URL_YARAHQ}"
unzip -o "${TMP_DIR}"/yara-forge-rules-full.zip -d "${TMP_DIR}"

docker compose stop
sudo rm -rf configs/python/backend/yara/*
cp "${TMP_DIR}"/packages/full/yara-rules-full.yar configs/python/backend/yara/rules.yara
docker compose up -d

rm -rf "${TMP_DIR}"
printf "YARA rules updated successfully.\n"

print_green_v2 "$service_name deployment started." "Successfully"
