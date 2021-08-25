#!/bin/bash

set -eu

if [ -d "/home/ec2-user/RADAR-Docker" ]; then
    pushd .
    cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack
    ./bin/radar-docker down
    popd
    rm -rf /home/ec2-user/RADAR-Docker
fi

# Remove nginx if installed to free port 80
systemctl stop nginx
systemctl disable nginx.service
systemctl daemon-reload
apt-get -y remove nginx nginx-common

# Configure container logs
cat <<EOF > /etc/docker/daemon.json
{
    "log-opts": {
        "max-size": "30m",
        "max-file": "7"
    }
}
EOF
systemctl restart docker
