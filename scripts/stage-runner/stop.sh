#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack
./bin/radar-docker down
popd

rm -rf /home/ec2-user/RADAR-Docker

# Remove nginx if installed to free port 80
systemctl stop nginx
systemctl disable nginx.service
systemctl daemon-reload
apt-get -y remove nginx nginx-common
