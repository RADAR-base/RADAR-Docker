#!/bin/bash

# Check if first execution
if [ -f /home/.radar_topic_set ]; then
	echo "*********************************************"
	echo "**  RADAR-CNS topics are ready to be used  **"
	echo "*********************************************"
    exit 0
fi

# Wait untill all brokers are up & running
interval=1
while [ "$LENGTH" != "$KAFKA_BROKERS" ]; do
    BROKERS=$(curl -sS $KAFKA_REST_PROXY/brokers)
    BROKERS="$(echo -e "${BROKERS:12}" | tr -d '[:space:]'  | tr -d '}'  | tr -d ']')"

    IFS=',' read -r -a array <<< $BROKERS
    LENGTH=${#array[@]}

    if [ "$LENGTH" != "$KAFKA_BROKERS" ]; then
        echo "Expected $KAFKA_BROKERS brokers but found only $LENGTH. Waiting $interval second before retrying ..."         
        sleep $interval
        if (( interval < 30 )); then
            ((interval=interval*2))
        fi
    fi
done


# Check if variables exist
if [ -z "$RADAR_TOPICS" ]; then
	echo "RADAR_TOPICS is not defined"
	exit 126
fi

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
        echo "KAFKA_ZOOKEEPER_CONNECT is not defined"
        exit 126
fi

if [ -z "$RADAR_PARTITIONS" ]; then
        echo "RADAR_PARTITIONS is not defined"
        exit 126
fi

if [ -z "$RADAR_REPLICATION_FACTOR" ]; then
        echo "RADAR_REPLICATION_FACTOR is not defined"
        exit 126
fi

# Create topics
echo "Creating RADAR-CNS topics..."
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
