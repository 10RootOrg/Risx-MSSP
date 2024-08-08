#!/bin/bash

. ./_library.sh

#Reference https://github.com/Velocidex/velociraptor and https://github.com/weslambert/velocistack
home_path=$1
git clone https://github.com/weslambert/velociraptor-docker
cd velociraptor-docker
cp $home_path/resources/velociraptor/docker-compose.yaml .
cp $home_path/resources/velociraptor/entrypoint .

sudo docker compose build
sudo docker compose up -d
sleep 5

sudo chmod 777 -R $home_path/scripts/velociraptor-docker/velociraptor
sudo chmod 777 -R $home_path/scripts/velociraptor-docker/velociraptor/clients
cd velociraptor
cp -R $home_path/resources/velociraptor/custom/ .
sudo docker restart velociraptor
