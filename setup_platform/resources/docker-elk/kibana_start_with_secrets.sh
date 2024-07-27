#!/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

/bin/bash /usr/local/bin/kibana-docker
