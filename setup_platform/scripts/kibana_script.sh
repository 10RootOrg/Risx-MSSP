# Define `ELK_PASSWORD_GENERATOR` environment variable and make sure you have `apg` installed
#   to generate required passwords automatically
#Reference https://github.com/deviantony/docker-elk/tree/main

. ./_library.sh

home_path=$1
git clone  https://github.com/deviantony/docker-elk.git
cd docker-elk
cp  $home_path/resources/docker-elk/docker-compose.yml .
cp  $home_path/resources/docker-elk/env.*.secret .

generate_passwords_if_required $home_path/resources/docker-elk

sudo docker compose up setup
sudo docker compose up -d
