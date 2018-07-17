#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. lib/util.sh

sudo-linux chmod og-rw ./.env
sudo-linux chmod og-rwx ./etc
if [ -e ./output ]; then
  sudo-linux chmod og-rwx ./output
else
  sudo-linux mkdir -m 0700 ./output
fi

# Initialize and check all config files
check_config_present .env etc/env.template
check_config_present etc/radar-backend/radar.yml
check_config_present etc/managementportal/config/oauth_client_details.csv
check_config_present etc/redcap-integration/radar.yml
copy_template_if_absent etc/mongodb-connector/sink-mongo.properties
copy_template_if_absent etc/hdfs-connector/sink-hdfs.properties
copy_template_if_absent etc/rest-api/radar.yml
copy_template_if_absent etc/webserver/nginx.conf

. ./.env

# Check provided directories and configurations
check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}
check_parent_exists HDFS_DATA_DIR_2 ${HDFS_DATA_DIR_2}
check_parent_exists HDFS_NAME_DIR_1 ${HDFS_NAME_DIR_1}
check_parent_exists HDFS_NAME_DIR_2 ${HDFS_NAME_DIR_2}
check_parent_exists MONGODB_DIR ${MONGODB_DIR}
check_parent_exists MP_POSTGRES_DIR ${MP_POSTGRES_DIR}

if [ -z ${SERVER_NAME} ]; then
  echo "Set SERVER_NAME variable in .env"
  exit 1
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
sudo-linux bin/radar-docker run --rm kafka-init

echo "==> Configuring MongoDB Connector"
# Update sink-mongo.properties
inline_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/mongodb-connector/sink-mongo.properties
inline_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/mongodb-connector/sink-mongo.properties
inline_variable 'mongo.database=' $HOTSTORAGE_NAME etc/mongodb-connector/sink-mongo.properties

# Set topics
if [ -z "${COMBINED_AGG_TOPIC_LIST}"]; then
  COMBINED_AGG_TOPIC_LIST=$(sudo-linux docker run --rm radarcns/kafka-init list_aggregated.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_AGG_TOPIC_LIST}" ]; then
    COMBINED_AGG_TOPIC_LIST="${RADAR_AGG_TOPIC_LIST},${COMBINED_AGG_TOPIC_LIST}"
  fi
fi
inline_variable 'topics=' "${COMBINED_AGG_TOPIC_LIST}" etc/mongodb-connector/sink-mongo.properties

echo "==> Configuring HDFS Connector"
if [ -z "${COMBINED_RAW_TOPIC_LIST}"]; then
  COMBINED_RAW_TOPIC_LIST=$(sudo-linux docker run --rm radarcns/kafka-init list_raw.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_RAW_TOPIC_LIST}" ]; then
    COMBINED_RAW_TOPIC_LIST="${RADAR_RAW_TOPIC_LIST},${COMBINED_RAW_TOPIC_LIST}"
  fi
fi
inline_variable 'topics=' "${COMBINED_RAW_TOPIC_LIST}" etc/hdfs-connector/sink-hdfs.properties

echo "==> Configuring Management Portal"


keystorefile=etc/managementportal/config/keystore.jks
if [ -f "$keystorefile" ]; then
  echo "--> Keystore for signing JWTs already exists. Not creating a new one."
else
  echo "--> Generating keystore to hold RSA keypair for JWT signing"
  if [ -n "${MANAGEMENTPORTAL_KEY_DNAME}" ]; then
    sudo-linux keytool -genkeypair -dname "${MANAGEMENTPORTAL_KEY_DNAME}" -alias selfsigned -keyalg RSA -keystore "$keystorefile" -keysize 4096 -storepass radarbase -keypass radarbase
  else
    sudo-linux keytool -genkeypair -alias selfsigned -keyalg RSA -keystore "$keystorefile" -keysize 4096 -storepass radarbase -keypass radarbase
  fi
  sudo-linux chmod 400 "${keystorefile}"
fi

echo "==> Configuring REST-API"

# Set MongoDb credential
inline_variable 'username:[[:space:]]' "$HOTSTORAGE_USERNAME" etc/rest-api/radar.yml
inline_variable 'password:[[:space:]]' "$HOTSTORAGE_PASSWORD" etc/rest-api/radar.yml
inline_variable 'database_name:[[:space:]]' "$HOTSTORAGE_NAME" etc/rest-api/radar.yml

echo "==> Configuring REDCap-Integration"

echo "==> Configuring nginx"
inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
init_certificate "${SERVER_NAME}"

echo "==> Starting RADAR-base Platform"
sudo-linux bin/radar-docker up -d --remove-orphans "$@"

request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
echo "### SUCCESS ###"
