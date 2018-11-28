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
copy_template_if_absent etc/managementportal/config/oauth_client_details.csv
copy_template_if_absent etc/mongodb-connector/sink-mongo.properties
copy_template_if_absent etc/hdfs-connector/sink-hdfs.properties
copy_template_if_absent etc/rest-api/radar.yml
copy_template_if_absent etc/webserver/ip-access-control.conf
copy_template_if_absent etc/webserver/optional-services.conf
copy_template_if_absent etc/fitbit/docker/source-fitbit.properties
copy_template_if_absent etc/rest-source-authorizer/rest_source_clients_configs.yml

# Set permissions
sudo-linux chmod og-rw ./.env
sudo-linux chmod og-rwx ./etc
if [ -e ./output ]; then
  sudo-linux chmod og-rwx ./output
else
  sudo-linux mkdir -m 0700 ./output
fi

. ./.env

if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  copy_template_if_absent etc/webserver/nginx.conf
  if ! grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does not contain HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.conf.template or set ENABLE_HTTPS=no in .env."
    exit 1
  fi
else
  copy_template_if_absent etc/webserver/nginx.conf etc/webserver/nginx.nossl.conf.template
  if grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does contains HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.nossl.conf.template or set ENABLE_HTTPS=yes in .env."
    exit 1
  fi
fi

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
  sudo-linux docker network create --internal hadoop > /dev/null
elif [ $(docker network inspect hadoop --format "{{.Internal}}") != "true" ]; then
  echo "==> Re-creating docker network - hadoop"
  sudo-linux bin/radar-docker quit radar-hdfs-connector hdfs-namenode-1 hdfs-datanode-1 hdfs-datanode-2 hdfs-datanode-3 > /dev/null
  sudo-linux docker network rm hadoop > /dev/null
  sudo-linux docker network create --internal hadoop > /dev/null
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
    radarbase/kafka-init:${RADAR_SCHEMAS_VERSION}
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
sudo-linux bin/radar-docker build --no-cache radarbase-postgresql
sudo-linux bin/radar-docker up -d --force-recreate radarbase-postgresql
sudo-linux bin/radar-docker exec --user postgres -T radarbase-postgresql on-db-ready /docker-entrypoint-initdb.d/multi-db-init.sh
ensure_env_password MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET "ManagementPortal front-end client secret is not set in .env"
ensure_env_password MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD "Admin password for ManagementPortal is not set in .env."

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
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
  init_certificate "${SERVER_NAME}"
else
  # Fill in reverse proxy servers
  proxies=
  for PROXY in ${NGINX_PROXIES:-}; do
    proxies="${proxies}set_real_ip_from ${PROXY}; "
  done
  sed_i "s/^\(\s*\).*# NGINX_PROXIES/\1$proxies# NGINX_PROXIES/" etc/webserver/nginx.conf
fi

# Configure Optional services
if [[ "${ENABLE_OPTIONAL_SERVICES}" = "true" ]]; then
  echo "==> Configuring Fitbit Connector"
  ensure_variable 'fitbit.api.client=' $FITBIT_API_CLIENT_ID etc/fitbit/docker/source-fitbit.properties
  ensure_variable 'fitbit.api.secret=' $FITBIT_API_CLIENT_SECRET etc/fitbit/docker/source-fitbit.properties

  echo "==> Configuring Rest Source Authorizer"
  inline_variable 'client_id:[[:space:]]' "$FITBIT_API_CLIENT_ID" etc/rest-source-authorizer/rest_source_clients_configs.yml
  inline_variable 'client_secret:[[:space:]]' "$FITBIT_API_CLIENT_SECRET" etc/rest-source-authorizer/rest_source_clients_configs.yml

  check_config_present etc/redcap-integration/radar.yml
fi

echo "==> Starting RADAR-base Platform"
sudo-linux bin/radar-docker up -d --remove-orphans "$@"

if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
fi
echo "### SUCCESS ###"
