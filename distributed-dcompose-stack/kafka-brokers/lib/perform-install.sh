#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

. ./.env

ensure_env_password KAFKA_1_HOST "Kafka 1 host is not set .env."
ensure_env_password KAFKA_2_HOST "Kafka 2 host is not set .env."
ensure_env_password KAFKA_3_HOST "Kafka 3 host is not set .env."

sudo-linux docker-compose up -d
