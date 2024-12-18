#!/bin/bash
# Copyright 2020 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

START_CONTAINER=

if [ "$1" == "--start-container" ]; then
  START_CONTAINER=yes
fi

# Exit early if run as non-root user.
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script need to run as root."
  exit 1
fi

# Exit early if a timesketch directory already exists.
if [ -d "./timesketch" ]; then
  echo "ERROR: Timesketch directory already exist."
  echo "You can run the following command to remove the directory:"
  echo "./cleanup.sh --app timesketch"
  exit 1
fi

# Exit early if there are Timesketch containers already running.
if [ ! -z "$(docker ps | grep timesketch)" ]; then
  echo "ERROR: Timesketch containers already running."
  echo "You can run the following command to remove the directory:"
  echo "./cleanup.sh --app timesketch"
  exit 1
fi

# Tweak for OpenSearch
echo "* Setting vm.max_map_count for Elasticsearch"
sysctl -q -w vm.max_map_count=262144
if [ -z "$(grep vm.max_map_count /etc/sysctl.conf)" ]; then
  echo "vm.max_map_count=262144" >>/etc/sysctl.conf
fi

# Create dirs
mkdir -p timesketch/{data/postgresql,data/opensearch,logs,etc,etc/timesketch,etc/timesketch/sigma/rules,upload}
# TODO: Switch to named volumes instead of host volumes.
chown 1000 timesketch/data/opensearch

echo -n "* Setting default config parameters.."
POSTGRES_USER="timesketch"
POSTGRES_PASSWORD="$(
  tr </dev/urandom -dc A-Za-z0-9 | head -c 32
  echo
)"
POSTGRES_ADDRESS="postgres"
POSTGRES_PORT=5432
SECRET_KEY="$(
  tr </dev/urandom -dc A-Za-z0-9 | head -c 32
  echo
)"
OPENSEARCH_ADDRESS="opensearch"
OPENSEARCH_PORT=9200
OPENSEARCH_MEM_USE_GB=$(cat /proc/meminfo | grep MemTotal | awk '{printf "%.0f", ($2 / (1024 * 1024) / 2)}')
REDIS_ADDRESS="redis"
REDIS_PORT=6379
GITHUB_COMMIT="20240828"
GITHUB_BASE_URL="https://raw.githubusercontent.com/google/timesketch/${GITHUB_COMMIT}"
echo "OK"
echo "* Setting OpenSearch memory allocation to ${OPENSEARCH_MEM_USE_GB}GB"

# Docker compose and configuration
echo -n "* Fetching configuration files.."
mv docker-compose.yml timesketch/docker-compose.yml
mv config.env timesketch/config.env

# Fetch default Timesketch config files
curl -s $GITHUB_BASE_URL/data/context_links.yaml >timesketch/etc/timesketch/context_links.yaml
curl -s $GITHUB_BASE_URL/data/generic.mappings >timesketch/etc/timesketch/generic.mappings
curl -s $GITHUB_BASE_URL/data/intelligence_tag_metadata.yaml >timesketch/etc/timesketch/intelligence_tag_metadata.yaml
curl -s $GITHUB_BASE_URL/data/ontology.yaml >timesketch/etc/timesketch/ontology.yaml
curl -s $GITHUB_BASE_URL/data/plaso.mappings >timesketch/etc/timesketch/plaso.mappings
curl -s $GITHUB_BASE_URL/data/plaso_formatters.yaml >timesketch/etc/timesketch/plaso_formatters.yaml
curl -s $GITHUB_BASE_URL/data/regex_features.yaml >timesketch/etc/timesketch/regex_features.yaml
curl -s $GITHUB_BASE_URL/data/sigma/rules/lnx_susp_zmap.yml >timesketch/etc/timesketch/sigma/rules/lnx_susp_zmap.yml
curl -s $GITHUB_BASE_URL/data/sigma_config.yaml >timesketch/etc/timesketch/sigma_config.yaml
curl -s $GITHUB_BASE_URL/data/sigma_rule_status.csv >timesketch/etc/timesketch/sigma_rule_status.csv
curl -s $GITHUB_BASE_URL/data/timesketch.conf >timesketch/etc/timesketch/timesketch.conf
curl -s $GITHUB_BASE_URL/data/winevt_features.yaml >timesketch/etc/timesketch/winevt_features.yaml

# Replace the original tagger
GITHUB_COMMIT_blueteam0ps=${GITHUB_COMMIT_blueteam0ps:-"07d4df90d8686b8379f97c5755dd9ebe5f534ca9"} # Default to the latest commit
GITHUB_URL_blueteam0ps="https://raw.githubusercontent.com/blueteam0ps/AllthingsTimesketch/${GITHUB_COMMIT_blueteam0ps}"
curl -o timesketch/etc/timesketch/tags.yaml -s "${GITHUB_URL_blueteam0ps}"/tags.yaml

# TODO: we don't use an nginx on this level
#curl -s $GITHUB_BASE_URL/contrib/nginx.conf > timesketch/etc/nginx.conf
echo "OK"

# Create a minimal Timesketch config
echo -n "* Edit configuration files.."
sed -i 's#SECRET_KEY = \x27\x3CKEY_GOES_HERE\x3E\x27#SECRET_KEY = \x27'$SECRET_KEY'\x27#' timesketch/etc/timesketch/timesketch.conf

# Set up the Elastic connection
sed -i 's#^OPENSEARCH_HOST = \x27127.0.0.1\x27#OPENSEARCH_HOST = \x27'$OPENSEARCH_ADDRESS'\x27#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^OPENSEARCH_PORT = 9200#OPENSEARCH_PORT = '$OPENSEARCH_PORT'#' timesketch/etc/timesketch/timesketch.conf

