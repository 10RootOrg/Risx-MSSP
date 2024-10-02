#!/bin/bash
# TODO:Do we really need this?

# TODO: {"statusCode":409,"error":"Conflict","message":"Saved object [index-pattern/artifact] conflict"}Done!
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:5601)" != "302" ]]; do echo "Waiting on Kibana to be ready..."; sleep 1; done
echo "Applying default config..."
curl -XPOST localhost:5601/api/saved_objects/index-pattern/artifact -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{"attributes":{"timeFieldName":"@timestamp","title":"artifact*"}}'
echo "Done!"
