#!/bin/bash

. ./util.sh

echo "==> Restarting RADAR-CNS Platform"
sudo-docker-compose restart
