#!/bin/bash
set -eo pipefail

source libs/main.sh
rync -av ../resources/default.env .env
define_env
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

echo "All the docker services are deployed successfully, Access the services using below links"
MYIP=$(curl -s ifconfig.me)

echo "cyberchef    : https://$MYIP/cyberchef"
echo "iris         : https://$MYIP:8443"
echo "kibana       : https://$MYIP/kibana"
echo "nightingale  : https://$MYIP/nightingale"
echo "portainer    : https://$MYIP/portainer"
echo "strelka      : https://$MYIP:8843"
echo "timesketch   : https://$MYIP"
echo "velociraptor : https://$MYIP/velociraptor"
