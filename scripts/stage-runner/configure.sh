#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack

cp ./etc/env.template ./.env

# Configure OAuth client credentials?
cp ./etc/managementportal/config/oauth_client_details.csv.template ./etc/managementportal/config/oauth_client_details.csv

cp ./etc/radar-backend/radar.yml.template ./etc/radar-backend/radar.yml
cp ./etc/redcap-integration/radar.yml.template ./etc/redcap-integration/radar.yml
cp ./etc/fitbit/docker/users/fitbit-user.yml.template ./etc/fitbit/docker/users/fitbit-user.yml
cp ./etc/webserver/ip-access-control.conf.template ./etc/webserver/ip-access-control.conf
cp ./etc/webserver/nginx.conf.template ./etc/webserver/nginx.conf

sed -i "s|SERVER_NAME=localhost|SERVER_NAME=radar-backend.co.uk|" ./.env
sed -i "s|MANAGEMENTPORTAL_KEY_DNAME=CN=localhost,OU=MyName,O=MyOrg,L=MyCity,S=MyState,C=MyCountryCode|MANAGEMENTPORTAL_KEY_DNAME=CN=radar-backend.co.uk,OU=MyName,O=MyOrg,L=MyCity,S=MyState,C=MyCountryCode|" ./.env
sed -i "s|MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET=|MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET=travel.COUNTRY.flowers|" ./.env
sed -i "s|SELF_SIGNED_CERT=yes|SELF_SIGNED_CERT=no|" ./.env
sed -i "s|MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT=false|MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT=true|" ./.env
sed -i "s|ENABLE_OPTIONAL_SERVICES=false|ENABLE_OPTIONAL_SERVICES=true|" ./.env

# Why RADAR_SCHEMAS_VERSION has been hard coded in etc/env.template?
sed -i "s|RADAR_SCHEMAS_VERSION=0.5.1|RADAR_SCHEMAS_VERSION=0.5.5|" ./.env

hotstorage_username=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendHotstorageUsername --with-decryption --query Parameters[0].Value)
hotstorage_username=$(echo $hotstorage_username | sed -e 's/^"//' -e 's/"$//')
sed -i "s|HOTSTORAGE_USERNAME=mongodb-user|HOTSTORAGE_USERNAME=$hotstorage_username|" ./.env

hotstorage_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendHotstoragePassword --with-decryption --query Parameters[0].Value)
hotstorage_password=$(echo $hotstorage_password | sed -e 's/^"//' -e 's/"$//')
sed -i "s|HOTSTORAGE_PASSWORD=|HOTSTORAGE_PASSWORD=$hotstorage_password|" ./.env

hotstorage_name=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendHotstorageName --with-decryption --query Parameters[0].Value)
hotstorage_name=$(echo $hotstorage_name | sed -e 's/^"//' -e 's/"$//')
sed -i "s|HOTSTORAGE_NAME=mongodb-database|HOTSTORAGE_NAME=$hotstorage_name|" ./.env

postgres_user=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendPostgresUser --with-decryption --query Parameters[0].Value)
postgres_user=$(echo $postgres_user | sed -e 's/^"//' -e 's/"$//')
sed -i "s|POSTGRES_USER=postgresdb-user|POSTGRES_USER=$postgres_user|" ./.env

postgres_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendPostgresPassword --with-decryption --query Parameters[0].Value)
postgres_password=$(echo $postgres_password | sed -e 's/^"//' -e 's/"$//')
sed -i "s|POSTGRES_PASSWORD=|POSTGRES_PASSWORD=$postgres_password|" ./.env

kafka_manager_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendKafkaManagerPassword --with-decryption --query Parameters[0].Value)
kafka_manager_password=$(echo $kafka_manager_password | sed -e 's/^"//' -e 's/"$//')
sed -i "s|KAFKA_MANAGER_PASSWORD=|KAFKA_MANAGER_PASSWORD=$kafka_manager_password|" ./.env

portainer_password_hash=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendPortainerPasswordHash --with-decryption --query Parameters[0].Value)
portainer_password_hash=$(echo $portainer_password_hash | sed -e 's/^"//' -e 's/"$//')
sed -i "s|PORTAINER_PASSWORD_HASH=|PORTAINER_PASSWORD_HASH=$portainer_password_hash|" ./.env

managementportal_common_admin_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendManagementportalCommonAdminPassword --with-decryption --query Parameters[0].Value)
managementportal_common_admin_password=$(echo $managementportal_common_admin_password | sed -e 's/^"//' -e 's/"$//')
sed -i "s|MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD=|MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD=$managementportal_common_admin_password|" ./.env

gmail_user=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendGmailUser --with-decryption --query Parameters[0].Value)
gmail_user=$(echo $gmail_user | sed -e 's/^"//' -e 's/"$//')
gmail_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendGmailPassword --with-decryption --query Parameters[0].Value)
gmail_password=$(echo $gmail_password | sed -e 's/^"//' -e 's/"$//')
cat > ./etc/smtp.env << EOF
GMAIL_USER=$gmail_user
GMAIL_PASSWORD=$gmail_password
RELAY_NETWORKS=:172.0.0.0/8:192.168.0.0/16
EOF

cat > ./etc/webserver/optional-services.conf << EOF
location /redcapint/ {
 proxy_pass         http://radar-integration:8080/redcap/;
 proxy_set_header   Host \$host;
}

location /rest-sources/authorizer/ {
 proxy_pass         http://radar-rest-sources-authorizer:80/;
 proxy_set_header   Host \$host;
}

location /rest-sources/backend/ {
 proxy_pass         http://radar-rest-sources-backend:8080/;
 proxy_set_header   Host \$host;
}

location /grafana/ {
 proxy_pass         http://grafana:3000/;
 proxy_set_header   Host \$host;
}
EOF

popd