#!/bin/sh

# Create topics
echo "Creating RADAR-CNS topics..."

if ! radar-schemas-tools create -p $KAFKA_NUM_PARTITIONS -r $KAFKA_NUM_REPLICATION -b $KAFKA_NUM_BROKERS "${KAFKA_ZOOKEEPER_CONNECT}" merged; then
  echo "FAILED TO CREATE TOPICS"
  exit 1
fi

echo "Topics created."

echo "Registering RADAR-CNS schemas..."

tries=10
timeout=1
max_timeout=32
while true; do
  if wget --spider -q "${KAFKA_SCHEMA_REGISTRY}" 2>/dev/null; then
    break;
  fi
  tries=$((tries - 1))
  if [ $tries = 0 ]; then
    echo "FAILED TO REACH SCHEMA REGISTRY. SCHEMAS NOT REGISTERED"
    exit 1
  fi
  echo "Failed to reach schema registry. Retrying in ${timeout} seconds."
  sleep $timeout
  timeout=$((timeout * 2 < max_timeout ? timeout * 2 : max_timeout))
done

if ! radar-schemas-tools register "${KAFKA_SCHEMA_REGISTRY}" merged; then
  echo "FAILED TO REGISTER SCHEMAS"
  exit 1
fi

echo "Schemas registered."

echo "*******************************************"
echo "**  RADAR-CNS topics and schemas ready   **"
echo "*******************************************"
