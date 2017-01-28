#!/bin/bash

command_exists() {
        command -v "$@" > /dev/null 2>&1
}

echo "Linux version: "$(uname -a)

if command_exists docker
    then
        echo "Docker version: "$(docker --version)
    else
       echo "RADAR-CNS cannot start without Docker. Please, install Docker and then try again"
       exit 1
fi

if command_exists docker-compose
    then
        echo "Docker-compose version: "$(docker-compose --version)
    else
        echo "RADAR-CNS cannot start without docker-compose. Please, install docker-compose and then try again"
        exit 1
fi

if [ ! -d /usr/local/var/lib/docker ]; then
    echo "RADAR-CNS stores HDFS volumes at /usr/local/var/lib/docker. If this folder does not exist, please create the entire path and then try again"
    exit 1
fi

echo "==> Creating docker network - hadoop"
sudo docker network create hadoop

echo "==> Setting MongoDB Connector"
# Extract credentials from .env file
username=$(cat .env | grep HOTSTORAGE_USERNAME=radar)
password=$(cat .env | grep HOTSTORAGE_PASSWORD=radar)
database=$(cat .env | grep HOTSTORAGE_NAME=hotstorage)
username="$(echo -e "${username:20}" | tr -d '[:space:]' )"
password="$(echo -e "${password:20}" | tr -d '[:space:]' )"
database="$(echo -e "${database:16}" | tr -d '[:space:]' )"
# Update sink-mongo.properties
sed -i '/mongo.username=/c\mongo.username='$username sink-mongo.properties
sed -i '/mongo.password=/c\mongo.password='$password sink-mongo.properties
sed -i '/mongo.database=/c\mongo.database='$database sink-mongo.properties
# Set topics
topic_list=$(cat .env | grep RADAR_TOPIC_LIST)
topic_list="$(echo -e "${topic_list:17}")"
sed -i '/topics=/c\topics='"$topic_list" sink-mongo.properties

echo "==> Setting HDFS Connector"
raw_topic=$(cat .env | grep RADAR_RAW_TOPIC_LIST)
raw_topic="$(echo -e "${raw_topic:21}")"
sed -i '/topics=/c\topics='"$raw_topic" sink-hdfs.properties

echo "==> Starting RADAR-CNS Platform"
sudo docker-compose up -d
