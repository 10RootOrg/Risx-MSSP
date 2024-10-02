sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)
#sudo docker image prune -a
#sudo docker volume prune -a
sudo docker volume rm iris-web_db_data
sudo docker network prune

source .env
# If the username is not defined, then ask user to enter the username
if [ -z "$username" ]; then
  current_user=$(whoami)
  read -p "Enter username for home directory setup (default: $current_user): " username
  username=${username:-$current_user}
fi
scripts_path="/home/$username/setup_platform/scripts"

sudo rm -rf "${scripts_path}/.env"
sudo rm -rf "${scripts_path}/cyberchef"
sudo rm -rf "${scripts_path}/docker-elk"
sudo rm -rf "${scripts_path}/iris-web"
sudo rm -rf "${scripts_path}/nginx"
sudo rm -rf "${scripts_path}/nightingale"
sudo rm -rf "${scripts_path}/portainer"
sudo rm -rf "${scripts_path}/strelka"
sudo rm -rf "${scripts_path}/strelka-ui"
sudo rm -rf "${scripts_path}/timesketch"
sudo rm -rf "${scripts_path}/velociraptor"
