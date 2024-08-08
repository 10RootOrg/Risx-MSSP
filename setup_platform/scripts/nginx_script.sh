#!/bin/bash

. ./_library.sh

home_path=$1
mkdir nginx
cd nginx
cp -r $home_path/resources/nginx/.  .
docker compose up -d
