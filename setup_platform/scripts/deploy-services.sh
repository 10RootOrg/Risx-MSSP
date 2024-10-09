#!/bin/bash
set -eo pipefail

source libs/main.sh
rsync -a ../resources/default.env ../workdir/.env
define_env ../workdir/.env
define_paths

source libs/prerquiests-check.sh

# Function to deploy the services
deploy_service() {
  local service_name="$1"
  print_with_border "Deploying $service_name"
  bash "${scripts_dir}/apps/${service_name}.sh" "$home_path"
}

for service in "${APPS_TO_INSTALL[@]}"; do
  deploy_service "$service"
done
# Should be the last service to deploy
deploy_service "nginx"

# --- Show endpoints to access the services
MYIP=$(curl -s ifconfig.me)
ENDPOINTS=(
"cyberchef    : https://$MYIP/cyberchef/"
"elk          : https://$MYIP/kibana/"
"iris-web     : https://$MYIP:8443/"
"nightingale  : https://$MYIP/nightingale/"
"portainer    : https://$MYIP/portainer/"
"strelka      : https://$MYIP:8843/"
"timesketch   : https://$MYIP/"
"velociraptor : https://$MYIP/velociraptor"
)
print_green "All the docker services are deployed successfully."
print_with_border "Access the services using below links"
for service in "${APPS_TO_INSTALL[@]}"; do
  for endpoint in "${ENDPOINTS[@]}"; do
    if [[ $endpoint == "$service"* ]]; then
      echo "$endpoint"
    fi
  done
done
