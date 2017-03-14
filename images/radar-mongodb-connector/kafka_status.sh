#!/bin/bash

# Check if variables exist
if [ -z "$KAFKA_REST_PROXY" ]; then
        echo "KAFKA_REST_PROXY is not defined"
        exit 2
fi

if [ -z "$TOPIC_LIST" ]; then
        echo "TOPIC_LIST is not defined"
        exit 2
fi

# Fetch env topic list
IFS=', ' read -r -a needed <<< $TOPIC_LIST

# Fetch env topic list
count=0
interval=1
max_retryes=5
while [ "$count" != "${#needed[@]}" ] ; do

    if [ "$max_retryes" -eq "0" ] ; then
        echo "Error connecting to Rest-Proxy ... "
        echo "Rebooting  ... "
        exit 2
    fi

    echo "Waiting $interval second before retrying ..."
    sleep $interval
    if (( interval < 30 )); then
        ((interval=interval*2))
    fi

    count=0
    TOPICS=$(curl -sSX GET -H "Content-Type: application/json" "$KAFKA_REST_PROXY/topics")
    curl_result=$?
    TOPICS="$(echo -e "${TOPICS}" | tr -d '"'  | tr -d '['  | tr -d ']' | tr -d '[:space:]' )"

    IFS=',' read -r -a array <<< $TOPICS
    for topic in "${array[@]}"
    do
        for need in "${needed[@]}"
        do
            if [ "$topic" = "$need" ] ; then
                ((count++))
            fi
        done
    done

    if [ "$curl_result" -ne "0" ] ; then
         ((max_retryes--))
    fi
done

echo "All topics are now available. Ready to go!"
