#!/bin/bash

# Script to update the Velociraptor version in .env file
# The script will read the VELOCIRAPTOR_VERSION from the main .env file
# Usage: ./update_velociraptor_version.sh [new_version]
# If no version is provided, it will use the current VELOCIRAPTOR_VERSION from main .env
# Example: ./update_velociraptor_version.sh v0.74

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
VELOCIRAPTOR_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/velociraptor/.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check Velociraptor env file
    if [ ! -f "$VELOCIRAPTOR_ENV_FILE" ]; then
        echo "Error: Velociraptor configuration file not found at $VELOCIRAPTOR_ENV_FILE"
        exit 1
    else
        echo "Found Velociraptor configuration file at $VELOCIRAPTOR_ENV_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the VELOCIRAPTOR_VERSION from main .env file
get_velociraptor_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local velociraptor_version=$(grep "VELOCIRAPTOR_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$velociraptor_version" ]; then
            echo "Warning: VELOCIRAPTOR_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found VELOCIRAPTOR_VERSION=$velociraptor_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$velociraptor_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the Velociraptor version
update_version() {
    local new_version=$1
    local main_velociraptor_version=$2
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_velociraptor_version" ]; then
            echo "No version specified, using VELOCIRAPTOR_VERSION from main .env: $main_velociraptor_version"
            new_version="$main_velociraptor_version"
        else
            echo "Error: No version specified and couldn't get VELOCIRAPTOR_VERSION from main .env"
            echo "Usage: ./update_velociraptor_version.sh [new_version]"
            echo "Example: ./update_velociraptor_version.sh v0.74"
            exit 1
        fi
    fi
    
    # Get current version for logging
    local current_version=$(grep "VELOCIRAPTOR_VERSION=" "$VELOCIRAPTOR_ENV_FILE" | cut -d'=' -f2)
    
    # Use sed to update the version
    if sed -i "s/VELOCIRAPTOR_VERSION=.*/VELOCIRAPTOR_VERSION=$new_version/" "$VELOCIRAPTOR_ENV_FILE"; then
        echo "Success: Velociraptor version updated from $current_version to $new_version"
        echo "Updated file: $VELOCIRAPTOR_ENV_FILE"
    else
        echo "Error: Failed to update Velociraptor version"
        exit 1
    fi
}

# Main execution
check_files_exist

# Get Velociraptor version from main .env file
MAIN_VELOCIRAPTOR_VERSION=$(get_velociraptor_version)
echo "Information: VELOCIRAPTOR_VERSION from main .env is $MAIN_VELOCIRAPTOR_VERSION"

# Update Velociraptor version with provided argument
update_version "$1" "$MAIN_VELOCIRAPTOR_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current Velociraptor .env file content:"
cat "$VELOCIRAPTOR_ENV_FILE"

exit 0