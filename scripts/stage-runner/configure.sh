#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack

cp ./etc/env.template ./.env
cp ./etc/managementportal/config/oauth_client_details.csv.template ./etc/managementportal/config/oauth_client_details.csv
cp ./etc/radar-backend/radar.yml.template ./etc/radar-backend/radar.yml
cp ./etc/webserver/optional-services.conf.template ./etc/webserver/optional-services.conf

sed -i "" "s|SERVER_NAME=localhost|SERVER_NAME=radar-backend.co.uk|" ./.env
sed -i "" "s|MANAGEMENTPORTAL_KEY_DNAME=CN=localhost,OU=MyName,O=MyOrg,L=MyCity,S=MyState,C=MyCountryCode|MANAGEMENTPORTAL_KEY_DNAME=CN=radar-backend.co.uk,OU=MyName,O=MyOrg,L=MyCity,S=MyState,C=MyCountryCode|" ./.env
sed -i "" "s|MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET=|MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET=travel.COUNTRY.flowers|" ./.env
sed -i "" "s|SELF_SIGNED_CERT=yes|SELF_SIGNED_CERT=no|" ./.env
sed -i "" "s|MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT=false|MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT=true|" ./.env
sed -i "" "s|ENABLE_OPTIONAL_SERVICES=false|ENABLE_OPTIONAL_SERVICES=true|" ./.env

# Why RADAR_SCHEMAS_VERSION has been hard coded in etc/env.template?
sed -i "" "s|RADAR_SCHEMAS_VERSION=0.5.1|RADAR_SCHEMAS_VERSION=0.5.5|" ./.env

portainer_password_hash=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendPortainerPasswordHash --with-decryption --query Parameters[0].Value)
portainer_password_hash=$(echo $portainer_password_hash | sed -e 's/^"//' -e 's/"$//')
sed -i "" "s|PORTAINER_PASSWORD_HASH=|PORTAINER_PASSWORD_HASH=$portainer_password_hash|" ./.env

managementportal_common_admin_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendManagementportalCommonAdminPassword --with-decryption --query Parameters[0].Value)
managementportal_common_admin_password=$(echo $managementportal_common_admin_password | sed -e 's/^"//' -e 's/"$//')
sed -i "" "s|MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD=|MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD=$managementportal_common_admin_password|" ./.env

gmail_user=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendGmailUser --with-decryption --query Parameters[0].Value)
gmail_user=$(echo $gmail_user | sed -e 's/^"//' -e 's/"$//')
gmail_password=$(aws ssm get-parameters --region eu-west-1 --names RadarBackendGmailPassword --with-decryption --query Parameters[0].Value)
gmail_password=$(echo $gmail_password | sed -e 's/^"//' -e 's/"$//')
cat > ./etc/smtp.env << EOF
GMAIL_USER=$gmail_user
GMAIL_PASSWORD=$gmail_password
RELAY_NETWORKS=:172.0.0.0/8:192.168.0.0/16
EOF

popd