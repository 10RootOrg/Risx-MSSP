#!/bin/bash

# Script to run all component update scripts
# This will update all component versions based on the values in the main .env file

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Current directory containing all update scripts
SCRIPT_DIR="$(pwd)"

# Counter for successful/failed updates
SUCCESS_COUNT=0
FAILED_COUNT=0
TOTAL_SCRIPTS=0

# Function to run a script and track its success/failure
run_script() {
    local script=$1
    
    if [ -f "$SCRIPT_DIR/$script" ]; then
        echo -e "\n${YELLOW}===================================================${NC}"
        echo -e "${YELLOW}Running $script...${NC}"
        echo -e "${YELLOW}===================================================${NC}"
        
        # Make script executable if it's not already
        chmod +x "$SCRIPT_DIR/$script"
        
        # Run the script
        if "$SCRIPT_DIR/$script"; then
            echo -e "${GREEN}✓ $script executed successfully${NC}"
            ((SUCCESS_COUNT++))
        else
            echo -e "${RED}✗ $script failed with exit code $?${NC}"
            echo -e "${YELLOW}Continuing with the next script...${NC}"
            ((FAILED_COUNT++))
        fi
        
        ((TOTAL_SCRIPTS++))
    else
        echo -e "${RED}Script $script not found in $SCRIPT_DIR${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}Starting bulk update of all components...${NC}"
echo -e "${YELLOW}Reading versions from: ${SCRIPT_DIR}/.env${NC}"

# List of scripts to run (excluding updated_env)
SCRIPTS=(
    "velociraptor.sh"
    "cyberchef.sh"
    "iris.sh"
    "nginx.sh"
    "nightingale.sh"
    "portainer.sh"
    "prowler.sh"
    "strelka.sh"
    "timesketch.sh"
)

# Run each script
for script in "${SCRIPTS[@]}"; do
    run_script "$script"
done

# Print summary
echo -e "\n${YELLOW}===================================================${NC}"
echo -e "${YELLOW}Update Summary${NC}"
echo -e "${YELLOW}===================================================${NC}"
echo -e "Total scripts executed: $TOTAL_SCRIPTS"
echo -e "${GREEN}Successful updates: $SUCCESS_COUNT${NC}"
echo -e "${RED}Failed updates: $FAILED_COUNT${NC}"

if [ $FAILED_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}All component versions updated successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}Some component updates failed. Please check the logs above.${NC}"
    exit 1
fi