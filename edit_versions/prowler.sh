#!/bin/bash

# Script to update versions for all Prowler modules in .env file
# Usage: ./update_prowler_versions.sh [module] [new_version]
# If no module is specified, script will update all Prowler modules
# If no version is provided, it will use the versions from the main .env file
# Example: ./update_prowler_versions.sh ui latest

# Get the current user
CURRENT_USER=$(whoami)

# Define paths dynamically based on current user
PROWLER_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/prowler/.env"
MAIN_ENV_FILE="/home/${CURRENT_USER}/setup_platform/resources/default.env"

# Define Prowler modules
declare -A MODULES=(
    ["ui"]="PROWLER_UI_VERSION:PROWLER_UI_VERSION"
    ["api"]="PROWLER_API_VERSION:PROWLER_API_VERSION"
)

# Function to check if files exist
check_files_exist() {
    # Check Prowler env file
    if [ ! -f "$PROWLER_ENV_FILE" ]; then
        echo "Error: Prowler configuration file not found at $PROWLER_ENV_FILE"
        exit 1
    else
        echo "Found Prowler configuration file at $PROWLER_ENV_FILE"
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

# Function to update a specific Prowler module version
update_module_version() {
    local module=$1
    local new_version=$2
    
    # Check if module is valid
    if [[ ! ${MODULES[$module]} ]]; then
        echo "Error: Invalid module '$module'. Available modules: ui, api, all"
        exit 1
    fi
    
    # Parse module config
    IFS=':' read -r var_name main_env_var <<< "${MODULES[$module]}"
    
    # Check if version parameter is provided
    if [ -z "$new_version" ]; then
        # If no version specified, use the version from main .env
        main_version=$(get_version_from_main_env "$main_env_var")
        if [ -n "$main_version" ]; then
            echo "No version specified, using $main_env_var from main .env: $main_version"
            new_version="$main_version"
        else
            echo "Error: No version specified and couldn't get $main_env_var from main .env"
            echo "Usage: ./update_prowler_versions.sh $module [new_version]"
            exit 1
        fi
    fi
    
    # Get current version for logging
    current_version=$(grep "$var_name=" "$PROWLER_ENV_FILE" | cut -d'=' -f2 | tr -d '"')
    
    # Use sed to update the version (with quotes)
    if sed -i "s/${var_name}=.*/${var_name}=\"$new_version\"/" "$PROWLER_ENV_FILE"; then
        echo "Success: Prowler $module version updated from $current_version to $new_version"
        return 0
    else
        echo "Error: Failed to update Prowler $module version"
        return 1
    fi
}

# Function to list available modules
list_modules() {
    echo "Available Prowler modules:"
    echo "  - ui   (Updates PROWLER_UI_VERSION)"
    echo "  - api  (Updates PROWLER_API_VERSION)"
    echo "  - all  (Updates all Prowler modules)"
    echo ""
    echo "Usage: ./update_prowler_versions.sh [module] [new_version]"
    echo "Example: ./update_prowler_versions.sh ui latest"
}

# Function to update all Prowler modules
update_all_modules() {
    local new_version=$1
    local had_errors=0
    
    echo "Updating all Prowler modules..."
    for module in "${!MODULES[@]}"; do
        echo "-------------------------------------"
        echo "Updating $module module..."
        if ! update_module_version "$module" "$new_version"; then
            had_errors=1
        fi
    done
    
    if [ $had_errors -eq 1 ]; then
        echo "-------------------------------------"
        echo "Warning: Some modules could not be updated. Please check the errors above."
        return 1
    else
        echo "-------------------------------------"
        echo "All Prowler modules updated successfully!"
        return 0
    fi
}

# Main execution
check_files_exist

# Parse command line arguments
module="$1"
version="$2"

# Execute based on arguments
if [ -z "$module" ] || [ "$module" == "all" ]; then
    # Update all modules
    update_all_modules "$version"
elif [[ ${MODULES[$module]} ]]; then
    # Update specific module
    update_module_version "$module" "$version"
else
    # Invalid module
    echo "Error: Invalid module '$module'."
    list_modules
    exit 1
fi

# Display updated content
echo "-------------------------------------"
echo "Current Prowler versions:"
grep "_VERSION=" "$PROWLER_ENV_FILE" | grep -E "PROWLER_(UI|API)_VERSION"

exit 0