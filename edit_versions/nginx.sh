#!/bin/bash

# Script to update the Nginx version in .env file
# Usage: ./update_nginx_version.sh [new_version]

CURRENT_USER=$(whoami)

NGINX_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/nginx/.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

check_files_exist() {
    [ -f "$NGINX_ENV_FILE" ] && echo "Found Nginx configuration file at $NGINX_ENV_FILE" || { echo "Error: Nginx configuration file not found."; exit 1; }
    [ -f "$MAIN_ENV_FILE" ] && echo "Found main configuration file at $MAIN_ENV_FILE" || { echo "Error: Main configuration file not found."; exit 1; }
}

get_nginx_version() {
    local version=$(grep "^NGINX_VERSION=" "$MAIN_ENV_FILE" | head -n1 | cut -d'=' -f2 | tr -d '[:space:]')
    if [ -z "$version" ]; then
        echo "Error: NGINX_VERSION not found in $MAIN_ENV_FILE" >&2
        exit 1
    fi
    echo "$version"
}


update_version() {
    local new_version=$1

    if [ -z "$new_version" ]; then
        new_version=$(get_nginx_version)
        echo "No version specified, using NGINX_VERSION from main .env: $new_version"
    fi

    local current_version=$(grep "NGINX_VERSION=" "$NGINX_ENV_FILE" | cut -d'=' -f2)

    # Fixed sed command using a safe delimiter '|'
    if sed -i "s|NGINX_VERSION=.*|NGINX_VERSION=$new_version|" "$NGINX_ENV_FILE"; then
        echo "Success: Nginx version updated from $current_version to $new_version"
        echo "Updated file: $NGINX_ENV_FILE"
    else
        echo "Error: Failed to update Nginx version"
        exit 1
    fi
}

check_files_exist
update_version "$1"

# Show updated content
echo "-------------------------------------"
echo "Current Nginx .env file content:"
cat "$NGINX_ENV_FILE"

exit 0