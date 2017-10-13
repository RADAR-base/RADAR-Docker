#!/bin/bash

. ./util.sh

echo "==> Restarting RADAR-CNS Platform"
sudo-linux docker-compose restart
