#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack

rm -rf ./.env
touch ./.env

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

function get_param () {
    local param_value=$(aws ssm get-parameters --region eu-west-1 --names $1 --query Parameters[0].Value)
    param_value=$(echo $param_value | sed -e 's/^"//' -e 's/"$//')
    echo $param_value
}

function get_decrypted_param () {
    local param_value=$(aws ssm get-parameters --region eu-west-1 --names $1 --with-decryption --query Parameters[0].Value)
    param_value=$(echo $param_value | sed -e 's/^"//' -e 's/"$//')
    echo $param_value
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
    elif [[ "$key" == "RADAR_SCHEMAS_VERSION" ]]; then
        value=$(get_param "RadarBackendRadarSchemasVersion")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_USERNAME" ]]; then
        value=$(get_decrypted_param "RadarBackendHotstorageUsername")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendHotstoragePassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "HOTSTORAGE_NAME" ]]; then
        value=$(get_decrypted_param "RadarBackendHotstorageName")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "POSTGRES_USER" ]]; then
        value=$(get_decrypted_param "RadarBackendPostgresUser")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "POSTGRES_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendPostgresPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "KAFKA_MANAGER_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendKafkaManagerPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "PORTAINER_PASSWORD_HASH" ]]; then
        value=$(get_decrypted_param "RadarBackendPortainerPasswordHash")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendManagementportalCommonAdminPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "TIMESCALEDB_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendTimescaledbPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "GRAFANA_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendGrafanaPassword")
        echo "$key=$value" >> ./.env
    elif [[ "$key" == "MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD" ]]; then
        value=$(get_decrypted_param "RadarBackendManagementportalCommonAdminPassword")
        echo "$key=$value" >> ./.env
    else
        echo "$key=$val" >> ./.env
    fi
done < <(grep . ./etc/env.template)

gmail_user=$(get_decrypted_param "RadarBackendGmailUser")
gmail_password=$(get_decrypted_param "RadarBackendGmailPassword")
cat > ./etc/smtp.env << EOF
GMAIL_USER=$gmail_user
GMAIL_PASSWORD=$gmail_password
RELAY_NETWORKS=:172.0.0.0/8:192.168.0.0/16
EOF

output_restructure_config=$(get_decrypted_param "RadarBackendOutputRestructureConfig")
echo "$output_restructure_config" > ./etc/hdfs-restructure/restructure.yml
mkdir -p ./etc/hdfs-restructure/output/+tmp
chmod -R +w ./etc/hdfs-restructure/output

sed -i -e '2,$s/^#//' ./etc/webserver/optional-services.conf

popd