#!/bin/bash
# Reference: https://github.com/dfir-iris/iris-web/tree/master

set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"

# Step 1: Pre-installation
pre_install "risx-mssp"

# Step 3: Generate passwords if required
if [[ -z "$GENERATE_ALL_PASSWORDS" ]]; then
  read -p "Would you like to generate passwords? [Y/n] (default:no)" ANSWER
  GENERATE_ALL_PASSWORDS=${ANSWER:-n}
fi

if [[ $GENERATE_ALL_PASSWORDS =~ ^[Yy]$ || $GENERATE_ALL_PASSWORDS =~ ^[Yy][Ee][Ss]$ ]]; then
  source "${curr_dir}/libs/passwords.sh"
  generate_passwords_if_required .
fi

####
#find $home_path/resources/risx-mssp -name 'env.*.secret' -type f | xargs -I % cp % .
#find $home_path/resources/risx-mssp -name '*.passwd' -type f | xargs -I % cp % .
#
#generate_passwords_if_required .
#
## Grab ENV vars from secrets
#for file in `ls env.*.secret`
#do
#  # Cut `env.` prefix and `.secret` suffix from the filename
#  var=`echo ${file} | sed -e 's#^env\.##; s#\.secret##'`
#  export ${var}=`cat ${file}`
#done
#
## Replace ENV vars with values in config file
#cat $home_path/resources/risx-mssp/mssp_config.json.envsubst | envsubst > mssp_config.json
#docker compose build
#touch mssp-back.log
#docker compose up -d
#
#cd -
