sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)
#sudo docker image prune -a 
#sudo docker volume prune -a
sudo docker network prune


sudo rm -rf /home/Eleven1978/setup_platform/scripts/strelka
sudo rm -rf /home/Eleven1978/setup_platform/scripts/nginx
sudo rm -rf /home/Eleven1978/setup_platform/scripts/portainer
sudo rm -rf /home/Eleven1978/setup_platform/scripts/docker-elk
sudo rm -rf /home/Eleven1978/setup_platform/scripts/velociraptor-docker
sudo rm -rf /home/Eleven1978/setup_platform/scripts/timesketch
sudo rm -rf /home/Eleven1978/setup_platform/scripts/strelka-ui
sudo rm -rf /home/Eleven1978/setup_platform/scripts/risx-mssp
