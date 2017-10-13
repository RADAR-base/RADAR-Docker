#!/bin/bash

. ./util.sh

echo "==> Stopping RADAR-CNS Stack"
sudo-linux docker-compose stop
