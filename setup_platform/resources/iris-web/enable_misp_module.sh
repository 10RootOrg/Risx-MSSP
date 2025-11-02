#!/usr/bin/env bash

# Enable MISP module via SQL query and setup config
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
export MODULE_NAME=${IRIS_MODULE_NAME:-"iris_misp_module"}
export MODULE_CONFIG_FILE=${IRIS_MISP_MODULE_CONFIG_FILE:-"misp_config.json"}

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

# Run command inside the DB container and make query to update the module config
function update_config() {
  printf "Updating the config for the module %s\n" "$MODULE_NAME"

  # If file with config does not exist, exit
  if [[ ! -f "$MODULE_CONFIG_FILE" ]]; then
    printf "Config file %s does not exist\n" "$MODULE_CONFIG_FILE"
    exit 1
  fi

  MODULE_CONFIG_SETTINGS=$(jq -Rs . "$MODULE_CONFIG_FILE")

  QUERY=$(
    cat <<'SQL'
      UPDATE $TABLE_NAME
      SET module_config = (
        SELECT jsonb_agg(
          CASE
            WHEN elem->>'param_name' = 'misp_config'
            THEN jsonb_set(elem, '{value}', '$MODULE_CONFIG_SETTINGS'::jsonb)
            ELSE elem
          END
        )
        FROM jsonb_array_elements(module_config::jsonb) AS elem
      )
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(module_config::jsonb) AS elem WHERE elem->>'param_name' = 'misp_config'
      );
SQL
  )

  container_compose exec -T db psql -U postgres -d "$DB_NAME" -c "$QUERY"
  printf "Config for the module %s has been updated\n" "$MODULE_NAME"

#  Show current value to debug
#  CURR_CONFIG_JSON_QUERY="SELECT module_config FROM $TABLE_NAME WHERE module_name = '$MODULE_NAME';"
#  RESP="$(container_compose exec -T db psql -U postgres -d "$DB_NAME" -q -t -c "$CURR_CONFIG_JSON_QUERY")"
#  jq '.[] | select(.param_name == "misp_config").value' <<<"$RESP" | jq -r .
}

# Function to enable the module
function enable_module() {
  printf "Enabling the module %s\n" "$MODULE_NAME"

  local QUERY="UPDATE $TABLE_NAME SET is_active = true WHERE module_name = '$MODULE_NAME';"
  container_compose exec -T db psql -U postgres -d "$DB_NAME" -c "$QUERY"
  printf "Module %s has been enabled\n" "$MODULE_NAME"
}

check_if_exists
update_config
enable_module
