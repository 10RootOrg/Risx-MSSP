#!/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

/bin/tini -- /usr/local/bin/docker-entrypoint.sh
