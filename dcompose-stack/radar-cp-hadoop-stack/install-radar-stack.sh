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
inline_variable 'mongo.username=' $HOTSTORAGE_USERNAME sink-mongo.properties
inline_variable 'mongo.password=' $HOTSTORAGE_PASSWORD sink-mongo.properties
inline_variable 'mongo.database=' $HOTSTORAGE_NAME sink-mongo.properties
inline_variable 'server_name[[:space:]]*' $SERVER_NAME nginx.conf

# Set topics
inline_variable 'topics=' "${RADAR_AGG_TOPIC_LIST}" sink-mongo.properties

echo "==> Setting HDFS Connector"
inline_variable 'topics=' "${RADAR_RAW_TOPIC_LIST}" sink-hdfs.properties

echo "==> Starting RADAR-CNS Platform"
sudo-linux docker-compose up --force-recreate -d
