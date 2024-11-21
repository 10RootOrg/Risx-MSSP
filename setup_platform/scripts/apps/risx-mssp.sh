#!/bin/bash

. ./_library.sh

home_path=$1
mkdir -p risx-mssp
cd risx-mssp

cp $home_path/resources/risx-mssp/docker-compose.yaml .
cp $home_path/resources/risx-mssp/*.Dockerfile .
cp $home_path/resources/risx-mssp/environment.sh .
cp $home_path/resources/risx-mssp/backend_entrypoint.sh .
cp $home_path/resources/risx-mssp/permissions.sql .
cp $home_path/resources/risx-mssp/nginx_default.conf.template .

find $home_path/resources/risx-mssp -name 'env.*.secret' -type f | xargs -I % cp % .
find $home_path/resources/risx-mssp -name '*.passwd' -type f | xargs -I % cp % .

generate_passwords_if_required .

# Grab ENV vars from secrets
for file in `ls env.*.secret`
do
  # Cut `env.` prefix and `.secret` suffix from the filename
  var=`echo ${file} | sed -e 's#^env\.##; s#\.secret##'`
  export ${var}=`cat ${file}`
done

# Replace ENV vars with values in config file
cat $home_path/resources/risx-mssp/mssp_config.json.envsubst | envsubst > mssp_config.json
docker compose build
touch mssp-back.log
docker compose up -d

cd -
