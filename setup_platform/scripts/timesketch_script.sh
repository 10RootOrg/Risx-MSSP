#!/bin/bash

. ./_library.sh

#Reference https://timesketch.org/developers/getting-started/
home_path=$1
echo $home_path
mkdir timesketch
cd timesketch
cp $home_path/resources/timesketch/deploy_timesketch.sh .
cp $home_path/resources/timesketch/config.env .
cp $home_path/resources/timesketch/docker-compose.yml . 
sudo chmod 755 deploy_timesketch.sh
sudo ./deploy_timesketch.sh $home_path

