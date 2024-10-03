#!/bin/bash
set -eo pipefail

cp ../resources/default.env .env
source .env
source libs/main.sh
source libs/prerquiests-check.sh

# If the username is not defined, then ask user to enter the username
if [ -z "$username" ]; then
  current_user=$(whoami)
  read -p "Enter username for home directory setup (default: $current_user): " username
  username=${username:-$current_user}
fi
home_path=${home_path:-"/home/$username/setup_platform"}

print_with_border() {
  local input_string="$1"
  local length=${#input_string}
  local border="===================== "
  # Calculate the length of the border
  local border_length=$(((80 - length - ${#border}) / 2))
  # Print the top border
  printf "%s" "$border"
  for ((i = 0; i < border_length; i++)); do
    printf "="
  done
  printf " %s " "$input_string"
  for ((i = 0; i < border_length; i++)); do
    printf "="
  done
  printf "%s\n" "$border"
}

# Function to deploy the services
deploy_service() {
  local service_name="$1"
  print_with_border "Deploying $service_name"
  bash "${home_path}/scripts/apps/${service_name}.sh" "$home_path"
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
