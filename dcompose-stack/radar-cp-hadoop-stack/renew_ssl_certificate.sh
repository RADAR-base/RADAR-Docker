#!/bin/bash

. ./util.sh
. ./.env

if [ -z "$SERVER_NAME" ]; then
  echo "Set SERVER_NAME variable in .env"
fi

request_certificate $SERVER_NAME force
