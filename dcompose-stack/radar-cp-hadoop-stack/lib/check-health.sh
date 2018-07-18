#!/bin/bash
# Check whether services are healthy. If not, restart them and notify the maintainer.

cd "$( dirname "${BASH_SOURCE[0]}" )/.."

stack=bin/radar-docker
. lib/util.sh
. ./.env

function hipchat_notify() {
    # Send notification via HipChat, if configured.
    if [ "$HEALTHCHECK_HIPCHAT_NOTIFY" == "yes" ] ; then
        if [ -z "$HEALTHCHECK_HIPCHAT_ROOM_ID" ] ; then
            echo "Error: HipChat notifications are enabled, but \$HEALTHCHECK_HIPCHAT_ROOM_ID is undefined. Unable to send HipChat notification."
            exit 1
        fi

        if [ -z "$HEALTHCHECK_HIPCHAT_TOKEN" ] ; then
            echo "Error: HipChat notifications are enabled, but \$HEALTHCHECK_HIPCHAT_TOKEN is undefined. Unable to send HipChat notification."
            exit 1
        fi

        color=$1
        body=$2
        curl -X POST -H "Content-Type: application/json" --header "Authorization: Bearer $HEALTHCHECK_HIPCHAT_TOKEN" \
             -d "{\"color\": \"$color\", \"message_format\": \"text\", \"message\": \"$body\" }" \
             https://api.hipchat.com/v2/room/$HEALTHCHECK_HIPCHAT_ROOM_ID/notification
    fi
}

unhealthy=()

# get all human-readable service names
# see last line of loop
while read service; do
    # check if a container was started for the service
    container=$(sudo-linux $stack ps -q $service)
    if [ -z "${container}" ]; then
        # no container means no running service
        continue
    fi
    health=$(sudo-linux docker inspect --format '{{.State.Health.Status}}' $container 2>/dev/null || echo "null")
    if [ "$health" = "unhealthy" ]; then
        echo "Service $service is unhealthy. Restarting."
        unhealthy+=("${service}")
        sudo-linux $stack restart ${service}
    fi
done <<< "$(sudo-linux $stack config --services)"

display_host="${SERVER_NAME} ($(hostname -f), $(curl -s http://ipecho.net/plain))"

if [ "${#unhealthy[@]}" -eq 0 ]; then
    if [ -f .unhealthy ]; then
         rm -f .unhealthy
         hipchat_notify green "All services on ${display_host} are healthy again"
    fi
    echo "All services are healthy"
else
    echo "$unhealthy services were unhealthy and have been restarted."

    # Send notification to MAINTAINER
    # start up the mail container if not already started
    sudo-linux $stack up -d smtp
    # ensure that all topics are available
    sudo-linux $stack run --rm kafka-init
    # save the container, so that we can use exec to send an email later
    container=$(sudo-linux $stack ps -q smtp)
    SAVEIFS=$IFS
    IFS=,
    display_services="[${unhealthy[*]}]"
    IFS=$SAVEIFS
    body="Services on ${display_host} are unhealthy. Services $display_services have been restarted. Please log in for further information."
    echo "Sent notification to $MAINTAINER_EMAIL"
    echo "$body" | sudo-linux docker exec -i ${container} mail -aFrom:$FROM_EMAIL "-s[RADAR] Services on ${SERVER_NAME} unhealthy" $MAINTAINER_EMAIL

    echo "${unhealthy[@]}" > .unhealthy

    hipchat_notify red "$body"

    exit 1
fi
