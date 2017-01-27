#!/bin/bash

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

if command_exists docker; then
    echo $(docker --version)
fi

if command_exists docker-compose; then
    echo $(docker-compose --version)
fi

echo "==> Creating docker network - hadoop"
sudo docker network create hadoop

echo "==> Starting RADAR-CNS Platform"
sudo docker-compose up -d