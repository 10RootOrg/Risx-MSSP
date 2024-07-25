#!/usr/bin/env bash

function _list_passwords_from_compose() {
    local workdir=$1

    if [ -e "${workdir}/docker-compose.yml" -o "${workdir}/docker-compose.yaml" ]
    then
      local name=$(ls ${workdir}/docker-compose.* | grep -E 'ya?ml$' | head -n 1)
      echo $(cat ${name} | sed -n 's#.*\(env\..*\.secret\).*#\1#p' | sort | uniq)
    fi
}

function _list_password_files_with_passwords() {
    local workdir=$1

    echo $(find $workdir -type f -not -empty -and -name 'env.*.secret' | xargs basename)
}

function check_password_generator() {
    if [ "${PASSWORD_GENERATOR}123" = "123" ]
    then
      export PASSWORD_GENERATOR="LC_ALL=C tr -dc 'A-Za-z0-9-_!@#$%^&*()+{}[]:;,./?' </dev/urandom | head -c 16"
    fi
}

function generate_password() {
    local workdir=$1

}

function generate_passwords_if_required() {
    local workdir=$1

    declare -a required=($(_list_passwords_from_compose $workdir))
    declare -a existing=($(_list_password_files_with_passwords $workdir))
    # Two matching names means we have the same thing defined in docker-compose.yaml and env secrets
    declare -a defined=($(printf "%s\n%s\n" ${required[@]} ${existing[@]} | sort | uniq -c | sort -rn | grep -E '\s*2' | awk '{print $2}'))
    # Filter out extra env secrets that are not required
    declare -a undefined=($(printf "%s\n%s\n" ${required[@]} ${defined[@]} | sort | uniq -c | sort -rn | grep -E '\s*1' | awk '{print $2}'))
    printf "%s\n" ${undefined[@]}
}

check_password_generator
generate_passwords_if_required ../resources/docker-elk