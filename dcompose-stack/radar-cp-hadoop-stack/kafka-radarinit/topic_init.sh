#!/bin/sh

# Create topics
echo "Creating RADAR-CNS topics..."

radar-schemas-tools create -p $KAFKA_NUM_PARTITIONS -r $KAFKA_NUM_REPLICATION -b $KAFKA_NUM_BROKERS $KAFKA_ZOOKEEPER_CONNECT merged

echo "Topics created."

echo "Registering RADAR-CNS schemas..."

radar-schemas-tools register $KAFKA_ZOOKEEPER_CONNECT merged

echo "Schemas registered."

echo "*******************************************"
echo "**  RADAR-CNS topics and schemas ready   **"
echo "*******************************************"
