#!/bin/bash
#Reference https://timesketch.org/developers/getting-started/

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "timesketch"

# Step 2: Run the deployment script
sudo workdir="${workdir}" ./deploy_timesketch.sh

print_green_v2 "$service_name deployment started." "Successfully"
