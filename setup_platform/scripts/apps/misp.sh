#!/bin/bash
# Reference: https://github.com/MISP/misp-docker

# Exit immediately if a command exits with a non-zero status
set -e

source "./libs/main.sh"
define_env
define_paths
source "./libs/install-helper.sh"
pre_install "misp"

replace_envs "${workdir}/${service_name}/.env"
source .env

# Step 2: Start the service
printf "Starting the service...\n"
docker compose up -d --force-recreate
printf "Starting the Sllep...\n"
sleep 70
printf "Ending the Sllep...\n"

NEWUSERNAME_PASSWORD="$(
  {
    tr -dc 'A-Z' </dev/urandom | head -c1
    tr -dc 'a-z' </dev/urandom | head -c1
    tr -dc '0-9' </dev/urandom | head -c1
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c12
  } | fold -w1 | shuf | tr -d '\n'
  echo
)"
ADMINE_PASSWORD="$(
  {
    tr -dc 'A-Z' </dev/urandom | head -c1
    tr -dc 'a-z' </dev/urandom | head -c1
    tr -dc '0-9' </dev/urandom | head -c1
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c12
  } | fold -w1 | shuf | tr -d '\n'
  echo
)"

USER_LIST=$(docker exec misp-misp-core-1 /var/www/MISP/app/Console/cake user list)

echo "=== Current MISP user list ==="
echo "$USER_LIST"

# Basic empty check
if [[ -z "$USER_LIST" ]]; then
  echo "No users found — running setup logic..."
  docker exec misp-misp-core-1 /var/www/MISP/app/Console/cake user create admin@admin.test 1 1 "Aa1234567890"
  echo "No users found — Ending setup logic..."

else
  echo "Users already exist — skipping user creation."
fi

docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake user create "${READ_ONLY_USER}" 6 1 "Aa1234567890"
sleep 5
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake user list
printf "user list end\n"

sleep 2
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake user change_pw --no_password_change 2 "$NEWUSERNAME_PASSWORD"
sleep 2
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake user change_pw --no_password_change 1 "$ADMINE_PASSWORD"
sleep 2
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake user list
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake admin setSetting Security.password_policy_length 8
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake admin setSetting MISP.default_publish_alert false  
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake admin setSetting MISP.correlation_engine "NoAcl"
docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake Server loadDefaultFeeds
sleep 5
ID_ARRAY=($FEEDS_ID)

# Iterate over the array
for id in "${ID_ARRAY[@]}"; do
    echo "Processing ID: $id"
    docker exec -it misp-misp-core-1 /var/www/MISP/app/Console/cake Server toggleFeed "$id"
done


echo "############################################"
echo "### READ_ONLY_USER created: ${READ_ONLY_USER}"
echo "### Password: $NEWUSERNAME_PASSWORD"
echo "### User: admin@admin.test"
echo "### Password: $ADMINE_PASSWORD"
echo "############################################"

echo "### Autogenerated by MISP scripts ###" >> "${workdir}/.env"

echo "USER=admin@admin.test" >> "${workdir}/.env"
echo "MISP_PASSWORD=$ADMINE_PASSWORD" >> "${workdir}/.env"
echo "READ_ONLY_USER=$READ_ONLY_USER" >> "${workdir}/.env"
echo "MISP_PASSWORD=$NEWUSERNAME_PASSWORD" >> "${workdir}/.env"


sleep 5
docker restart misp-misp-core-1
sleep 10

echo "Pull Start"

for id in "${ID_ARRAY[@]}"; do
    echo "Fetching Feed ID: $id"
    nohup docker exec misp-misp-core-1 /var/www/MISP/app/Console/cake Server fetchFeed 1 "$id" &
done


sleep 5
echo "Pull End"

#!/bin/bash

CONTAINER_NAME="misp-misp-core-1"
# Redefine cleanly to avoid any hidden character issues
CRON_COMMAND="0 1 * * * docker exec ${CONTAINER_NAME} /var/www/MISP/app/Console/cake Server pullall 1 update"
echo "=== DEBUGGING CRONTAB ISSUE ==="

# 1. Check current user
echo "Current user: $(whoami)"

# 2. Check if cron service is running
echo "Checking cron service..."
if command -v systemctl > /dev/null; then
    systemctl is-active cron 2>/dev/null || systemctl is-active crond 2>/dev/null || echo "Cron service status unknown"
elif command -v service > /dev/null; then
    service cron status 2>/dev/null || service crond status 2>/dev/null || echo "Cron service status unknown"
else
    if pgrep cron > /dev/null || pgrep crond > /dev/null; then
        echo "Cron process is running"
    else
        echo "ERROR: No cron process found!"
    fi
fi

# 3. Check current crontab
echo "Current crontab BEFORE adding:"
crontab -l 2>/dev/null || echo "(no existing crontab)"

# 4. Try to add the cron job with detailed output
echo "Adding cron job..."
echo "Command to add: $CRON_COMMAND"

# Create a temporary file to debug
TEMP_CRON=$(mktemp)
echo crontab -l 2>/dev/null > "$TEMP_CRON"

# crontab -l 2>/dev/null > "$TEMP_CRON"
crontab -l 2>/dev/null > "$TEMP_CRON" || echo "# empty crontab" > "$TEMP_CRON"


echo "$CRON_COMMAND" >> "$TEMP_CRON"

echo "Contents of temp cron file:"
cat "$TEMP_CRON"

# Apply the crontab
if crontab "$TEMP_CRON" 2>&1; then
    echo "crontab command executed successfully"
else
    echo "crontab command failed"
    rm "$TEMP_CRON"
    exit 1
fi

rm "$TEMP_CRON"

# 5. Check crontab immediately after
echo "Current crontab AFTER adding:"
crontab -l 2>/dev/null || echo "(no crontab found - this is the problem!)"

# 6. Verify the specific job exists
if crontab -l 2>/dev/null | grep -F "docker exec $CONTAINER_NAME" > /dev/null; then
    echo "SUCCESS: Cron job found in crontab"
else
    echo "FAILURE: Cron job NOT found in crontab"
    
    # Additional checks
    echo "=== ADDITIONAL DIAGNOSTICS ==="
    
    # Check if we can write to crontab at all
    echo "Testing basic crontab functionality..."
    echo "# Test entry" | crontab -
    if crontab -l 2>/dev/null | grep -F "# Test entry" > /dev/null; then
        echo "Basic crontab write works"
        # Clean up test entry
        crontab -l 2>/dev/null | grep -v "# Test entry" | crontab -
    else
        echo "ERROR: Cannot write to crontab at all!"
    fi
    
    # Check crontab directory permissions
    if [ -d /var/spool/cron ]; then
        echo "Cron spool directory permissions:"
        ls -la /var/spool/cron/ 2>/dev/null || echo "Cannot access /var/spool/cron/"
    fi
    
    # exit 1
fi

echo "=== END DEBUG ==="

print_green_v2 "$service_name deployment started." "Successfully"