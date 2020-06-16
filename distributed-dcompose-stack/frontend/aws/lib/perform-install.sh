#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose
check_command_exists java
check_command_exists psql
check_command_exists pg_isready

# Initialize and check all config files
check_config_present .env etc/env.template
check_config_present etc/smtp.env
check_config_present etc/redcap-integration/radar.yml
copy_template_if_absent etc/managementportal/config/oauth_client_details.csv
copy_template_if_absent etc/rest-source-authorizer/rest_source_clients_configs.yml
copy_template_if_absent etc/managementportal/config/radar-is.yml

. ./.env

ensure_env_password POSTGRES_PASSWORD "PostgreSQL password not set in .env."

echo "==> Configuring Management Portal"
./lib/on-db-ready lib/multi-db-init.sh
ensure_env_password MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET "ManagementPortal front-end client secret is not set in .env"
ensure_env_password MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD "Admin password for ManagementPortal is not set in .env."

bin/keystore-init

inline_variable 'publicKeyEndpoints:[[:space:]]*' "http://${SERVER_NAME}/managementportal/oauth/token_key" etc/managementportal/config/radar-is.yml

echo "==> Configuring Rest Source Authorizer"
inline_variable 'client_id:[[:space:]]' "$FITBIT_API_CLIENT_ID" etc/rest-source-authorizer/rest_source_clients_configs.yml
inline_variable 'client_secret:[[:space:]]' "$FITBIT_API_CLIENT_SECRET" etc/rest-source-authorizer/rest_source_clients_configs.yml


echo "==> Configuring Netdata Host monitoring"
if [[ -n "${NETDATA_MASTER_HOST}" ]]; then
  cp "../commons/etc/netdata/slave/stream.conf.template" "etc/netdata/slave/stream.conf"
  cp "../commons/etc/netdata/slave/netdata.conf.template" "etc/netdata/slave/netdata.conf"
  inline_variable "destination[[:space:]]=[[:space:]]" "${NETDATA_MASTER_HOST}" "etc/netdata/slave/stream.conf"
  inline_variable "api[[:space:]]key[[:space:]]=[[:space:]]" "${NETDATA_STREAM_API_KEY}" "etc/netdata/slave/stream.conf"
else
  echo "NetData Master not configured. Not setting up host monitoring."
fi

sudo-linux docker-compose up -d
