#!/bin/bash
# Reference: https://github.com/dfir-iris/iris-web/tree/master

# Exit immediately if a command exits with a non-zero status
set -e

# Check if home_path is provided
if [ -z "$1" ]; then
  printf "Usage: %s <home_path>\n" "$0"
  exit 1
fi

home_path=$1
IRIS_GIT_COMMIT=${IRIS_GIT_COMMIT:-"v2.4.10"}
SCRIPTS_PATH=${SCRIPTS_PATH:-"$(pwd)"}

# Step 1: Clone the repository and check out the specific commit
printf "Cloning the repository and checking out commit %s...\n" "$IRIS_GIT_COMMIT"
if [ -d "iris-web" -a -d "iris-web/.git" ]; then
  cd iris-web
  git pull origin "$IRIS_GIT_COMMIT"
else
  git clone https://github.com/dfir-iris/iris-web.git
  cd iris-web
fi
git checkout "$IRIS_GIT_COMMIT"

# Step 2: Copy necessary files from the specified home_path
printf "Copying docker-compose.yml and environment.sh from %s...\n" "$home_path"
cp "$home_path/resources/iris-web/docker-compose.yml" .
cp "$home_path/resources/iris-web/environment.sh" .
cp "${home_path}"/resources/iris-web/*start_with_secrets.sh .
chmod a+rx,go-w *start_with_secrets.sh

# Replaces direct `cp` for the situation of no secrets exists
find "$home_path/resources/iris-web" -name 'env.*.secret' -type f | xargs -I % cp % .

# Replace direct `cp` for the cases with no testcases defined
find "$home_path/resources/iris-web" -name '*_testcase.sh' -type f | xargs -I % cp % .

# Step 3: Generate passwords if required
read -p "Would you like to generate passwords? [Y/n] (default:no)" ANSWER
if [[ $ANSWER =~ ^[Yy]$ ]]; then
  export GENERATE_ALL_PASSWORDS=true
  . "${SCRIPTS_PATH}/libs/passwords.sh"
  # TODO: move out of the scope of the if condition
  generate_passwords_if_required .

  # Show login credentials
  echo "############################################"
  echo "Iris credentials:"
  echo "Username: administrator"
  echo "Password: $(cat env.IRIS_ADM_PASSWORD.secret)"
  echo "############################################"
fi

# Step 4: Build and bring up the services
printf "Building and bringing up the services...\n"
docker compose build
docker compose up -d --force-recreate

printf "IRIS deployment completed successfully.\n"
