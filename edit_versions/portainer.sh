#!/bin/bash

# Script to update the Portainer versions in docker-compose.yaml file
# The script will read the PORTAINER_VERSION from the main .env file
# Usage: ./update_portainer_version.sh [new_version]
# If no version is provided, it will use the current PORTAINER_VERSION from main .env
# Example: ./update_portainer_version.sh 2.22.0

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
PORTAINER_COMPOSE_FILE="/home/${CURRENT_USER}/setup_platform/resources/portainer/docker-compose.yaml"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check Portainer compose file
    if [ ! -f "$PORTAINER_COMPOSE_FILE" ]; then
        echo "Error: Portainer docker-compose file not found at $PORTAINER_COMPOSE_FILE"
        exit 1
    else
        echo "Found Portainer docker-compose file at $PORTAINER_COMPOSE_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the PORTAINER_VERSION from main .env file
get_portainer_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local portainer_version=$(grep "PORTAINER_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$portainer_version" ]; then
            echo "Warning: PORTAINER_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found PORTAINER_VERSION=$portainer_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$portainer_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the Portainer versions in docker-compose.yaml
update_version() {
    local new_version=$1
    local main_portainer_version=$2
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_portainer_version" ]; then
            echo "No version specified, using PORTAINER_VERSION from main .env: $main_portainer_version"
            new_version="$main_portainer_version"
        else
            echo "Error: No version specified and couldn't get PORTAINER_VERSION from main .env"
            echo "Usage: ./update_portainer_version.sh [new_version]"
            echo "Example: ./update_portainer_version.sh 2.22.0"
            exit 1
        fi
    fi
    
    # Get current agent version for logging
    local current_agent_version=$(grep -A1 "agent:" "$PORTAINER_COMPOSE_FILE" | grep "image:" | awk -F: '{print $3}')
    
    # Get current portainer version for logging
    local current_portainer_version=$(grep -A1 "portainer:" "$PORTAINER_COMPOSE_FILE" | grep "image:" | awk -F: '{print $3}')
    
    # Use sed to update both agent and portainer-ce versions
    # First update the agent version
    if sed -i "s/portainer\/agent:[^ ]*/portainer\/agent:$new_version/g" "$PORTAINER_COMPOSE_FILE"; then
        echo "Success: Portainer Agent version updated from $current_agent_version to $new_version"
    else
        echo "Error: Failed to update Portainer Agent version"
        exit 1
    fi
    
    # Then update the portainer-ce version
    if sed -i "s/portainer\/portainer-ce:[^ ]*/portainer\/portainer-ce:$new_version/g" "$PORTAINER_COMPOSE_FILE"; then
        echo "Success: Portainer CE version updated from $current_portainer_version to $new_version"
        echo "Updated file: $PORTAINER_COMPOSE_FILE"
    else
        echo "Error: Failed to update Portainer CE version"
        exit 1
    fi
}

# Main execution
check_files_exist

# Get Portainer version from main .env file
MAIN_PORTAINER_VERSION=$(get_portainer_version)
echo "Information: PORTAINER_VERSION from main .env is $MAIN_PORTAINER_VERSION"

# Update Portainer version with provided argument
update_version "$1" "$MAIN_PORTAINER_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current Portainer docker-compose file version entries:"
grep -n "image: portainer" "$PORTAINER_COMPOSE_FILE"

exit 0