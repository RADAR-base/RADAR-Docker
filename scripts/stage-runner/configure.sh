#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack

ENV_PATH=./.env
readonly ENV_PATH
rm -rf "$ENV_PATH"
touch "$ENV_PATH"

# Configure OAuth client credentials?
cp ./etc/managementportal/config/oauth_client_details.csv.template ./etc/managementportal/config/oauth_client_details.csv

cp ./etc/radar-backend/radar.yml.template ./etc/radar-backend/radar.yml
cp ./etc/redcap-integration/radar.yml.template ./etc/redcap-integration/radar.yml
cp ./etc/fitbit/docker/users/fitbit-user.yml.template ./etc/fitbit/docker/users/fitbit-user.yml
cp ./etc/webserver/ip-access-control.conf.template ./etc/webserver/ip-access-control.conf
cp ./etc/webserver/nginx.conf.template ./etc/webserver/nginx.conf
cp ./etc/webserver/optional-services.conf.template ./etc/webserver/optional-services.conf
cp ./etc/smtp.env.template ./etc/smtp.env
cp ./etc/hdfs-restructure/restructure.yml.template ./etc/hdfs-restructure/restructure.yml

function _get_param () {
    local param_value=$(aws ssm get-parameters --region eu-west-1 --names $1 --query Parameters[0].Value)
    param_value=$(echo "$param_value" | sed -e 's/^"//' -e 's/"$//')
    echo $param_value
}

function _get_decrypted_param () {
    local param_value=$(aws ssm get-parameters --region eu-west-1 --names $1 --with-decryption --query Parameters[0].Value)
    param_value=$(echo "$param_value" | sed -e 's/^"//' -e 's/"$//')
    echo $param_value
}

function _get_secure_file() {
    local file_content=$(_get_decrypted_param "$1")
    printf "%b\n" "$file_content" > $2
}

IFS="="
while read -r key val
do
    if [[ "$key" == "SERVER_NAME" ]]; then
        echo "$key=radar-backend.co.uk" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_KEY_DNAME" ]]; then
        echo "$key=CN=radar-backend.co.uk,OU=MyName,O=MyOrg,L=MyCity,S=MyState,C=MyCountryCode" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET" ]]; then
        echo "$key=travel.COUNTRY.flowers" >> ./.env
    elif [[ "$key" == "SELF_SIGNED_CERT" ]]; then
        echo "$key=no" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT" ]]; then
        echo "$key=true" >> ./.env
    elif [[ "$key" == "ENABLE_OPTIONAL_SERVICES" ]]; then
        echo "$key=true" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_USERNAME" ]]; then
        value=$(_get_decrypted_param "RadarBackendHotstorageUsername")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendHotstoragePassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_NAME" ]]; then
        value=$(_get_decrypted_param "RadarBackendHotstorageName")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "POSTGRES_USER" ]]; then
        value=$(_get_decrypted_param "RadarBackendPostgresUser")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "POSTGRES_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendPostgresPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "KAFKA_MANAGER_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendKafkaManagerPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "PORTAINER_PASSWORD_HASH" ]]; then
        value=$(_get_decrypted_param "RadarBackendPortainerPasswordHash")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendManagementportalCommonAdminPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "TIMESCALEDB_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendTimescaledbPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "GRAFANA_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendGrafanaPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD" ]]; then
        value=$(_get_decrypted_param "RadarBackendManagementportalCommonAdminPassword")
        echo "$key=$value" >> ./.env
    else
        echo "$key=$val" >> ./.env
    fi
done < <(grep . ./etc/env.template)

# Overwrite SMTP environment variables
_get_secure_file "RadarBackendSmtpEnv" ./etc/smtp.env

# Overwrite configuration on output restructure
_get_secure_file "RadarBackendOutputRestructureConfig" ./etc/hdfs-restructure/restructure.yml
mkdir -p ./etc/hdfs-restructure/output/+tmp
chmod -R +w ./etc/hdfs-restructure/output

sed -i -e '2,$s/^#//' ./etc/webserver/optional-services.conf

popd