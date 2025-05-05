#!/bin/bash

# Script to update the IRIS-web versions in docker-compose.yml file
# The script will read the IRIS_VERSION and IRIS_RABBITMQ_VERSION from the main .env file
# Usage: ./update_iris_version.sh [iris_version] [rabbitmq_version]
# If no version is provided, it will use the versions from the main .env file
# Example: ./update_iris_version.sh v2.5.0 3-management-alpine

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
IRIS_COMPOSE_FILE="/home/${CURRENT_USER}/setup_platform/resources/iris-web/docker-compose.yml"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Function to check if files exist
check_files_exist() {
    # Check IRIS compose file
    if [ ! -f "$IRIS_COMPOSE_FILE" ]; then
        echo "Error: IRIS-web docker-compose file not found at $IRIS_COMPOSE_FILE"
        exit 1
    else
        echo "Found IRIS-web docker-compose file at $IRIS_COMPOSE_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read the IRIS_VERSION from main .env file
get_iris_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local iris_version=$(grep "IRIS_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$iris_version" ]; then
            echo "Warning: IRIS_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found IRIS_VERSION=$iris_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$iris_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to read the IRIS_RABBITMQ_VERSION from main .env file
get_rabbitmq_version() {
    if [ -f "$MAIN_ENV_FILE" ]; then
        local rabbitmq_version=$(grep "IRIS_RABBITMQ_VERSION=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$rabbitmq_version" ]; then
            echo "Warning: IRIS_RABBITMQ_VERSION not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found IRIS_RABBITMQ_VERSION=$rabbitmq_version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$rabbitmq_version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update the IRIS-web versions in docker-compose.yml
update_version() {
    local new_version=$1
    local main_iris_version=$2
    local new_rabbitmq_version=$3
    local main_rabbitmq_version=$4
    local had_errors=0
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        if [ -n "$main_iris_version" ]; then
            echo "No version specified, using IRIS_VERSION from main .env: $main_iris_version"
            new_version="$main_iris_version"
        else
            echo "Error: No version specified and couldn't get IRIS_VERSION from main .env"
            echo "Usage: ./update_iris_version.sh [iris_version] [rabbitmq_version]"
            echo "Example: ./update_iris_version.sh v2.5.0 3-management-alpine"
            exit 1
        fi
    fi
    
    # Get current version for logging
    local current_db_version=$(grep -A2 "container_name: iriswebapp_db" "$IRIS_COMPOSE_FILE" | grep "image:" | sed -n 's/.*:\(v[0-9.]\+\).*/\1/p')
    echo "Current IRIS-web version: $current_db_version"
    
    # Update DB version
    if sed -i "s|ghcr.io/dfir-iris/iriswebapp_db:[^ ]*|ghcr.io/dfir-iris/iriswebapp_db:$new_version|g" "$IRIS_COMPOSE_FILE"; then
        echo "Success: IRIS-web DB version updated to $new_version"
    else
        echo "Error: Failed to update IRIS-web DB version"
        had_errors=1
    fi
    
    # Update App version (which affects both app and worker services)
    if sed -i "s|ghcr.io/dfir-iris/iriswebapp_app:[^ ]*|ghcr.io/dfir-iris/iriswebapp_app:$new_version|g" "$IRIS_COMPOSE_FILE"; then
        echo "Success: IRIS-web App version updated to $new_version"
    else
        echo "Error: Failed to update IRIS-web App version"
        had_errors=1
    fi
    
    # Update Nginx version
    if sed -i "s|ghcr.io/dfir-iris/iriswebapp_nginx:[^ ]*|ghcr.io/dfir-iris/iriswebapp_nginx:$new_version|g" "$IRIS_COMPOSE_FILE"; then
        echo "Success: IRIS-web Nginx version updated to $new_version"
    else
        echo "Error: Failed to update IRIS-web Nginx version"
        had_errors=1
    fi
    
    # Update RabbitMQ version if provided or available in main .env
    if [ -z "$new_rabbitmq_version" ]; then
        if [ -n "$main_rabbitmq_version" ]; then
            echo "Using IRIS_RABBITMQ_VERSION from main .env: $main_rabbitmq_version"
            new_rabbitmq_version="$main_rabbitmq_version"
            
            # Update RabbitMQ version
            if sed -i "s|rabbitmq:[^ ]*|rabbitmq:$new_rabbitmq_version|g" "$IRIS_COMPOSE_FILE"; then
                echo "Success: IRIS RabbitMQ version updated to $new_rabbitmq_version"
            else
                echo "Error: Failed to update IRIS RabbitMQ version"
                had_errors=1
            fi
        else
            echo "No RabbitMQ version specified and couldn't get IRIS_RABBITMQ_VERSION from main .env"
            echo "RabbitMQ version will not be updated"
        fi
    else
        # Update RabbitMQ version with provided value
        if sed -i "s|rabbitmq:[^ ]*|rabbitmq:$new_rabbitmq_version|g" "$IRIS_COMPOSE_FILE"; then
            echo "Success: IRIS RabbitMQ version updated to $new_rabbitmq_version"
        else
            echo "Error: Failed to update IRIS RabbitMQ version"
            had_errors=1
        fi
    fi
    
    if [ $had_errors -eq 0 ]; then
        echo "Updated file: $IRIS_COMPOSE_FILE"
        return 0
    else
        echo "Some errors occurred while updating versions"
        return 1
    fi
}

# Main execution
check_files_exist

# Get IRIS version from main .env file
MAIN_IRIS_VERSION=$(get_iris_version)
echo "Information: IRIS_VERSION from main .env is $MAIN_IRIS_VERSION"

# Get RabbitMQ version from main .env file
MAIN_RABBITMQ_VERSION=$(get_rabbitmq_version)
echo "Information: IRIS_RABBITMQ_VERSION from main .env is $MAIN_RABBITMQ_VERSION"

# Update IRIS version with provided argument
update_version "$1" "$MAIN_IRIS_VERSION" "$2" "$MAIN_RABBITMQ_VERSION"

# Optionally display the new content to verify
echo "-------------------------------------"
echo "Current IRIS-web docker-compose file version entries:"
grep -n "image:" "$IRIS_COMPOSE_FILE"

exit 0