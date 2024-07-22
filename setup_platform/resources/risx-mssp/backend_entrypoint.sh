#!/bin/bash

###
# `FORCE_INIT` not equal to `0`
#   - OR -
# `${INIT_CHECK_DIR}/init_done` file do not exists
##
set -x
if [ "${FORCE_INIT}321" != "0321" -o ! -f "${INIT_CHECK_DIR}/init_done" ]
then
  npm run prod \
    && touch "${INIT_CHECK_DIR}/init_done"
fi

# Grab ENV vars from secrets
cd /run/secrets/
for file in `ls env.*.secret`
do
  # Cut `env.` prefix and `.secret` suffix from the filename
  var=${${file#env.}%.secret}
  export ${var}=`cat ${file}`
done
cd -

npm run start
