#!/bin/bash

. ./util.sh
. ./.env

check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}
check_parent_exists HDFS_DATA_DIR_2 ${HDFS_DATA_DIR_2}
check_parent_exists HDFS_NAME_DIR_1 ${HDFS_NAME_DIR_1}
check_parent_exists HDFS_NAME_DIR_2 ${HDFS_NAME_DIR_2}
check_parent_exists MONGODB_DIR ${MONGODB_DIR}

if [ -z $(sudo-docker network ls --format '{{.Name}}' | grep "^hadoop$") ]; then
  echo "==> Creating docker network - hadoop"
  sudo-docker network create hadoop
else
  echo "==> Creating docker network - hadoop ALREADY EXISTS"
fi

echo "==> Setting MongoDB Connector"

# Update sink-mongo.properties
sed -i '' 's/\(mongo.username=\).*$/\1'${HOTSTORAGE_USERNAME}'/' sink-mongo.properties
sed -i '' 's/\(mongo.password=\).*$/\1'${HOTSTORAGE_PASSWORD}'/' sink-mongo.properties
sed -i '' 's/\(mongo.database=\).*$/\1'${HOTSTORAGE_NAME}'/' sink-mongo.properties
sed -i '' 's/\(server_name[[:space:]]*\).*$/\1'${SERVER_NAME}'/' nginx.conf

# Set topics
sed -i '' 's/\(topics=\).*$/\1'${RADAR_AGG_TOPIC_LIST}'/' sink-mongo.properties

echo "==> Setting HDFS Connector"
sed -i '' 's|\(topics=\).*$|\1'${RADAR_RAW_TOPIC_LIST}'|' sink-hdfs.properties

echo "==> Starting RADAR-CNS Platform"
sudo-docker-compose up --force-recreate -d