# Set up the Redis connection
sed -i 's#^UPLOAD_ENABLED = False#UPLOAD_ENABLED = True#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^UPLOAD_FOLDER = \x27/tmp\x27#UPLOAD_FOLDER = \x27/usr/share/timesketch/upload\x27#' timesketch/etc/timesketch/timesketch.conf

sed -i 's#^CELERY_BROKER_URL =.*#CELERY_BROKER_URL = \x27redis://'$REDIS_ADDRESS':'$REDIS_PORT'\x27#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^CELERY_RESULT_BACKEND =.*#CELERY_RESULT_BACKEND = \x27redis://'$REDIS_ADDRESS':'$REDIS_PORT'\x27#' timesketch/etc/timesketch/timesketch.conf

# Set up the Postgres connection
sed -i 's#postgresql://<USERNAME>:<PASSWORD>@localhost#postgresql://'$POSTGRES_USER':'$POSTGRES_PASSWORD'@'$POSTGRES_ADDRESS':'$POSTGRES_PORT'#' timesketch/etc/timesketch/timesketch.conf

sed -i 's#^POSTGRES_PASSWORD=#POSTGRES_PASSWORD='$POSTGRES_PASSWORD'#' timesketch/config.env
sed -i 's#^OPENSEARCH_MEM_USE_GB=#OPENSEARCH_MEM_USE_GB='$OPENSEARCH_MEM_USE_GB'#' timesketch/config.env

ln -s ./config.env ./timesketch/.env
echo "OK"
echo "* PRE Installation done."

source ./timesketch/.env
if [ -z $START_CONTAINER ]; then
  read -p "Would you like to start the containers? [Y/n] (default:no)" START_CONTAINER
fi

cd timesketch
if [ "$START_CONTAINER" != "${START_CONTAINER#[Yy]}" ]; then # this grammar (the #[] operator) means that the variable $start_cnt where any Y or y in 1st position will be dropped if they exist.
  docker compose up -d
  echo "sleep 5..."
  sleep 5
else
  echo
  echo "You have chosen not to start the containers,"
  echo "if you wish to do so later, you can start timesketch container as below"
  echo
  echo "Start the system:"
  echo "1. cd timesketch"
  echo "2. docker compose up -d"
  echo "3. docker compose exec timesketch-web tsctl create-user <USERNAME>"
  echo
  echo "WARNING: The server is running without encryption."
  echo "Follow the instructions to enable SSL to secure the communications:"
  echo "https://github.com/google/timesketch/blob/master/docs/Installation.md"
  echo
  echo
  exit
fi

# If CREATE_USER is not defined, then ask user to create a new user
if [ -z "${CREATE_USER}" ]; then
  read -p "Would you like to create a new timesketch user? [Y/n] (default:no)" CREATE_USER
fi

if [ "$CREATE_USER" != "${CREATE_USER#[Yy]}" ]; then
  if [ -z "${NEWUSERNAME}" ]; then
    read -p "Please provide a new username: " NEWUSERNAME
  fi
  if [ -z "${NEWUSERNAME_PASSWORD}" ]; then
    NEWUSERNAME_PASSWORD="$(
      tr </dev/urandom -dc A-Za-z0-9 | head -c 32
      echo
    )"
  fi
  sleep 10

  docker compose exec timesketch-web tsctl create-user "$NEWUSERNAME" --password "${NEWUSERNAME_PASSWORD}" \
  && echo "New user has been created"
  echo "############################################"
  echo "### User created: $NEWUSERNAME"
  echo "### Password: $NEWUSERNAME_PASSWORD"
  echo "############################################"
  
  echo "### Autogenerated by TIMESKETCH scripts ###" >> "${workdir}/.env"
  echo "TIMESKETCH_USERNAME=$NEWUSERNAME" >> "${workdir}/.env"
  echo "TIMESKETCH_PASSWORD=$NEWUSERNAME_PASSWORD" >> "${workdir}/.env"
fi

echo "############################################"
echo "Creating a username for importing data"
echo "############################################"
docker compose exec timesketch-web tsctl create-user "${IMPORT_USER_NAME}" --password "${IMPORT_USER_PASSWORD}" \
&& echo "New user has been created"

# TASK-8911: auto analyzers run
CONFIG_FILE=etc/timesketch/timesketch.conf
DEFAULT_ANALYZERS='["feature_extraction","sessionizer","geo_ip_maxmind_db","browser_search","domain","phishy_domains","sigma","hashr_lookup","evtx_gap","chain","ssh_sessionizer","ssh_bruteforce_sessionizer","web_activity_sessionizer","similarity_scorer","win_crash","browser_timeframe","safebrowsing","gcp_servicekey","gcp_logging","misp_analyzer","hashlookup_analyzer"]'

ANALYZERS="${TIMESKETCH_ANALYZERS:-$DEFAULT_ANALYZERS}"

# Update the AUTO_SKETCH_ANALYZERS line if it exists
sudo sed -i "/^AUTO_SKETCH_ANALYZERS = / c\AUTO_SKETCH_ANALYZERS = $ANALYZERS" "$CONFIG_FILE"

# Add the AUTO_SKETCH_ANALYZERS line if it does not exist
if ! sudo grep -q '^AUTO_SKETCH_ANALYZERS = ' "$CONFIG_FILE"; then
  echo "AUTO_SKETCH_ANALYZERS does not exist in the config file. Adding it."
  echo "AUTO_SKETCH_ANALYZERS = $ANALYZERS" | sudo tee -a "$CONFIG_FILE"
fi

echo "############################################"
echo "### Starting the Timesketch container ###"
docker compose restart timesketch-web
docker compose restart timesketch-web-legacy
docker compose restart timesketch-worker
echo "############################################"
