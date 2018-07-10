#!/usr/bin/env bash

PIG_VERSION="0.16.0"

OUTPUT_DIR="./tmp"
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd)/$(basename "$OUTPUT_DIR")"

TOPICS_FILE="./topics_to_remove.txt"
HDFS_NAME_NODE='hdfs://hdfs-namenode:8020'
DELETE="false"
SKIP_TRASH=""

# HDFS command to get FS image file from hdfs name node
HDFS_COMMAND_IMAGE=(hdfs dfsadmin -fetchImage /fsimage_tmp/hdfs.image)
# Can also use (curl --silent "http://hdfs-namenode:50070/imagetransfer?getimage=1&txid=latest" -o /fsimage_tmp/hdfs.image)

# HDFS command to create text file from FSImage file
HDFS_COMMAND_TEXT=(hadoop oiv -i /fsimage_tmp/hdfs.image -o /fsimage_tmp/hdfs.txt -p Delimited -delimiter ,)
DOCKER_COMMAND=(docker run -i --rm --network hadoop -v "${OUTPUT_DIR}:/fsimage_tmp" -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2)



if [[ ! -d 'tmp' ]]; then
  mkdir tmp
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--delete)
    DELETE="true"
    shift # past argument
    ;;
    -st|--skip-trash)
    SKIP_TRASH="-skipTrash"
    shift # past argument
    ;;
    -u|--url)
    HDFS_NAME_NODE="$2"
    shift # past argument
    shift # past value
    ;;
    -tf|--topics-file)
    TOPICS_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    -dt|--date)
    if [[ "$2" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])[[:space:]]([0-1][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
      # All records for appropriate topics before this date will be removed from HDFS.
      date_time_to_remove_before="$2"
    else
      echo "Invalid date. Please use -h or --help for more information."
      exit 1
    fi
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Usage: ./hdfs_data_retention.sh -u <hdfs namenode url> -tf <name of the topics file> -dt <date and time to delete before> -d"
    echo "Options: * means required"
    echo "  -d|--delete: enable delete for the data. If not specified, the size of selected files is displayed."
    echo "  -st|--skip-trash: Enables skipTrash option for <hdfs dfs -rm>. To be used with -d|--delete option."
    echo "  -h|--help: Displays this help."
    echo "* -u|--url: The HDFS namenode Url to connect to. Default is hdfs://hdfs-namenode:8020"
    echo "* -tf|--topics-file: The path of the file containing the newline-separated list of topics to remove the files from. Default is ./topics_to_remove.txt"
    echo "* -dt|--date: All the files modified before this date time will be selected. Format is (yyyy-MM-dd HH:mm)"
    exit 0
    ;;
    *)    # unknown option
    echo "Unknown Option $1. Try again. Use -h or --help for more info."
    exit 1
    ;;
esac
done

if [[ -z "$date_time_to_remove_before" ]]; then
  echo "Please specify a date and time. See -h or --help for more information."
  exit 1
fi

if [[ -f "./tmp/hdfs.image" ]]; then
  if [[ $(find ./tmp/hdfs.image -mtime +1 -print) ]]; then
    echo "./tmp/hdfs.image is older than a day. Downloading a new FS image file. "
    ${DOCKER_COMMAND[@]} ${HDFS_COMMAND_IMAGE[@]}
    ${DOCKER_COMMAND[@]} ${HDFS_COMMAND_TEXT[@]}
  fi
else
  echo "Downloading a new FS image file and converting to txt. "
  ${DOCKER_COMMAND[@]} ${HDFS_COMMAND_IMAGE[@]}
  ${DOCKER_COMMAND[@]} ${HDFS_COMMAND_TEXT[@]}
fi

# Set this if get JAVA_HOME not set error or set it in ~/.profile
#export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

# Download and configure apache pig
export PIG_HOME="$(pwd)"/pig-"${PIG_VERSION}"
export PATH=$PATH:"$(pwd)"/pig-"${PIG_VERSION}"/bin

if ! hash "pig" >/dev/null 2>&1; then
  wget http://www-us.apache.org/dist/pig/pig-"${PIG_VERSION}"/pig-"${PIG_VERSION}".tar.gz
  tar -xzf pig-"${PIG_VERSION}".tar.gz
  export PATH=$PATH:"$(pwd)"/pig-"${PIG_VERSION}"/bin
fi

# Write all the relevant file paths to file using apache pig
pig -x local -param inputFile=./tmp/hdfs.txt -param outputFile=./tmp/final_paths -param topics=${TOPICS_FILE} -param time="${date_time_to_remove_before}" ./hdfs_get_relevant_files.pig

FINAL_PATH='./tmp/final_paths/part-r-00000'
#NUMOFLINES=$(wc -l < "${FINAL_PATH}")
# If delete is passed as an argument, only then delete the files from the HDFS.
if [[ "${DELETE}" = "true" ]]; then
  docker run -i -d --name "hdfs-delete" --network hadoop -v "${OUTPUT_DIR}:/fsimage_tmp" -e "CORE_CONF_fs_defaultFS=${HDFS_NAME_NODE}" uhopper/hadoop:2.7.2 /bin/bash
  # Wait for the container to start up
  sleep 30
  if [[ -f "${FINAL_PATH}" ]]; then
    echo "READING AND REMOVING RELEVANT PATHS"
    docker exec hdfs-delete bash -c 'apt-get -y install pv && pv -pte /fsimage_tmp/final_paths/part-r-00000 | xargs -n 100 hdfs dfs -rm ${SKIP_TRASH}'
  fi
  # Delete the image after delete operation is complete
  rm -r ./tmp/hdfs.*
  docker rm -f hdfs-delete
fi

rm -r ./tmp/final_paths/
