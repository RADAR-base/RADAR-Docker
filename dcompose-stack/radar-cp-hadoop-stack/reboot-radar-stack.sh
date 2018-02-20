#!/bin/bash

. ./util.sh

echo "==> Restarting RADAR-base Platform"
sudo-linux docker-compose restart
