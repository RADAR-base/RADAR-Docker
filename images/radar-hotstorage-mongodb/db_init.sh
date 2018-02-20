#!/bin/bash

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MongoDB service startup"
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

if [ -f /data/db/.radar_hotstorage_set ]; then
	echo "**********************************************"
	echo "**  RADAR-base Hotstorage is up and running  **"
	echo "**********************************************"
    exit 0
fi

if [ -z "$RADAR_USER" ]; then
	echo "$RADAR_USER is not defined"
	exit 2
fi

if [ -z "$RADAR_PWD" ]; then
	echo "$RADAR_PWD is not defined"
	exit 2
fi

if [ -z "$RADAR_DB" ]; then
	echo "$RADAR_DB is not defined"
	exit 2
fi

echo "=> MongoDB is ready"

echo "=> Creating DB and User for RADAR-base Hot Storage"

mongo admin --eval 'db.createUser( { user: "'${RADAR_USER}'", pwd: "'${RADAR_PWD}'", roles: [ { role: "root", db: "admin" } ] } )'
mongo admin -u $RADAR_USER -p $RADAR_PWD <<EOF
use $RADAR_DB
db.createUser( { user: "${RADAR_USER}", pwd: "${RADAR_PWD}", roles:[{role:"dbOwner",db:"$RADAR_DB"} ] } );
EOF
mongo $RADAR_DB -u $RADAR_USER -p $RADAR_PWD <<EOF
EOF

touch /data/db/.radar_hotstorage_set

echo ""
echo "*********************************************************"
echo "*********************************************************"
echo "**                                                     **"
echo "**  Your RADAR-base Hotstorage is now ready to be used  **"
echo "**                                                     **"
echo "*********************************************************"
echo "*********************************************************"

# docker build -t radarcns/radar-mongodb ./
# docker run -it --expose=27017 --name=mongodbPilot -p 27017:27017 radarcns/radar-mongodb
# docker exec -i -t mongodbPilot /bin/bash
# mongo hotstorage -u restapi -p radar


