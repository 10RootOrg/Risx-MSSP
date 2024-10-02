#!/bin/bash
#Reference https://github.com/deviantony/docker-elk/tree/main
###
# TODO:Why do we need to build ELK from the source code instead of using the official Docker image?
###
# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
ELK_GIT_COMMIT=${ELK_GIT_COMMIT:-"629aea49616ae8a4184b5e68da904cb88e69831d"}
# Step 1: Clone only the specific commit "629aea4" from the repository
printf "Cloning the repository and checking out commit %s...\n" "$ELK_GIT_COMMIT"
git clone --branch main --single-branch --depth 1 https://github.com/deviantony/docker-elk.git
cd docker-elk
git fetch --depth 1 origin "$ELK_GIT_COMMIT"
git checkout "$ELK_GIT_COMMIT"

# Step 2: Copy the docker-compose.yml file from the specified home_path
printf "Copying ELK files from %s...\n" "$home_path"
cp -Rf "${home_path}"/resources/docker-elk/* .

# Step 3: Use Docker Compose to bring up the setup service and then the rest of the services in detached mode
printf "Bringing up the setup service...\n"
sudo docker compose up setup

printf "Bringing up the rest of the services in detached mode...\n"
sudo docker compose up -d

# Step 4: Import all dashboards to Kibana
printf "Waiting 30 sec for Kibana to be ready...\n"
sleep 30
# Import all dashboards to the Kibana
#for file in /usr/share/kibana/dashboards/*.ndjson; do
#  echo "Importing $file"
#  curl -s -X POST -H 'kbn-xsrf: true' -H "securitytenant: global" \
#    http://localhost:5601/api/saved_objects/_import?overwrite=true --form \
#    file=@"$file"
#done
docker exec -it kibana /bin/bash -c "for file in /usr/share/kibana/dashboards/*.ndjson; do echo \"Importing \$file\"; curl -s -X POST -H 'kbn-xsrf: true' -H \"securitytenant: global\" http://localhost:5601/api/saved_objects/_import?overwrite=true --form file=@\"\$file\"; done"

printf "\n###\nKibana(ELK) deployment completed successfully.\n###\n"
