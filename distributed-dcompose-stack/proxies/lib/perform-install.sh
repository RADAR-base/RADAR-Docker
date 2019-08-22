#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template
copy_template_if_absent etc/webserver/ip-access-control.conf

. ./.env

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

echo "==> Checking docker external volumes"
if ! sudo-linux docker volume ls -q | grep -q "^certs$"; then
  sudo-linux docker volume create --name=certs --label certs
fi
if ! sudo-linux docker volume ls -q | grep -q "^certs-data$"; then
  sudo-linux docker volume create --name=certs-data --label certs
fi

# Initializing Kafka
echo "==> Setting up topics"
sudo-linux docker-compose run --rm kafka-init

echo "==> Configure gateway"
if [[ (-f etc/managementportal/config/keystore.jks) || (-f etc/managementportal/config/keystore.p12) ]]; then
  ./bin/keys-init
else
  echo "No Keystore File Found. Please copy it from the Management Portal and put it in 'etc/managementportal/config/'..."
  exit 1
fi
inline_variable 'managementPortalUrl:[[:space:]]*' "${MANAGEMENT_PORTAL_URL}" etc/gateway/gateway.yml

echo "==> Configuring nginx"
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  cp etc/webserver/nginx.conf.template etc/webserver/nginx.conf
  if ! grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does not contain HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.conf.template or set ENABLE_HTTPS=no in .env."
    exit 1
  fi
else
  cp etc/webserver/nginx.nossl.conf.template etc/webserver/nginx.conf
  if grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does contains HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.nossl.conf.template or set ENABLE_HTTPS=yes in .env."
    exit 1
  fi
fi

# Set proper urls
sed_i 's|\${MANAGEMENT_PORTAL_URL}|'"${MANAGEMENT_PORTAL_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${DASHBOARD_URL}|'"${DASHBOARD_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${PORTAINER_URL}|'"${PORTAINER_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${REST_API_URL}|'"${REST_API_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${KAFKA_MANAGER_URL}|'"${KAFKA_MANAGER_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${RADAR_REST_SOURCES_URL}|'"${RADAR_REST_SOURCES_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${RADAR_REST_SOURCES_BACKEND_URL}|'"${RADAR_REST_SOURCES_BACKEND_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${REDCAP_INTEGRATION_APP_URL}|'"${REDCAP_INTEGRATION_APP_URL}"'|' etc/webserver/nginx.conf

inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
  init_certificate "${SERVER_NAME}"
else
  # Fill in reverse proxy servers
  proxies=
  for PROXY in ${NGINX_PROXIES:-}; do
    proxies="${proxies}set_real_ip_from ${PROXY}; "
  done
  sed_i "s/^\(\s*\).*# NGINX_PROXIES/\1$proxies# NGINX_PROXIES/" etc/webserver/nginx.conf
fi


echo "==> Configuring Kafka-manager password"
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${KAFKA_MANAGER_USERNAME}" "${KAFKA_MANAGER_PASSWORD}" > etc/webserver/kafka-manager.htpasswd


sudo-linux docker-compose up -d

if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
fi
