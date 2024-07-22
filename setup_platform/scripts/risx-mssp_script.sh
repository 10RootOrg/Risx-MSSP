home_path=$1
mkdir -p risx-mssp
cd risx-mssp

cp $home_path/resources/risx-mssp/docker-compose.yaml .
cp $home_path/resources/risx-mssp/*.Dockerfile .
cp $home_path/resources/risx-mssp/*.secret .
cp $home_path/resources/risx-mssp/*.passwd .
cp $home_path/resources/risx-mssp/environment.sh .
cp $home_path/resources/risx-mssp/backend_entrypoint.sh .
cp $home_path/resources/risx-mssp/permissions.sql .
cp $home_path/resources/risx-mssp/nginx_default.conf.template .

# Grab ENV vars from secrets
for file in `ls env.*.secret`
do
  # Cut `env.` prefix and `.secret` suffix from the filename
  var=`echo ${file} | sed -e 's#^env\.##; s#\.secret##'`
  export ${var}=`cat ${file}`
done

# Replace ENV vars with values in config file
cat $home_path/resources/risx-mssp/mssp_config.json.envsubst | envsubst > ./mssp_config.json
docker compose up -d
