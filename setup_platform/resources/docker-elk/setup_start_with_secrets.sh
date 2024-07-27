#!/bin/bash

cd /run/secrets
for file in `ls`
do
  export ${file}=`cat ${file}`
done
cd -

if [ -f /init/init.done ]
then
  echo "Skipping setup step, it's already done"
  exit 0
else
  /usr/sbin/runuser -u elasticsearch /entrypoint.sh && touch /init/init.done
fi
