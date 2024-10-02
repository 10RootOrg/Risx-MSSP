home_path=$1
mkdir -p nginx
cd nginx

cp -r $home_path/resources/nginx/.  .

source ./.env

docker compose up -d
