#Reference https://github.com/deviantony/docker-elk/tree/main

. ./_library.sh

home_path=$1
if [ -d "docker-elk" -a -d "docker-elk/.git" ]
then
  cd docker-elk
  git pull
else
  git clone  https://github.com/deviantony/docker-elk.git
  cd docker-elk
fi

cp  $home_path/resources/docker-elk/docker-compose.yml .
cp  $home_path/resources/docker-elk/*start_with_secrets.sh .
chmod a+rx,go-w *start_with_secrets.sh

# Replaces direct `cp` for the situation of no secrets exists
find $home_path/resources/docker-elk -name 'env.*.secret' -type f | xargs cp

generate_passwords_if_required .

docker compose up setup
docker compose up -d
