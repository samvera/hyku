#!/usr/bin/env sh

COUNTER=0;
# /app/samvera/hyrax-webapp/solr/conf
CONFDIR="${1}"

if [ "$SOLR_ADMIN_USER" ]; then
  solr_user_settings="--user $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD"
fi

# Solr Cloud ConfigSet API URLs
solr_config_list_url="http://$SOLR_HOST:$SOLR_PORT/api/cluster/configs?omitHeader=true"
solr_config_upload_url="http://$SOLR_HOST:$SOLR_PORT/solr/admin/configs?action=UPLOAD&name=$SOLR_CONFIGSET_NAME"
# Solr Cloud Collection API URLs
solr_collection_list_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=LIST"
solr_collection_modify_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=MODIFYCOLLECTION&collection=$SOLR_COLLECTION_NAME&collection.configName=$SOLR_CONFIGSET_NAME"

while [ $COUNTER -lt 30 ]; do
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  if nc -z "${SOLR_HOST}" "${SOLR_PORT}"; then
    # the solr pods come up and report available before they are ready to accept trusted configs
    # only try to upload the config if auth is on.
    if curl --silent $solr_user_settings "$solr_config_list_url" | grep -q "$SOLR_CONFIGSET_NAME"; then
      echo "-- ConfigSet already exists; skipping creation ...";
    else
      echo "-- ConfigSet for ${CONFDIR} does not exist; creating ..."
      (cd "$CONFDIR" && zip -r - *) | curl -X POST $solr_user_settings --header "Content-Type:application/octet-stream" --data-binary @- "$solr_config_upload_url"
    fi
    break
  fi
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

COUNTER=0;

while [ $COUNTER -lt 30 ]; do
  if curl --silent $solr_user_settings "$solr_collection_list_url" | grep -q "$SOLR_COLLECTION_NAME"; then
    echo "-- Collection ${SOLR_COLLECTION_NAME} exists; setting ${SOLR_CONFIGSET_NAME} ConfigSet ..."
    echo $solr_collection_modify_url
    curl $solr_user_settings "$solr_collection_modify_url"
    exit
  fi
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

echo "--- ERROR: failed to create/update Solr collection after 5 minutes";
exit 1
