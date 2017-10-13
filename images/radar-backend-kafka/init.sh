#!/bin/bash

# Busy waiting loop that waits untill all topic are available 
echo "===> Waiting RADAR-CNS topics ... "
./home/kafka_status.sh

# Start streams
echo "===> Starting " $1 "...."
./usr/bin/java -jar /usr/share/java/radar-backend-*.jar -c /etc/radar.yml $1