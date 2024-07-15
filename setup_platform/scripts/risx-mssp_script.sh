home_path=$1
mkdir mysql
cd mysql
cp $home_path/resources/risx-mssp/docker-compose.yaml .
sudo docker compose up -d
