#!/bin/bash

check_command_exists() {
  if command -v "$1" > /dev/null 2>&1; then
    echo "$1 version: $($1 --version)"
  else
    echo "RADAR-CNS cannot start without $1. Please, install $1 and then try again"
    exit 1
  fi
}

check_parent_exists() {
  if [ -z "$2" ]; then
    echo "Directory variable $1 is not set in .env"
  fi
  PARENT=$(dirname $2)
  if [ ! -d "${PARENT}" ]; then
    echo "RADAR-CNS stores volumes at ${PARENT}. If this folder does not exist, please create the entire path and then try again"
    exit 1
  fi
}

sudo-docker() {
  if [ $(uname) == "Darwin" ]; then
    docker "$@"
  else
    sudo docker "$@"
  fi
}

sudo-docker-compose() {
  if [ $(uname) == "Darwin" ]; then
    docker-compose "$@"
  else
    sudo docker-compose "$@"
  fi
}

sedi() {
  if [ $(uname) == "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i -- "$@"
  fi
}

echo "OS version: "$(uname -a)
check_command_exists docker
check_command_exists docker-compose
