#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

# Initialize and check all config files
check_config_present .env etc/env.template
check_config_present etc/smtp.env
check_config_present etc/radar-backend/radar.yml
check_config_present etc/managementportal/config/oauth_client_details.csv
copy_template_if_absent etc/mongodb-connector/sink-mongo.properties
copy_template_if_absent etc/hdfs-connector/sink-hdfs.properties
copy_template_if_absent etc/rest-api/radar.yml
copy_template_if_absent etc/webserver/nginx.conf
copy_template_if_absent etc/webserver/ip-access-control.conf
copy_template_if_absent etc/webserver/optional-services.conf
copy_template_if_absent etc/fitbit/docker/source-fitbit.properties

# Set permissions
sudo-linux chmod og-rw ./.env
sudo-linux chmod og-rwx ./etc
if [ -e ./output ]; then
  sudo-linux chmod og-rwx ./output
else
  sudo-linux mkdir -m 0700 ./output
fi

. ./.env

# Check provided directories and configurations
check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}
check_parent_exists HDFS_DATA_DIR_2 ${HDFS_DATA_DIR_2}
check_parent_exists HDFS_NAME_DIR_1 ${HDFS_NAME_DIR_1}
check_parent_exists HDFS_NAME_DIR_2 ${HDFS_NAME_DIR_2}
check_parent_exists MONGODB_DIR ${MONGODB_DIR}
check_parent_exists MP_POSTGRES_DIR ${MP_POSTGRES_DIR}

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

ensure_env_default HOTSTORAGE_USERNAME hotstorage
ensure_env_password HOTSTORAGE_PASSWORD "Hot storage (MongoDB) password not set in .env."
ensure_env_default HOTSTORAGE_NAME hotstorage

ensure_env_password POSTGRES_PASSWORD "PostgreSQL password not set in .env."
ensure_env_default KAFKA_MANAGER_USERNAME kafkamanager-user
ensure_env_password KAFKA_MANAGER_PASSWORD "Kafka Manager password not set in .env."

if [ -z ${PORTAINER_PASSWORD_HASH} ]; then
  query_password PORTAINER_PASSWORD "Portainer password not set in .env."
  PORTAINER_PASSWORD_HASH=$(sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB admin "${PORTAINER_PASSWORD}" | cut -d ":" -f 2)
  ensure_variable 'PORTAINER_PASSWORD_HASH=' "${PORTAINER_PASSWORD_HASH}" .env
fi

# Create networks and volumes
if ! sudo-linux docker network ls --format '{{.Name}}' | grep -q "^hadoop$"; then
  echo "==> Creating docker network - hadoop"
  sudo-linux docker network create hadoop > /dev/null
else
  echo "==> Creating docker network - hadoop ALREADY EXISTS"
fi

echo "==> Checking docker external volumes"
if ! sudo-linux docker volume ls -q | grep -q "^certs$"; then
  sudo-linux docker volume create --name=certs --label certs
fi
if ! sudo-linux docker volume ls -q | grep -q "^certs-data$"; then
  sudo-linux docker volume create --name=certs-data --label certs
fi

# Initializing Kafka
echo "==> Setting up topics"
sudo-linux bin/radar-docker up -d zookeeper-1 zookeeper-2 zookeeper-3 kafka-1 kafka-2 kafka-3 schema-registry-1
sudo-linux bin/radar-docker run --rm kafka-init
KAFKA_SCHEMA_RETENTION_MS=${KAFKA_SCHEMA_RETENTION_MS:-5400000000}
KAFKA_SCHEMA_RETENTION_CMD='kafka-configs --zookeeper "${KAFKA_ZOOKEEPER_CONNECT}" --entity-type topics --entity-name _schemas --alter --add-config min.compaction.lag.ms='${KAFKA_SCHEMA_RETENTION_MS}',cleanup.policy=compact'
sudo-linux bin/radar-docker exec -T kafka-1 bash -c "$KAFKA_SCHEMA_RETENTION_CMD"

echo "==> Configuring MongoDB Connector"
# Update sink-mongo.properties
ensure_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.database=' $HOTSTORAGE_NAME etc/mongodb-connector/sink-mongo.properties

KAFKA_INIT_OPTS=(
    --rm -v "$PWD/etc/schema:/schema/conf"
    radarbase/kafka-init:0.3.6
  )

# Set topics
if [ -z "${COMBINED_AGG_TOPIC_LIST}"]; then
  COMBINED_AGG_TOPIC_LIST=$(sudo-linux docker run "${KAFKA_INIT_OPTS[@]}" list_aggregated.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_AGG_TOPIC_LIST}" ]; then
    COMBINED_AGG_TOPIC_LIST="${RADAR_AGG_TOPIC_LIST},${COMBINED_AGG_TOPIC_LIST}"
  fi
fi
ensure_variable 'topics=' "${COMBINED_AGG_TOPIC_LIST}" etc/mongodb-connector/sink-mongo.properties

echo "==> Configuring HDFS Connector"
if [ -z "${COMBINED_RAW_TOPIC_LIST}"]; then
  COMBINED_RAW_TOPIC_LIST=$(sudo-linux docker run "${KAFKA_INIT_OPTS[@]}" list_raw.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_RAW_TOPIC_LIST}" ]; then
    COMBINED_RAW_TOPIC_LIST="${RADAR_RAW_TOPIC_LIST},${COMBINED_RAW_TOPIC_LIST}"
  fi
fi
ensure_variable 'topics=' "${COMBINED_RAW_TOPIC_LIST}" etc/hdfs-connector/sink-hdfs.properties

echo "==> Configuring Management Portal"

bin/keystore-init

echo "==> Configuring REST-API"

# Set MongoDb credential
inline_variable 'username:[[:space:]]' "$HOTSTORAGE_USERNAME" etc/rest-api/radar.yml
inline_variable 'password:[[:space:]]' "$HOTSTORAGE_PASSWORD" etc/rest-api/radar.yml
inline_variable 'database_name:[[:space:]]' "$HOTSTORAGE_NAME" etc/rest-api/radar.yml

echo "==> Configuring Kafka-manager"
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${KAFKA_MANAGER_USERNAME}" "${KAFKA_MANAGER_PASSWORD}" > etc/webserver/kafka-manager.htpasswd

echo "==> Configuring nginx"
inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
init_certificate "${SERVER_NAME}"

# Configure Optional services
if [[ "${ENABLE_OPTIONAL_SERVICES}" = "true" ]]; then
  echo "==> Configuring Fitbit Connector"
  ensure_variable 'fitbit.api.client=' $FITBIT_API_CLIENT_ID etc/fitbit/docker/source-fitbit.properties
  ensure_variable 'fitbit.api.secret=' $FITBIT_API_CLIENT_SECRET etc/fitbit/docker/source-fitbit.properties

  check_config_present etc/redcap-integration/radar.yml
fi

echo "==> Starting RADAR-base Platform"
sudo-linux bin/radar-docker up -d --remove-orphans "$@"

request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
echo "### SUCCESS ###"
