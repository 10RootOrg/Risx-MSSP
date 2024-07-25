#!/usr/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

env

/bin/tini -- /usr/local/bin/docker-entrypoint.sh
