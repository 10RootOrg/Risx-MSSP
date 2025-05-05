#!/bin/bash

# Script to update version variables in Timesketch config.env file
# The script will read version values from the main .env file
# Usage: ./update_timesketch_versions.sh [component] [new_version]
# If no component is specified, script will list available components
# If no version is provided, it will use the version from the main .env file
# Example: ./update_timesketch_versions.sh timesketch 20240829

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
TIMESKETCH_CONFIG_FILE="/home/${CURRENT_USER}/setup_platform/resources/timesketch/config.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Define components and their corresponding variables
declare -A COMPONENTS=(
    ["timesketch"]="TIMESKETCH_VERSION:TIMESKETCH_VERSION"
    ["opensearch"]="OPENSEARCH_VERSION:TIMESKETCH_OPENSEARCH_VERSION"
    ["postgres"]="POSTGRES_VERSION:TIMESKETCH_POSTGRES_VERSION"
    ["redis"]="REDIS_VERSION:TIMESKETCH_REDIS_VERSION"
    ["nginx"]="NGINX_VERSION:TIMESKETCH_NGINX_VERSION"
    ["all"]="all:all"
)

# Function to check if files exist
check_files_exist() {
    # Check Timesketch config file
    if [ ! -f "$TIMESKETCH_CONFIG_FILE" ]; then
        echo "Error: Timesketch configuration file not found at $TIMESKETCH_CONFIG_FILE"
        exit 1
    else
        echo "Found Timesketch configuration file at $TIMESKETCH_CONFIG_FILE"
    fi
    
    # Check main env file
    if [ ! -f "$MAIN_ENV_FILE" ]; then
        echo "Error: Main configuration file not found at $MAIN_ENV_FILE"
        exit 1
    else
        echo "Found main configuration file at $MAIN_ENV_FILE"
    fi
}

# Function to read a version from the main .env file
get_version_from_main_env() {
    local var_name=$1
    
    if [ -f "$MAIN_ENV_FILE" ]; then
        local version=$(grep "${var_name}=" "$MAIN_ENV_FILE" | cut -d'=' -f2)
        if [ -z "$version" ]; then
            echo "Warning: ${var_name} not found in $MAIN_ENV_FILE" >&2
            return 1
        else
            echo "Found ${var_name}=$version in main .env file" >&2
            # Only output the actual version value to stdout
            echo "$version"
            return 0
        fi
    else
        echo "Error: Main .env file not found" >&2
        return 1
    fi
}

# Function to update a specific component version
update_component_version() {
    local component=$1
    local new_version=$2
    
    # Check if component is valid
    if [[ ! ${COMPONENTS[$component]} ]]; then
        echo "Error: Invalid component '$component'."
        list_components
        exit 1
    fi
    
    # Parse component config
    IFS=':' read -r var_name main_env_var <<< "${COMPONENTS[$component]}"
    
    # If "all" is selected, update all components
    if [ "$component" == "all" ]; then
        update_all_components "$new_version"
        return $?
    fi
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        main_version=$(get_version_from_main_env "$main_env_var")
        if [ -n "$main_version" ]; then
            echo "No version specified, using $main_env_var from main .env: $main_version"
            new_version="$main_version"
        else
            echo "Error: No version specified and couldn't get $main_env_var from main .env"
            echo "Usage: ./update_timesketch_versions.sh $component [new_version]"
            exit 1
        fi
    fi
    
    # Get current version for logging
    current_version=$(grep "^${var_name}=" "$TIMESKETCH_CONFIG_FILE" | cut -d'=' -f2)
    
    # Use sed to update the version
    if sed -i "s/^${var_name}=.*/${var_name}=$new_version/" "$TIMESKETCH_CONFIG_FILE"; then
        echo "Success: $component version ($var_name) updated from $current_version to $new_version"
        return 0
    else
        echo "Error: Failed to update $component version"
        return 1
    fi
}

# Function to list available components
list_components() {
    echo "Available components to update:"
    for comp in "${!COMPONENTS[@]}"; do
        if [ "$comp" != "all" ]; then
            IFS=':' read -r var_name _ <<< "${COMPONENTS[$comp]}"
            echo "  - $comp (Updates $var_name)"
        fi
    done
    echo "  - all (Updates all components)"
    echo ""
    echo "Usage: ./update_timesketch_versions.sh [component] [new_version]"
    echo "Example: ./update_timesketch_versions.sh timesketch 20240829"
}

# Function to update all components
update_all_components() {
    local new_version=$1
    local had_errors=0
    
    echo "Updating all Timesketch components..."
    for comp in "${!COMPONENTS[@]}"; do
        if [ "$comp" != "all" ]; then
            echo "-------------------------------------"
            echo "Updating $comp component..."
            # If no version provided, we let the individual component function 
            # handle getting from main .env by passing empty string
            if ! update_component_version "$comp" "$new_version"; then
                had_errors=1
            fi
        fi
    done
    
    if [ $had_errors -eq 1 ]; then
        echo "-------------------------------------"
        echo "Warning: Some components could not be updated. Please check the errors above."
        return 1
    else
        echo "-------------------------------------"
        echo "All Timesketch components updated successfully!"
        return 0
    fi
}

# Main execution
check_files_exist

# If no arguments provided, update all components
if [ $# -eq 0 ]; then
    update_all_components ""
    exit 0
fi

# Parse command line arguments
component="$1"
version="$2"

# Execute based on arguments
if [[ ${COMPONENTS[$component]} ]]; then
    # Update specific component or all components
    update_component_version "$component" "$version"
    
    # If we just updated a single component, show the result
    if [ "$component" != "all" ]; then
        IFS=':' read -r var_name _ <<< "${COMPONENTS[$component]}"
        echo "-------------------------------------"
        echo "Current $component configuration ($var_name):"
        grep "^$var_name=" "$TIMESKETCH_CONFIG_FILE"
    fi
else
    # Invalid component
    echo "Error: Invalid component '$component'."
    list_components
    exit 1
fi

exit 0