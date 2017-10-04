#!/bin/bash

# Check if variables exist
if [ -z "$CONNECT_ZOOKEEPER_CONNECT" ]; then
        echo "CONNECT_ZOOKEEPER_CONNECT is not defined"
        exit 2
fi

if [ -z "$TOPIC_LIST" ]; then
        echo "TOPIC_LIST is not defined"
        exit 2
fi

# Save current IFS
SAVEIFS=$IFS

# Fetch env topic list
IFS=', ' read -r -a needed <<< $TOPIC_LIST

# Fetch env topic list
IFS=$'\n'
count=0
interval=1
max_retryes=15
while [ "$count" != "${#needed[@]}" ] ; do

    if [ "$max_retryes" -eq "0" ] ; then
        IFS=$SAVEIFS
        echo "Force rebooting  ... "
        exit 2
    fi

    count=0
    topics=$(kafka-topics --list --zookeeper $CONNECT_ZOOKEEPER_CONNECT)
    topics=($topics)

    for topic in "${topics[@]}"
    do
        for need in "${needed[@]}"
        do
            if [ "$topic" = "$need" ] ; then
                ((count++))
            fi
        done
    done

    if [ "$count" != "${#needed[@]}" ] ; then
        echo "Waiting $interval second before retrying ..."
        sleep $interval
        if (( interval < 30 )); then
                ((interval=interval*2))
        fi
        ((max_retryes--))
    fi
done

echo "All topics are now available. Ready to go!"
