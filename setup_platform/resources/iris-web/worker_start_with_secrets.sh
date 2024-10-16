#!/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -
env
bash -c "/iriswebapp/wait-for-iriswebapp.sh app:8000 /iriswebapp/iris-entrypoint.sh iris-worker"
