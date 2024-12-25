#!/bin/bash
# Reference: https://github.com/dfir-iris/iris-web/tree/master

set -eo pipefail

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "risx-mssp"

# Step 2: Generate passwords if required
if [[ -z "$GENERATE_ALL_PASSWORDS" ]]; then
  read -p "Would you like to generate passwords? [Y/n] (default:no)" ANSWER
  GENERATE_ALL_PASSWORDS=${ANSWER:-n}
fi

if [[ $GENERATE_ALL_PASSWORDS =~ ^[Yy]$ || $GENERATE_ALL_PASSWORDS =~ ^[Yy][Ee][Ss]$ ]]; then
  source "${curr_dir}/libs/passwords.sh"
  generate_passwords_if_required .

  # Show login credentials
  echo "##### Autogenerated by $service_name script #####" | tee -a "$workdir/.env"
  echo "DEHASHED_U=$(cat env.DEHASHED_U.secret)" | tee -a "$workdir/.env"
  echo "SHORESH_PASSWD=$(cat shoresh.passwd)" | tee -a "$workdir/.env"
  echo "############## END $service_name #################" | tee -a "$workdir/.env"
fi

# Step 4: Prepare backend
## Step 4.1:  Setup ENV variables
# Read an app level .env file and replace values in the .env file with the default.env values (already in memory)
print_green "Setting up backend ..."
silent=true \
  replace_envs "${workdir}/${service_name}/backend/.env"
export_env "${workdir}/${service_name}/backend/.env"
git clone --branch "${GIT_RISX_BACKEND_BRANCH}" "${GIT_RISX_BACKEND_URL}" risx-mssp-back
mkdir -p backend/risx-mssp-back
rsync -avh --progress --exclude=".git" risx-mssp-back/ backend/risx-mssp-back/
rm -rf risx-mssp-back
# Workaround for attached volumes
mkdir -p backend/logs/node backend/logs/python-scripts
touch backend/logs/node/msspBack.log
chown -R 1000:1000 backend/logs
mkdir -p backend/init_check && chown 1000:1000 backend/init_check && chmod -R 777 backend/init_check

## Step 4.2: Clone PYTHON repo to the frontend
print_green "Setting up backend python ..."
git clone --branch "${GIT_RISX_PY_BRANCH}" "${GIT_RISX_PY_URL}" risx-mssp-python
rsync -avh --progress --exclude=".git" risx-mssp-python/ backend/python-scripts/
rm -rf risx-mssp-python
# TODO: N.B.: Duty workaround to add secret to the env file for the PYTHON script
rsync backend/.env backend/risx-mssp-back/.env
echo "DATABASE_PASSWORD=$(cat shoresh.passwd)" >> backend/risx-mssp-back/.env

# Step 5: Prepare frontend
## Step 5.1: Generate config based on the variables
print_green "Setting up frontend ..."
silent=true \
  replace_envs "${workdir}/${service_name}/frontend/.env"
export_env "${workdir}/${service_name}/frontend/.env"
git clone --branch "${GIT_RISX_FRONTEND_BRANCH}" "${GIT_RISX_FRONTEND_URL}" risx-mssp-front
rsync -avh --progress --exclude=".git" risx-mssp-front/ frontend/
rm -rf risx-mssp-front

jq --arg backendUrl "$RISX_MSSP_BACKEND_FULL_URL" --arg expiryDate "$RISX_MSSP_FE_EXPIRY_DATE" \
'.backendUrl = $backendUrl | .expiryDate = $expiryDate' frontend/public/mssp_config.json > frontend/mssp_config.json
# TODO: Clarify the dst path of the config
#rsync frontend/mssp_config.json frontend/public/mssp_config.json


#unset_env frontend/.env

# Step 6. Start the service
# Step 6.1 Check related dirs
if [[ ! -d "${workdir}/velociraptor/velociraptor/clients" ]]; then
  print_red "Velociraptor clients directory not found. Please run the velociraptor script first."
  exit 1
fi
# Step 6.2: Start the services
print_green "Starting the services..."
docker compose up -d --build --force-recreate
# Step 6.3: Clean up
rm -rf backend/python-scripts backend/risx-mssp-back

print_green_v2 "$service_name deployment started." "Successfully"
