#!/bin/bash

set -eu

pushd .
cd /home/ec2-user/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack
./bin/radar-docker down
popd

rm -rf /home/ec2-user/RADAR-Docker
