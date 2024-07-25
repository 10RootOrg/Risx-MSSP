#!/usr/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

env

/usr/bin/bash /entrypoint.sh