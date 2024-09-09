#!/bin/bash

set -eo pipefail

current_user=$(whoami)
read -p "Enter username for home directory setup (default: $current_user): " username
username=${username:-$current_user}

elk_msg="ELK installation Message"
iris_msg="Iris installation message"
nginx_msg="NGINX installation message"
portainer_msg="Portainer installation Message"
strelka_msg="Strelka installation message"
timesketch_msg="Time Sketch Installation"
velociraptor_msg="Velociraptor installation message"

home_path="/home/$username/setup_platform"
function print_with_border() {
    local input_string="$1"
    local length=${#input_string}
    local border="===================== "
    # Calculate the length of the border
    local border_length=$(( (80 - length - ${#border}) / 2 ))
    # Print the top border
    printf "%s" "$border"
    for ((i=0; i<border_length; i++)); do
        printf "="
    done
    printf " %s " "$input_string"
    for ((i=0; i<border_length; i++)); do
        printf "="
    done
    printf "%s\n" "$border"
}

print_with_border "$timesketch_msg"
sh "${home_path}/scripts/timesketch_script.sh" "$home_path"

print_with_border "$elk_msg"
sh "${home_path}/scripts/kibana_script.sh" "$home_path"

print_with_border "$strelka_msg"
sh "${home_path}/scripts/strelka_script.sh" "$home_path"

print_with_border "$velociraptor_msg"
sh "${home_path}/scripts/velociraptor_script.sh" "$home_path"

print_with_border "$portainer_msg"
sh "${home_path}/scripts/portainer_sript.sh" "$home_path"

print_with_border "$iris_msg"
bash "${home_path}/scripts/iris-web_script.sh" "$home_path"

echo "setting up monitoring"
bash "${home_path}/scripts/monitoring.sh"

# Should be the last service to be deployed
print_with_border "$nginx_msg"
bash "${home_path}/scripts/nginx_script.sh" "$home_path"

echo "All the docker services are deployed successfully, Access the services using below links"
MYIP="<HOSTNAME>"

echo "Portainer    : https://$MYIP/portainer"
echo "iris         : https://$MYIP:8443"
echo "kibana       : https://$MYIP/kibana"
echo "strelka      : https://$MYIP:8843"
echo "timesketch   : https://$MYIP"
echo "velociraptor : https://$MYIP/velociraptor"
