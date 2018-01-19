#!/bin/bash

. ./util.sh
. ./.env

check_command_exists docker

sudo-linux docker system prune --filter "label!=certs" "$@" && \
  sudo-linux rm -rf "$HDFS_DATA_DIR_1" && \
  sudo-linux rm -rf "$HDFS_DATA_DIR_2" && \
  sudo-linux rm -rf "$HDFS_NAME_DIR_1" && \
  sudo-linux rm -rf "$HDFS_NAME_DIR_2" && \
  sudo-linux rm -rf "$MONGODB_DIR" && \
  sudo-linux rm -rf "$MP_POSTGRES_DIR"

