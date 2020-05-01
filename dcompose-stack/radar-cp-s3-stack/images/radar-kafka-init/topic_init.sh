#!/bin/bash

# Create topics
echo "Creating RADAR-base topics..."

if ! radar-schemas-tools create -p $KAFKA_NUM_PARTITIONS -r $KAFKA_NUM_REPLICATION -b $KAFKA_NUM_BROKERS "${KAFKA_ZOOKEEPER_CONNECT}" merged; then
  echo "FAILED TO CREATE TOPICS"
  exit 1
fi


echo "Topics created."

echo "Registering RADAR-base schemas..."

tries=10
timeout=1
max_timeout=32
while true; do
  if curl -Ifs "${KAFKA_SCHEMA_REGISTRY}" > /dev/null; then
    break;
  fi
  tries=$((tries - 1))
  if [ $tries = 0 ]; then
    echo "FAILED TO REACH SCHEMA REGISTRY. SCHEMAS NOT REGISTERED"
    exit 1
  fi
  echo "Failed to reach schema registry. Retrying in ${timeout} seconds."
  sleep $timeout
  if [ $timeout -lt $max_timeout ]; then
    timeout=$((timeout * 2))
  fi
done

if ! radar-schemas-tools register --force "${KAFKA_SCHEMA_REGISTRY}" merged; then
  echo "FAILED TO REGISTER SCHEMAS"
  exit 1
fi

echo "Schemas registered."

echo "*******************************************"
echo "**  RADAR-base topics and schemas ready   **"
echo "*******************************************"
