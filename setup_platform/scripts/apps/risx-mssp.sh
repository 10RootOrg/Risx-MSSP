#!/bin/bash
# Reference: https://github.com/dfir-iris/iris-web/tree/master

set -e

source "./libs/main.sh"
define_env
define_paths "/Users/kk_sudo/projects/globalDots/10root/Risx-MSSP/setup_platform"
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


# Step 3: Prepare configs

# Step 3.1:  Setup ENV variables
# Replace all existing keys from the .env file to the env variable in the memory (from default.env)
# Read each line from the .env file, ignoring commented lines
grep -v '^#' .env |  grep -v '^\s*$' | while read -r line; do
    # Extract the key from the line
    key=$(echo "$line" | sed -E 's/([^=]+)=.*/\1/')
    # Replace the environment variable with the value from the .env file
    replace_env "${key}"
done

# Step 3.2: Generate config based on the variables
export_env .env
envsubst < mssp_config.json.envsubst > mssp_config.json
unset_env .env
touch mssp-back.log

# Step 4. Start the service
printf "Starting the service...\n"
docker compose up -d --build --force-recreate
print_green_v2 "$service_name deployment started." "Successfully"
