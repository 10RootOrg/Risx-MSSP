#!/bin/bash

# Script to update the CyberChef version in .env file
# The script will read the CYBERCHEF_VERSION from the main .env file
# Usage: ./update_cyberchef_version.sh [new_version]
# If no version is provided, it will use the current CYBERCHEF_VERSION from main .env
# Example: ./update_cyberchef_version.sh 10.20

# Get the current user
CURRENT_USER=$(whoami)
# Define paths dynamically based on current user
CYBERCHEF_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/cyberchef/.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check CyberChef env file
    if [ ! -f "$CYBERCHEF_ENV_FILE" ]; then
        echo "Error: CyberChef configuration file not found at $CYBERCHEF_ENV_FILE"
        exit 1
    else
        echo "Found CyberChef configuration file at $CYBERCHEF_ENV_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the CYBERCHEF_VERSION from main .env file
get_cyberchef_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local cyberchef_version=$(grep "CYBERCHEF_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$cyberchef_version" ]; then
            echo "Warning: CYBERCHEF_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found CYBERCHEF_VERSION=$cyberchef_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$cyberchef_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the CyberChef version
update_version() {
    local new_version=$1
    local main_cyberchef_version=$2
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_cyberchef_version" ]; then
            echo "No version specified, using CYBERCHEF_VERSION from main .env: $main_cyberchef_version"
            new_version="$main_cyberchef_version"
        else
            echo "Error: No version specified and couldn't get CYBERCHEF_VERSION from main .env"
            echo "Usage: ./update_cyberchef_version.sh [new_version]"
            echo "Example: ./update_cyberchef_version.sh 10.20"
            exit 1
        fi
    fi
    
    # Get current version for logging
    local current_version=$(grep "IMAGE_TAG=" "$CYBERCHEF_ENV_FILE" | cut -d'=' -f2)
    
    # Use sed to update the version
    if sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=$new_version/" "$CYBERCHEF_ENV_FILE"; then
        echo "Success: CyberChef version updated from $current_version to $new_version"
        echo "Updated file: $CYBERCHEF_ENV_FILE"
    else
        echo "Error: Failed to update CyberChef version"
        exit 1
    fi
}

# Main execution
check_files_exist

# Get CyberChef version from main .env file
MAIN_CYBERCHEF_VERSION=$(get_cyberchef_version)
echo "Information: CYBERCHEF_VERSION from main .env is $MAIN_CYBERCHEF_VERSION"

# Update CyberChef version with provided argument
update_version "$1" "$MAIN_CYBERCHEF_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current CyberChef .env file content:"
cat "$CYBERCHEF_ENV_FILE"

exit 0