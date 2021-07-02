#!/bin/bash
echo "Starting to configure mock configurations for test"

# create folder for docker volumes
mkdir -p /home/ci/data

# setup mock configs
cp ./ci-env.template ../.env
cp ./ci-smtp.template ../etc/smtp.env
cp ../etc/webserver/nginx.conf.template ../etc/webserver/nginx.conf
cp ../etc/s3-connector/sink-s3.properties.template ../etc/s3-connector/sink-s3.properties
cp ../etc/mongodb-connector/sink-mongo.properties.template ../etc/mongodb-connector/sink-mongo.properties
cp ../etc/managementportal/config/oauth_client_details.csv.template ../etc/managementportal/config/oauth_client_details.csv
cp ../etc/redcap-integration/radar.yml.template ../etc/redcap-integration/radar.yml
cp ../etc/output-restructure/restructure.yml.template ../etc/output-restructure/restructure.yml

../bin/keystore-init

echo "Setting up mock configurations finished..."
