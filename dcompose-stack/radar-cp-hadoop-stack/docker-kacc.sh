#!/bin/bash

# kafka-avro-console-consumer inside dockerized radar platform

if [[ $# -lt 1 || $1 = "-h" || $1 = "--help" || $1 == "--"* ]]; then
   printf "Usage: $0 <topic name> [passthrough options]\n"
   exit 1
fi

#Save command line arguments so functions can access it
#To access command line arguments use syntax ${args[0]} etc
args=("$@")

# get list of available topics
LS_CMD="docker exec -it radarcphadoopstack_kafka-1_1 kafka-topics --zookeeper zookeeper-1:2181 --list"
topics=($($LS_CMD))
#printf "%s\n" "${topics[@]}"

# consumer command to run
KACC_CMD="kafka-avro-console-consumer --zookeeper zookeeper-1:2181 --property schema.registry.url=http://schema-registry-1:8081 --property print.key=true --topic ${args[0]} ${args[@]:1}"
DOCKER_CMD="docker exec -it radarcphadoopstack_schema-registry-1_1"

# check if <topic name> is valid topic
array_contains () {
  local array="$1[@]"
  local seeking=$2
  local in=1
  for element in "${!array}"; do
    element_s=$(echo $element | tr -d '\r')
    seeking_s=$(echo $seeking | tr -d '\r')
    if [[ $element_s == $seeking_s ]]; then
      in=0
      break
    fi
  done
  return $in
}
if ! array_contains topics ${args[0]}; then
  echo -e "Topic ${args[0]} not available. Topics on server are:\n"
  printf "%s\n" "${topics[@]}"
  exit 1
fi

# run consumer
echo $DOCKER_CMD $KACC_CMD
$DOCKER_CMD $KACC_CMD


