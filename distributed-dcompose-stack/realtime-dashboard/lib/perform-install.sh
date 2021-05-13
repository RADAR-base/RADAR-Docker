#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template
copy_template_if_absent etc/jdbc-connector/sink-timescale.properties

. ./.env
echo "==> Configuring JDBC Connector"
# Update sink-timescale.properties
ensure_variable 'connection.url=' "jdbc:postgresql://timescaledb:5432/$TIMESCALEDB_DB" etc/jdbc-connector/sink-timescale.properties
ensure_variable 'connection.password=' $TIMESCALEDB_PASSWORD etc/jdbc-connector/sink-timescale.properties
ensure_variable 'topics=' $DASHBOARD_TOPIC_LIST etc/jdbc-connector/sink-timescale.properties

sudo-linux docker-compose up -d
