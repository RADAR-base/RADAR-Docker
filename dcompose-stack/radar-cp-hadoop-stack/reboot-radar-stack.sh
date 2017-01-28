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

echo "==> Stopping RADAR-CNS Platform"
sudo docker-compose down

echo "==> Starting RADAR-CNS Platform"
sudo docker-compose up -d
