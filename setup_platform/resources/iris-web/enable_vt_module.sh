#!/usr/bin/env bash

# Enable VT module via SQL query and setup VT API key
# https://github.com/dfir-iris/iris-vt-module

set -eo pipefail

if ! declare -f container_compose >/dev/null 2>&1; then
  script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
  if [ -f "$script_root/scripts/libs/main.sh" ]; then
    # shellcheck source=setup_platform/scripts/libs/main.sh
    source "$script_root/scripts/libs/main.sh"
  else
    echo "Container helpers are not available. Run this script via the setup tooling." >&2
    exit 1
  fi
fi

if [ -z "$CONTAINER_ENGINE" ] && declare -f initialize_container_runtime >/dev/null 2>&1; then
  initialize_container_runtime
fi

export DB_NAME=${IRIS_DB_NAME:-"iris_db"}
export TABLE_NAME=${IRIS_TABLE_NAME:-"iris_module"}
export MODULE_NAME=${IRIS_MODULE_NAME:-"iris_vt_module"}
export VT_MODULE_API_KEY=${IRIS_VT_MODULE_API_KEY}

# Function to check if the module exists in the DB
check_if_exists() {
  local QUERY="SELECT EXISTS (SELECT 1 FROM $TABLE_NAME WHERE module_name = '$MODULE_NAME');"
  local RESP=$(container_compose exec -T db psql -U postgres -d "$DB_NAME" -c "$QUERY" | grep f)

  printf "Checking if the module %s exists\n" "$MODULE_NAME"
  if [[ $RESP == " f" ]]; then
    printf "Module %s does not exist\n" "$MODULE_NAME"
    exit 1
  else
    printf "Module %s exists\n" "$MODULE_NAME"
  fi
}

# Run command inside the DB container and make query to set API key and enable VT module
function setup_api_key() {
  printf "Setting up API key for the module %s\n" "$MODULE_NAME"

  if [[ -z "$VT_MODULE_API_KEY" ]]; then
    printf "VT API key is not defined\n"
    exit 1
  fi

  local QUERY=$(
    cat <<EOF
      UPDATE $TABLE_NAME
      SET module_config = (
        SELECT jsonb_agg(
          CASE
            WHEN elem->>'param_name' = 'vt_api_key'
            THEN jsonb_set(elem, '{value}', '"$VT_MODULE_API_KEY"')
            ELSE elem
          END
        )
        FROM jsonb_array_elements(module_config::jsonb) AS elem
      )
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(module_config::jsonb) AS elem WHERE elem->>'param_name' = 'vt_api_key'
      );
EOF
  )

  container_compose exec -T db psql -U postgres -d "$DB_NAME" -c "$QUERY"
  printf "API key for the module %s has been set\n" "$MODULE_NAME"

#  Current API key to debug
#  CURR_CONFIG_JSON_QUERY="SELECT module_config FROM $TABLE_NAME WHERE module_name = '$MODULE_NAME';"
#  RESP=$(container_compose exec -T db psql -U postgres -d "$DB_NAME" -q -t -c "$CURR_CONFIG_JSON_QUERY")
#  jq '.[] | select(.param_name == "vt_api_key").value' <<<"$RESP"
}

# Function to enable the module
function enable_module() {
  printf "Enabling the module %s\n" "$MODULE_NAME"

  local QUERY="UPDATE $TABLE_NAME SET is_active = true WHERE module_name = '$MODULE_NAME';"
  container_compose exec -T db psql -U postgres -d "$DB_NAME" -c "$QUERY"
  printf "Module %s has been enabled\n" "$MODULE_NAME"
}

check_if_exists
setup_api_key
enable_module
