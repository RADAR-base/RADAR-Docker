#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template

check_config_present etc/radar-backend/radar.yml
ensure_variable "$NETDATA_STREAM_API_KEY" "The Netdata Stream API key is not set."
copy_template_if_absent "etc/netdata/master/stream.conf"

. ./.env

echo "==> Configuring Portainer..."
if [ -z ${PORTAINER_PASSWORD_HASH} ]; then
  query_password PORTAINER_PASSWORD "Portainer password not set in .env."
  PORTAINER_PASSWORD_HASH=$(sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB admin "${PORTAINER_PASSWORD}" | cut -d ":" -f 2)
  ensure_variable 'PORTAINER_PASSWORD_HASH=' "${PORTAINER_PASSWORD_HASH}" .env
fi

# TODO Add time-series db backend for archiving
echo "==> Configuring Netdata master..."
sed_i "s|API-KEY|${NETDATA_STREAM_API_KEY}"

sudo-linux docker-compose up -d
