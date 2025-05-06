#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Copy the stack configs
pre_install "nginx"
replace_envs "${workdir}/${service_name}/.env"

# Step 2: Prepare nginx configs
for app in "${APPS_TO_INSTALL[@]}"; do
  # replace app in the nginx config to include conf.d/$app.conf;, otherwise replace to empty
  if [ -f "etc/nginx/conf.d/$app.conf" ]; then
    sed -i "s/#include conf.d\/$app.conf;/include conf.d\/$app.conf;/g" "etc/nginx/nginx.conf"
  fi
done

# Step 2.1: Generate self sign cert and place to the etc/ssl/private/nginx-selfsigned.key if not exists
if [ ! -f "etc/ssl/private/nginx-selfsigned.key" ]; then
  mkdir -p etc/ssl/private etc/ssl/certs
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout etc/ssl/private/nginx-selfsigned.key \
    -out etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=IL/ST=Tel-Aviv/L=Tel-Aviv/O=10Root/OU=IT Department/CN=localhost"

  # Use dhparam from the git repo
  #openssl dhparam -out etc/ssl/certs/dhparam.pem 2048
fi

# Step 3: Start
printf "Starting the %s service...\n" "$service_name"
source ./.env
docker compose up -d --force-recreate

print_green_v2 "$service_name deployment started" "successfully"
