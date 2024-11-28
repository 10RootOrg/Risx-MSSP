#!/bin/bash
# Reference: https://github.com/dfir-iris/iris-web/tree/master

set -e

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
silient=true \
  replace_envs "${workdir}/${service_name}/backend/.env"
export_env "${workdir}/${service_name}/backend/.env"
git clone --branch "${GIT_RISX_BACKEND_BRANCH}" "${GIT_RISX_BACKEND_URL}" risx-mssp-back
rsync -avh --progress --exclude=".git" risx-mssp-back/ backend/
rm -rf risx-mssp-back
touch backend/mssp-back.log

## Step 4.2: Clone python repo to the frontend
print_green "Setting up backend python ..."
git clone --branch "${GIT_RISX_PY_BRANCH}" "${GIT_RISX_PY_URL}" risx-mssp-python
rsync -avh --progress --exclude=".git" risx-mssp-python/ backend/python-scripts/
rm -rf risx-mssp-python
#unset_env backend/.env

# Step 5: Prepare frontend
## Step 5.1: Generate config based on the variables
print_green "Setting up frontend ..."
silient=true \
  replace_envs "${workdir}/${service_name}/frontend/.env"
export_env "${workdir}/${service_name}/frontend/.env"
git clone --branch "${GIT_RISX_FRONTEND_BRANCH}" "${GIT_RISX_FRONTEND_URL}" risx-mssp-front
rsync -avh --progress --exclude=".git" risx-mssp-front/ frontend/
rm -rf risx-mssp-front
envsubst < frontend/mssp_config.json.envsubst > frontend/mssp_config.json
#unset_env frontend/.env

# Step 6. Start the service
print_green "Starting the services..."
docker compose up -d --build --force-recreate
print_green_v2 "$service_name deployment started." "Successfully"
