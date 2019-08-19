#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

. ./.env

ensure_env_password HOSTNAME "Host Name is not set .env."

sudo-linux docker-compose up -d
