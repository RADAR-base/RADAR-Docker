#!/bin/bash

if [[ $# -lt 1 || $1 = "-h" || $1 = "--help" ]]; then
   printf "Usage:\n$0 <hdfs path> [<destination directory>]\nThe destination directory defaults to ./output\n"
   exit 1
fi

# HDFS filename to get
HDFS_FILE=$1
# Absolute directory to write output to
OUTPUT_DIR=${2:-output}
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd)/$(basename "$OUTPUT_DIR")"
# Internal docker directory to write output to
HDFS_OUTPUT_DIR=/home/output
# HDFS command to run
HDFS_COMMAND="hdfs dfs -get $HDFS_FILE $HDFS_OUTPUT_DIR"

mkdir -p $OUTPUT_DIR
docker run --rm --network hadoop -v "$OUTPUT_DIR:$HDFS_OUTPUT_DIR" -e CLUSTER_NAME=radar-cns -e CORE_CONF_fs_defaultFS=hdfs://namenode:8020 uhopper/hadoop:2.7.2 $HDFS_COMMAND
