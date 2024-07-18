home_path=$1
mkdir risx-mssp
cd risx-mssp

cp $home_path/resources/risx-mssp/docker-compose.yaml .
cp $home_path/resources/risx-mssp/*.secret .
cp $home_path/resources/risx-mssp/*.passwd .
cp $home_path/resources/risx-mssp/environment.sh .

# Grab ENV vars from secrets
for file in `ls env.*.secret`
do
  # Cut `env.` prefix and `.secret` suffix from the filename
  var=${${file#env.}%.secret}
  export ${var}=`cat ${file}`
done

# Replace ENV vars with values in config file
cat $home_path/resources/risx-mssp/mssp_config.json.envsubst | envsubst > ./mssp_config.json
sudo docker compose up -d
