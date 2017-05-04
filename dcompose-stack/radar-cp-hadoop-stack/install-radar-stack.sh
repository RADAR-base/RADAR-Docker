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
if [ ! -e etc/sink-mongo.properties ]; then
  cp etc/sink-mongo.properties.template etc/sink-mongo.properties
fi
inline_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/sink-mongo.properties
inline_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/sink-mongo.properties
inline_variable 'mongo.database=' $HOTSTORAGE_NAME etc/sink-mongo.properties

# Set topics
inline_variable 'topics=' "${RADAR_AGG_TOPIC_LIST}" etc/sink-mongo.properties

echo "==> Setting HDFS Connector"
if [ ! -e etc/sink-hdfs.properties ]; then
  cp etc/sink-hdfs.properties.template etc/sink-hdfs.properties
fi
inline_variable 'topics=' "${RADAR_RAW_TOPIC_LIST}" etc/sink-hdfs.properties

echo "==> Setting nginx"
if [ ! -e etc/nginx.conf ]; then
  cp etc/nginx.conf.template etc/nginx.conf
fi
inline_variable 'server_name[[:space:]]*' $SERVER_NAME etc/nginx.conf

echo "==> Starting RADAR-CNS Platform"
sudo-linux docker-compose up --force-recreate -d
