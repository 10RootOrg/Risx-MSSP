#!/bin/bash
source ../.env

tag_name=${1:-""}

cd "frontend/Code" || { echo "Failed to cd into directory"; exit 1; }

if [ -z "$tag_name" ]; then
    tag_name=$(git tag --sort=-v:refname | head -n 1)
fi

printf "%s\n" "$tag_name"
printf "%s\n" "$RISX_MSSP_BACKEND_FULL_URL"

git checkout -- .
git checkout $tag_name
sed -i -E "s#(\"backendUrl\":\s*\")[^\"]*(\")#\1${RISX_MSSP_BACKEND_FULL_URL}\2#" "public/mssp_config.json"

cd "../../backend/risx-mssp-back" || { echo "Failed to cd into directory"; exit 1; }
git checkout -- .
git checkout $tag_name
  sed -i "s/localhost/${INTERNAL_IP_OF_HOST_MACHINE}/g" "db/seeds/production/config_seed.json"
  sed -i "s/importing/${TIMESKETCH_PASSWORD}/g" "db/seeds/production/config_seed.json"
  sed -i "s/import/${TIMESKETCH_USERNAME}/g" "db/seeds/production/config_seed.json"


cd "../python-scripts" || { echo "Failed to cd into directory"; exit 1; }
git checkout -- .
git checkout $tag_name
printf "All repositories have been updated to %s\n" "$tag_name"

