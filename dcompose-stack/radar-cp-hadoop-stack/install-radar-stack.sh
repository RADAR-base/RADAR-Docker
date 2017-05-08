#!/bin/bash

. ./util.sh
. ./.env

check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}
check_parent_exists HDFS_DATA_DIR_2 ${HDFS_DATA_DIR_2}
check_parent_exists HDFS_NAME_DIR_1 ${HDFS_NAME_DIR_1}
check_parent_exists HDFS_NAME_DIR_2 ${HDFS_NAME_DIR_2}
check_parent_exists MONGODB_DIR ${MONGODB_DIR}

if [ -z $(sudo-linux docker network ls --format '{{.Name}}' | grep "^hadoop$") ]; then
  echo "==> Creating docker network - hadoop"
  sudo-linux docker network create hadoop
else
  echo "==> Creating docker network - hadoop ALREADY EXISTS"
fi

echo "==> Setting MongoDB Connector"

# Update sink-mongo.properties
copy_template_if_absent etc/sink-mongo.properties
inline_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/sink-mongo.properties
inline_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/sink-mongo.properties
inline_variable 'mongo.database=' $HOTSTORAGE_NAME etc/sink-mongo.properties

# Set topics
inline_variable 'topics=' "${RADAR_AGG_TOPIC_LIST}" etc/sink-mongo.properties

echo "==> Setting HDFS Connector"
copy_template_if_absent etc/sink-hdfs.properties
inline_variable 'topics=' "${RADAR_RAW_TOPIC_LIST}" etc/sink-hdfs.properties

echo "==> Setting nginx"
copy_template_if_absent etc/nginx.conf
inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/nginx.conf

echo "==> Starting RADAR-CNS Platform"
sudo-linux docker-compose up --force-recreate -d
echo "### SUCCESS ###"
