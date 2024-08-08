#!/bin/bash

. ./_library.sh

#Reference https://github.com/target/strelka/
home_path=$1
git clone https://github.com/target/strelka-ui.git
cd strelka-ui/ui
sed -i 's/"homepage": "\/"/"homepage": "\/strelka"/g' package.json
if grep -q '"homepage": "/strelka"' package.json; then
     echo "Update homepage successful"
 else
     echo "Update homepage failed"
 fi
cd ..
docker compose build
cd ..

git clone https://github.com/target/strelka.git
cd strelka
cp  $home_path/resources/strelka/docker-compose.yaml build/docker-compose.yaml
docker compose -f build/docker-compose.yaml build && \
docker compose -f build/docker-compose.yaml up -d
