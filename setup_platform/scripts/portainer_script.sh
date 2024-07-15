home_path=$1
mkdir portainer
cd portainer
cp $home_path/resources/portainer/docker-compose.yaml .
sudo docker compose up -d
