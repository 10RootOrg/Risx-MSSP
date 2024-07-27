#!/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

/usr/local/bin/docker-entrypoint
