#!/bin/bash

if [[ $# -lt 1 || $1 = "-h" || $1 = "--help" ]]; then
   printf "Usage:\n$0 <hdfs path> [<destination directory>]\nThe destination directory defaults to ./output\n"
   exit 1
fi

. ./util.sh

# HDFS restructure version
JAR_VERSION=0.1.1
# HDFS restructure JAR
JAR="restructurehdfs-all-${JAR_VERSION}.jar"

if [ ! -e "lib/${JAR}" ]; then
  echo "Downloading HDFS restructuring JAR"
  sudo-linux curl -L -# -o lib/${JAR} "https://github.com/RADAR-CNS/Restructure-HDFS-topic/releases/download/v${JAR_VERSION}/${JAR}"
fi

# HDFS filename to get
HDFS_FILE=$1
# Absolute directory to write output to
OUTPUT_DIR=${2:-output}
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd)/$(basename "$OUTPUT_DIR")"
# Internal docker directory to write output to
HDFS_OUTPUT_DIR=/output
# HDFS command to run
HDFS_COMMAND="java -jar /${JAR} hdfs://hdfs-namenode:8020 $HDFS_FILE $HDFS_OUTPUT_DIR"

mkdir -p $OUTPUT_DIR
sudo-linux docker run -i --rm --network hadoop -v "$OUTPUT_DIR:$HDFS_OUTPUT_DIR" -v "$PWD/lib/${JAR}:/${JAR}" openjdk:8-jre-alpine $HDFS_COMMAND
