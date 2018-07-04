#!/usr/bin/env bash

# All records for appropriate topics before this date will be removed from HDFS.
date_time_to_remove_before='2018-03-15 12:00'

OUTPUT_DIR="./tmp"
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd)/$(basename "$OUTPUT_DIR")"

HDFS_NAME_NODE='hdfs://hdfs-namenode:8020'

# HDFS command to get FS image file from hdfs name node
HDFS_COMMAND_IMAGE=(hdfs dfsadmin -fetchImage /fsimage_tmp/hdfs.image)
# Can also use (curl --silent "http://hdfs-namenode:50070/imagetransfer?getimage=1&txid=latest" -o /fsimage_tmp/hdfs.image)

# HDFS command to create text file from FSImage file
HDFS_COMMAND_TEXT=(hadoop oiv -i /fsimage_tmp/hdfs.image -o /fsimage_tmp/hdfs.txt -p Delimited -delimiter ,)

if [[ ! -d 'tmp' ]]; then
  mkdir tmp
fi

if [[ ! -f './tmp/hdfs.image' ]]; then
  echo "Downloading a new FS image file at ./tmp and converting to txt."
  docker run -i --rm --network hadoop -v "${OUTPUT_DIR}:/fsimage_tmp" -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2 ${HDFS_COMMAND_IMAGE[@]}

  docker run -i --rm --network hadoop -v "${OUTPUT_DIR}:/fsimage_tmp" -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2 ${HDFS_COMMAND_TEXT[@]}
else
  echo "./tmp/hdfs.image already exists. Using the same FS image file. "
  if [[ ! -f './tmp/hdfs.txt' ]]; then
    docker run -i --rm --network hadoop -v "${OUTPUT_DIR}:/fsimage_tmp" -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2 ${HDFS_COMMAND_TEXT[@]}
  else
    echo "./tmp/hdfs.txt already exists. Not generating a new one. "
  fi
fi


# Set this if get JAVA_HOME not set error or set it in ~/.profile
#export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

# Download and configure apache pig
export PIG_HOME="$(pwd)"/pig-0.16.0
export PATH=$PATH:"$(pwd)"/pig-0.16.0/bin

if ! hash "pig" >/dev/null 2>&1; then
  wget http://www-us.apache.org/dist/pig/pig-0.16.0/pig-0.16.0.tar.gz
  tar -xzf pig-0.16.0.tar.gz
  export PATH=$PATH:"$(pwd)"/pig-0.16.0/bin
fi

# Write all the relevant file paths to file using apache pig
pig -x local -param inputFile=./tmp/hdfs.txt -param outputFile=./tmp/final_paths -param topics=./topics_to_remove.txt -param time="${date_time_to_remove_before}" ./hdfs_get_relevant_files.pig

FINAL_PATH='./tmp/final_paths/part-r-00000'
NUMOFLINES=$(wc -l < "${FINAL_PATH}")
# If delete is passed as an argument, only then delete the files from the HDFS.
if [[ "$1" = "delete" ]]; then
  docker run -i -d --name "hdfs-delete" --network hadoop -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2 /bin/bash
  # Wait for the container to start up
  sleep 30
  if [[ -f "${FINAL_PATH}" ]]; then
    echo "READING AND REMOVING RELEVANT PATHS"
    let "curr_prog = 0"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        docker exec hdfs-delete hdfs dfs -rm "$line" > /dev/null
        echo "Deleted from HDFS file: $line"
        let "curr_prog += 1"
        let "perc_prog = ((curr_prog*100)/NUMOFLINES)"
        echo "Progress: $perc_prog %"
    done < "${FINAL_PATH}"
  fi
  echo "Complete deletion"
  docker rm -f "hdfs-delete"
fi

rm -r ./tmp/final_paths/
