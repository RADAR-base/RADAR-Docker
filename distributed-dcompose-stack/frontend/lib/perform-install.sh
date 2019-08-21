#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

# Initialize and check all config files
check_config_present .env etc/env.template
check_config_present etc/smtp.env
copy_template_if_absent etc/managementportal/config/oauth_client_details.csv
copy_template_if_absent etc/rest-source-authorizer/rest_source_clients_configs.yml

. ./.env

check_parent_exists MP_POSTGRES_DIR ${MP_POSTGRES_DIR}

ensure_env_password POSTGRES_PASSWORD "PostgreSQL password not set in .env."

echo "==> Configuring Management Portal"
sudo-linux docker-compose build --no-cache radarbase-postgresql
sudo-linux docker-compose up -d --force-recreate radarbase-postgresql
sudo-linux docker-compose exec --user postgres -T radarbase-postgresql on-db-ready /docker-entrypoint-initdb.d/multi-db-init.sh
ensure_env_password MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET "ManagementPortal front-end client secret is not set in .env"
ensure_env_password MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD "Admin password for ManagementPortal is not set in .env."

bin/keystore-init

echo "==> Configuring Rest Source Authorizer"
inline_variable 'client_id:[[:space:]]' "$FITBIT_API_CLIENT_ID" etc/rest-source-authorizer/rest_source_clients_configs.yml
inline_variable 'client_secret:[[:space:]]' "$FITBIT_API_CLIENT_SECRET" etc/rest-source-authorizer/rest_source_clients_configs.yml

sudo-linux docker-compose up -d
