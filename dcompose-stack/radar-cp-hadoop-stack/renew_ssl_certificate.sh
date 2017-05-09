#!/bin/bash

. ./util.sh
. ./.env

if [ -z ${SERVER_NAME} ]; then
  echo "Set SERVER_NAME variable in .env"
  exit 1
fi

request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}" force
