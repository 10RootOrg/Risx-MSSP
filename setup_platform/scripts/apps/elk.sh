#!/bin/bash
#Reference https://github.com/deviantony/elk/tree/main
###
# TODO:Why do we need to build ELK from the source code instead of using the official Docker image?
###
# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# App specific variables
ELK_GIT_COMMIT=${ELK_GIT_COMMIT:-"629aea49616ae8a4184b5e68da904cb88e69831d"}

# Step 0: Clone only the specific commit "629aea4" from the repository
# TODO: Actually it's not really good approach to prepare an environment for the ELK stack. Use local files and prebuild images instead.
printf "Cloning the repository and checking out commit %s...\n" "$ELK_GIT_COMMIT"
# If the target dir is not empty asks for the user confirmation to delete the content or exit 1 with error
if [ -d "${workdir}"/elk ]; then
    print_red "The directory ${workdir}/elk already exists. Please remove it before running the script."
    print_red "You can run the following command to remove the directory:"
    print_yellow "./cleanup.sh --app elk"
    exit 1
fi
git clone --branch main --single-branch --depth 1 https://github.com/deviantony/docker-elk.git "${workdir}"/elk
cd "${workdir}"/elk
git fetch --depth 1 origin "$ELK_GIT_COMMIT"
git checkout "$ELK_GIT_COMMIT"

# Step 1: Pre-installation
pre_install "elk"

# Step 1.1:  Setup ENV variables
# Replace all existing keys from the .env file to the env variable in the memory (from default.env)
# input: BEATS_SYSTEM_PASSWORD=
# Output: BEATS_SYSTEM_PASSWORD=$BEATS_SYSTEM_PASSWORD
# Read each line from the .env file, ignoring commented lines
grep -v '^#' .env | while read -r line; do
    # Extract the key from the line
    key=$(echo "$line" | sed -E 's/(.*)=.*/\1/')
    # Replace the environment variable with the value from the .env file
    replace_env "${key}"
done
replace_env "ELASTIC_VERSION"

# Step 2: Use Docker Compose to bring up the setup service and then the rest of the services in detached mode
printf "Starting up the setup service...\n"
sudo docker compose up setup

printf "Starting the service...\n"
sudo docker compose up -d

# Step 3: Import all dashboards to Kibana
printf "Waiting for Kibana to be ready...\n"
sleep 10
while ! docker compose exec kibana curl -s -u "${KIBANA_SYSTEM_USER}":"${KIBANA_SYSTEM_PASSWORD}" http://localhost:5601/api/status | grep -q '"overall":{"level":"available","summary":"All services and plugins are available"}'; do
  printf "Sleeping 5; Still waiting for Kibana to be ready...\n"
  sleep 5
done

# Explaining the command below:
# Import all dashboards to the Kibana
#for file in /usr/share/kibana/dashboards/*.ndjson; do
#  echo "Importing $file"
#  curl -s -X POST -H 'kbn-xsrf: true' -H "securitytenant: global" \
#    http://localhost:5601/api/saved_objects/_import?overwrite=true --form \
#    file=@"$file"
#done
docker compose exec kibana /bin/bash -c \
"for file in /usr/share/kibana/dashboards/*.ndjson; do echo \"Importing \$file\"; curl -s -X POST -H 'kbn-xsrf: true' -u ${KIBANA_SYSTEM_USER}:${KIBANA_SYSTEM_PASSWORD} -H \"securitytenant: global\" http://localhost:5601/api/saved_objects/_import?overwrite=true --form file=@\"\$file\"; done"

printf "\n"
print_with_border "Kibana credentials"
printf "User: %s\n" "${KIBANA_SYSTEM_USER}"
printf "Password: %s\n" "${KIBANA_SYSTEM_PASSWORD}"
print_green_v2 "$service_name deployment started." "Successfully"
