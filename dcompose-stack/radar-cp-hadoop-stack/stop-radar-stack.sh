#!/bin/bash

. ./util.sh

echo "==> Stopping RADAR-base Stack"
sudo-linux docker-compose stop
