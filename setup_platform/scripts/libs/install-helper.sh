#!/usr/bin/env bash
set -eo pipefail
# --- Reused functions in the app install scripts

# TODO:Deprecated, because of define this variable in the define_paths function
# --- Function to Check if the first argument is provided
# Inputs:
# $1 - home_path
function check_home_path() {
  local home_path=${1:-"$home_path"}
  if [ -z "$home_path" ]; then
    print_red "Usage: %s <home_path>\n" "$0"
    exit 1
  fi
}

# --- Function to get env value from .env file
# Inputs:
# $1 - key to get the value
# $2[optional] - env file path
function get_env_value() {
  local key=$1
  local env_file=${2:-"${workdir}/${service_name}/.env"}
  local value=$(sed -n "s/^${key}=//p" "$env_file")
  printf "%s\n" "$value"
}

# --- Replace the default values in the local .env file which uses by docker compose file
# Inputs:
# $1 - env file path to replace the values
# $2 - key to replace
function replace_env() {
  local key=$1
  local env_file=${2:-"${scripts_dir}/${service_name}/.env"}

  if [[ -v $key ]]; then
    sed -i "s|${key}=.*|${key}=\"${!key}\"|" "$env_file"
  else
    print_yellow "The env variable $key is not provided"
  fi
}

# --- Download external file
# Inputs:
# $1 - url to download
# $2 - file name to save
function download_external_file() {
  local url=$1
  local file_name=$2
  if [ ! -f "$file_name" ]; then
    curl --show-error --silent --location --output "$file_name" "$url"
    print_green_v2 "$file_name" "Downloaded"
  else
    print_red "$file_name already exists."
  fi
}

# --- PRE install steps for each app
# Inputs:
# $1 - service name
# $2 [option] - copy files from the source directory
function pre_install() {
  service_name=$1
  local copy_files=${2:-true}
  if [ -z "$service_name" ]; then
    printf "Service name is not provided\n"
    print_red "Usage: $0 <service_name>"
    exit 1
  fi

  src_dir="$resources_dir/$service_name"
  curr_dir=$(pwd)

  mkdir -p "${workdir}/${service_name}"
  cd "${workdir}/${service_name}"

  # Step 1: Copy app related files
  if [ "$copy_files" = true ]; then
    printf "Copying app related files from %s...\n" "$src_dir"
    rsync -a "$src_dir/" .
  else
    printf "Skipping copying app related files.\n"
  fi
}
