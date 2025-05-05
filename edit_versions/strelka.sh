#!/bin/bash

# Script to update the Strelka versions in docker-compose.yml file
# The script will read the STRELKA_VERSION from the main .env file
# Usage: ./update_strelka_version.sh [new_version]
# If no version is provided, it will use the current STRELKA_VERSION from main .env
# Example: ./update_strelka_version.sh 0.24.08.01

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
STRELKA_COMPOSE_FILE="/home/${CURRENT_USER}/setup_platform/resources/strelka/docker-compose.yml"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check Strelka compose file
    if [ ! -f "$STRELKA_COMPOSE_FILE" ]; then
        echo "Error: Strelka docker-compose file not found at $STRELKA_COMPOSE_FILE"
        exit 1
    else
        echo "Found Strelka docker-compose file at $STRELKA_COMPOSE_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the STRELKA_VERSION from main .env file
get_strelka_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local strelka_version=$(grep "STRELKA_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$strelka_version" ]; then
            echo "Warning: STRELKA_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found STRELKA_VERSION=$strelka_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$strelka_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the Strelka versions in docker-compose.yml
update_version() {
    local new_version=$1
    local main_strelka_version=$2
    local strelka_components=("frontend" "backend" "manager")
    local had_errors=0
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_strelka_version" ]; then
            echo "No version specified, using STRELKA_VERSION from main .env: $main_strelka_version"
            new_version="$main_strelka_version"
        else
            echo "Error: No version specified and couldn't get STRELKA_VERSION from main .env"
            echo "Usage: ./update_strelka_version.sh [new_version]"
            echo "Example: ./update_strelka_version.sh 0.24.08.01"
            exit 1
        fi
    fi
    
    # Get current version for logging (from frontend service)
    local current_version=$(grep -A1 "frontend:" "$STRELKA_COMPOSE_FILE" | grep "image:" | awk -F: '{print $3}')
    echo "Current Strelka version: $current_version"
    
    # Update each Strelka component
    for component in "${strelka_components[@]}"; do
        if sed -i "s/target\/strelka-${component}:[^ ]*/target\/strelka-${component}:$new_version/g" "$STRELKA_COMPOSE_FILE"; then
            echo "Success: Strelka $component version updated to $new_version"
        else
            echo "Error: Failed to update Strelka $component version"
            had_errors=1
        fi
    done
    
    if [ $had_errors -eq 0 ]; then
        echo "Updated file: $STRELKA_COMPOSE_FILE"
        return 0
    else
        echo "Some errors occurred while updating versions"
        return 1
    fi
}

# Main execution
check_files_exist

# Get Strelka version from main .env file
MAIN_STRELKA_VERSION=$(get_strelka_version)
echo "Information: STRELKA_VERSION from main .env is $MAIN_STRELKA_VERSION"

# Update Strelka version with provided argument
update_version "$1" "$MAIN_STRELKA_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current Strelka docker-compose file version entries:"
grep -n "image: target/strelka-" "$STRELKA_COMPOSE_FILE"

exit 0