#!/bin/bash
echo "Starting to configure mock configurations for test"

# create folder for docker volumes
mkdir -p /home/travis/data

# setup mock configs
cp ./travis-env.template ../.env
cp ./travis-smtp.template ../etc/smtp.env
cp ../etc/radar-backend/radar.yml.template ../etc/radar-backend/radar.yml
cp ../etc/webserver/nginx.conf.template ../etc/webserver/nginx.conf
cp ../etc/hdfs-connector/sink-hdfs.properties.template ../etc/hdfs-connector/sink-hdfs.properties
cp ../etc/mongodb-connector/sink-mongo.properties.template ../etc/mongodb-connector/sink-mongo.properties
cp ../etc/managementportal/config/oauth_client_details.csv.template ../etc/managementportal/config/oauth_client_details.csv
cp ../etc/redcap-integration/radar.yml.template ../etc/redcap-integration/radar.yml

../bin/keystore-init

echo "Setting up mock configurations finished..."
