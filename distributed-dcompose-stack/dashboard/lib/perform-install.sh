#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose


# Initialize and check all config files
check_config_present .env etc/env.template
check_config_present etc/radar-backend/radar.yml
copy_template_if_absent etc/rest-api/radar.yml

. ./.env

check_parent_exists MONGODB_DIR ${MONGODB_DIR}

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

ensure_env_default HOTSTORAGE_USERNAME hotstorage
ensure_env_password HOTSTORAGE_PASSWORD "Hot storage (MongoDB) password not set in .env."
ensure_env_default HOTSTORAGE_NAME hotstorage


echo "==> Configuring REST-API"

# Set MongoDb credential
inline_variable 'username:[[:space:]]' "$HOTSTORAGE_USERNAME" etc/rest-api/radar.yml
inline_variable 'password:[[:space:]]' "$HOTSTORAGE_PASSWORD" etc/rest-api/radar.yml
inline_variable 'database_name:[[:space:]]' "$HOTSTORAGE_NAME" etc/rest-api/radar.yml
inline_variable 'management_portal_url:[[:space:]]*' "$MANAGEMENT_PORTAL_URL" etc/rest-api/radar.yml
inline_variable 'oauth_client_secret:[[:space:]]*' "$REST_API_OAUTH_CLIENT_SECRET" etc/rest-api/radar.yml

if [[ (-f etc/managementportal/config/keystore.jks) || (-f etc/managementportal/config/keystore.p12) ]]; then
  ./bin/keys-init
else
  echo "No Keystore File Found. Configuring using publicKeyEndpoint..."
  copy_template_if_absent etc/rest-api/radar-is.yml
  inline_variable 'publicKeyEndpoints:[[:space:]]*' "$MANAGEMENT_PORTAL_URL/oauth/token_key" etc/rest-api/radar-is.yml
fi

sudo-linux docker-compose up -d
