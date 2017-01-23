#!/bin/bash

# Check if first execution
if [ -f /home/.radar_topic_set ]; then
	echo "*********************************************"
	echo "**  RADAR-CNS topics are ready to be used  **"
	echo "*********************************************"
    exit 0
fi

# Check if variables exist
if [ -z "$RADAR_TOPICS" ]; then
	echo "$RADAR_TOPICS is not defined"
	exit 126
fi

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
        echo "$KAFKA_ZOOKEEPER_CONNECT is not defined"
        exit 126
fi

if [ -z "$RADAR_PARTITIONS" ]; then
        echo "$PARTITIONS is not defined"
        exit 126
fi

if [ -z "$RADAR_REPLICATION_FACTOR" ]; then
        echo "$PARTITIONS is not defined"
        exit 126
fi

# Create topics
echo "Creating RADAR-CNS topicsi..."
IFS=', ' read -r -a array <<< "$RADAR_TOPICS"

for element in "${array[@]}"
do
    echo "===> Creating $element"
    kafka-topics --zookeeper $KAFKA_ZOOKEEPER_CONNECT --create --topic $element --partitions $RADAR_PARTITIONS  --replication-factor $RADAR_REPLICATION_FACTOR --if-not-exists
done

touch /home/.radar_topic_set

echo "Topics created!"

echo "*******************************************"
echo "**  RADAR-CNS topics have been created   **"
echo "*******************************************"
