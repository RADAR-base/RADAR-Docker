#!/bin/bash

RADAR_RAW_TOPIC_LIST="android_empatica_e4_acceleration,android_empatica_e4_battery_level,android_empatica_e4_blood_volume_pulse,android_empatica_e4_electrodermal_activity,android_empatica_e4_inter_beat_interval,android_empatica_e4_sensor_status,android_empatica_e4_temperature"
RADAR_AGG_TOPIC_LIST="android_empatica_e4_acceleration_output, android_empatica_e4_battery_level_output, android_empatica_e4_blood_volume_pulse_output, android_empatica_e4_electrodermal_activity_output, android_empatica_e4_heartrate_output, android_empatica_e4_inter_beat_interval_output, android_empatica_e4_sensor_status_output, android_empatica_e4_temperature_output"

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
username=$(cat .env | grep HOTSTORAGE_USERNAME)
password=$(cat .env | grep HOTSTORAGE_PASSWORD)
database=$(cat .env | grep HOTSTORAGE_NAME)
username="$(echo -e "${username:20}" | tr -d '[:space:]' )"
password="$(echo -e "${password:20}" | tr -d '[:space:]' )"
database="$(echo -e "${database:16}" | tr -d '[:space:]' )"
# Update sink-mongo.properties
sed -i '/mongo.username=/c\mongo.username='$username sink-mongo.properties
sed -i '/mongo.password=/c\mongo.password='$password sink-mongo.properties
sed -i '/mongo.database=/c\mongo.database='$database sink-mongo.properties
# Set topics
sed -i '/topics=/c\topics='"$RADAR_AGG_TOPIC_LIST" sink-mongo.properties

echo "==> Setting HDFS Connector"
sed -i '/topics=/c\topics='"$RADAR_RAW_TOPIC_LIST" sink-hdfs.properties

echo "==> Starting RADAR-CNS Platform"
sudo docker-compose up -d
