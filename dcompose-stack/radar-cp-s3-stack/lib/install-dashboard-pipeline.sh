#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. lib/util.sh

echo "Setting up dashboard pipeline on"
check_command_exists docker
check_command_exists docker-compose

copy_template_if_absent etc/mongodb-connector/sink-mongo.properties
copy_template_if_absent etc/rest-api/radar.yml

check_parent_exists MONGODB_DIR ${MONGODB_DIR}

ensure_env_default HOTSTORAGE_USERNAME hotstorage
ensure_env_password HOTSTORAGE_PASSWORD "Hot storage (MongoDB) password not set in .env."
ensure_env_default HOTSTORAGE_NAME hotstorage

echo "==> Configuring MongoDB Connector"
# Update sink-mongo.properties
ensure_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.database=' $HOTSTORAGE_NAME etc/mongodb-connector/sink-mongo.properties

if [ -z "${COMBINED_AGG_TOPIC_LIST}"]; then
  COMBINED_AGG_TOPIC_LIST=$(sudo-linux docker run "${KAFKA_INIT_OPTS[@]}" list_aggregated.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_AGG_TOPIC_LIST}" ]; then
    COMBINED_AGG_TOPIC_LIST="${RADAR_AGG_TOPIC_LIST},${COMBINED_AGG_TOPIC_LIST}"
  fi
fi
ensure_variable 'topics=' "${COMBINED_AGG_TOPIC_LIST}" etc/mongodb-connector/sink-mongo.properties

echo "==> Configuring REST-API"

# Set MongoDb credential
inline_variable 'username:[[:space:]]' "$HOTSTORAGE_USERNAME" etc/rest-api/radar.yml
inline_variable 'password:[[:space:]]' "$HOTSTORAGE_PASSWORD" etc/rest-api/radar.yml
inline_variable 'database_name:[[:space:]]' "$HOTSTORAGE_NAME" etc/rest-api/radar.yml

echo "==> Including dashboard-pipeline.conf to nginx"
  sed_i  '/\#\sinclude\sdashboard\-pipeline\.conf\;*/s/#//g' etc/webserver/nginx.conf

echo "==> Starting RADAR-base Platform"
sudo-linux bin/radar-docker -f docker-compose.yml -f dashboard-pipeline.yml up -d --remove-orphans