#!/bin/bash

. ./_library.sh

#Reference https://github.com/deviantony/docker-elk/tree/main
home_path=$1
git clone  https://github.com/deviantony/docker-elk.git
cd docker-elk
cp  $home_path/resources/docker-elk/docker-compose.yml .
sudo docker compose up setup
sudo docker compose up -d
