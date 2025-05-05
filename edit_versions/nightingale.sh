#!/bin/bash

# Script to update the Nightingale version in .env file
# The script will read the NIGHTINGALE_VERSION from the main .env file
# Usage: ./update_nightingale_version.sh [new_version]
# If no version is provided, it will use the current NIGHTINGALE_VERSION from main .env
# Example: ./update_nightingale_version.sh v2.0.0

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
NIGHTINGALE_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/nightingale/.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check Nightingale env file
    if [ ! -f "$NIGHTINGALE_ENV_FILE" ]; then
        echo "Error: Nightingale configuration file not found at $NIGHTINGALE_ENV_FILE"
        exit 1
    else
        echo "Found Nightingale configuration file at $NIGHTINGALE_ENV_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the NIGHTINGALE_VERSION from main .env file
get_nightingale_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local nightingale_version=$(grep "NIGHTINGALE_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$nightingale_version" ]; then
            echo "Warning: NIGHTINGALE_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found NIGHTINGALE_VERSION=$nightingale_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$nightingale_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the Nightingale version
update_version() {
    local new_version=$1
    local main_nightingale_version=$2
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_nightingale_version" ]; then
            echo "No version specified, using NIGHTINGALE_VERSION from main .env: $main_nightingale_version"
            new_version="$main_nightingale_version"
        else
            echo "Error: No version specified and couldn't get NIGHTINGALE_VERSION from main .env"
            echo "Usage: ./update_nightingale_version.sh [new_version]"
            echo "Example: ./update_nightingale_version.sh v2.0.0"
            exit 1
        fi
    fi
    
    # Get current version for logging
    local current_version=$(grep "image_tag=" "$NIGHTINGALE_ENV_FILE" | cut -d'=' -f2)
    
    # Use sed to update the version
    if sed -i "s/image_tag=.*/image_tag=$new_version/" "$NIGHTINGALE_ENV_FILE"; then
        echo "Success: Nightingale version updated from $current_version to $new_version"
        echo "Updated file: $NIGHTINGALE_ENV_FILE"
    else
        echo "Error: Failed to update Nightingale version"
        exit 1
    fi
}

# Main execution
check_files_exist

# Get Nightingale version from main .env file
MAIN_NIGHTINGALE_VERSION=$(get_nightingale_version)
echo "Information: NIGHTINGALE_VERSION from main .env is $MAIN_NIGHTINGALE_VERSION"

# Update Nightingale version with provided argument
update_version "$1" "$MAIN_NIGHTINGALE_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current Nightingale .env file content:"
cat "$NIGHTINGALE_ENV_FILE"

exit 0