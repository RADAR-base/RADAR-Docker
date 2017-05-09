#!/bin/bash

. ./util.sh
. ./.env

check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}
check_parent_exists HDFS_DATA_DIR_2 ${HDFS_DATA_DIR_2}
check_parent_exists HDFS_NAME_DIR_1 ${HDFS_NAME_DIR_1}
check_parent_exists HDFS_NAME_DIR_2 ${HDFS_NAME_DIR_2}
check_parent_exists MONGODB_DIR ${MONGODB_DIR}

if [ -z "$SERVER_NAME" ]; then
  echo "Set SERVER_NAME variable in .env"
fi

if [ -z $(sudo-linux docker network ls --format '{{.Name}}' | grep "^hadoop$") ]; then
  echo "==> Creating docker network - hadoop"
  sudo-linux docker network create hadoop
else
  echo "==> Creating docker network - hadoop ALREADY EXISTS"
fi

echo "==> Configuring MongoDB Connector"

# Update sink-mongo.properties
copy_template_if_absent etc/sink-mongo.properties
inline_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/sink-mongo.properties
inline_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/sink-mongo.properties
inline_variable 'mongo.database=' $HOTSTORAGE_NAME etc/sink-mongo.properties

# Set topics
inline_variable 'topics=' "${RADAR_AGG_TOPIC_LIST}" etc/sink-mongo.properties

echo "==> Configuring HDFS Connector"
copy_template_if_absent etc/sink-hdfs.properties
inline_variable 'topics=' "${RADAR_RAW_TOPIC_LIST}" etc/sink-hdfs.properties

echo "==> Configuring nginx"
copy_template_if_absent etc/nginx.conf
inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/nginx.conf
sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'$SERVER_NAME'\2|' etc/nginx.conf
sudo-linux docker volume create certs
sudo-linux docker volume create certs-data

echo "==> Starting RADAR-CNS Platform"
sudo-linux docker-compose up --force-recreate -d

request_certificate "$SERVER_NAME"
echo "### SUCCESS ###"
