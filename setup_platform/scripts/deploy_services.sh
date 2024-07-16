#!/bin/bash

read -p "Enter username : " username

timesketch_msg="Time Sketch Installation"
elk_msg="ELK installation Message"
portainer_msg="Portainer installation Message"
strelka_msg="Strelka installation message"
velociraptor_msg="Velociraptor installation message"
nginx_msg="NGINX installation message"

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
sh $home_path/scripts/timesketch_script.sh $home_path

print_with_border "$elk_msg"
sh $home_path/scripts/kibana_script.sh $home_path

print_with_border "$strelka_msg"
sh $home_path/scripts/strelka_script.sh $home_path

print_with_border "$velociraptor_msg"
sh $home_path/scripts/velociraptor_script.sh $home_path

print_with_border "$portainer_msg"
sh $home_path/scripts/portainer_script.sh $home_path

print_with_border "$nginx_msg"
sh $home_path/scripts/nginx_script.sh $home_path

echo "setting up monitoring"
bash $home_path/scripts/monitoring.sh

echo "All the docker services are deployed successfuly, Access the services using below links"
echo "Portainer    : https://ip/portainer"
echo "velociraptor : https://ip/velociraptor"
echo "timesketch   : http://ip"
echo "kibana       : http://ip/kibana"
echo "strelka      : http://ip/strelka"
