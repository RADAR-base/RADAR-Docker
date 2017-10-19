#!/bin/bash

. ./util.sh
# set initial time of file
LTIME=`stat -c %Z ./etc/redcap-integration/radar.yml`

while true    
do
   ATIME=`stat -c %Z ./etc/redcap-integration/radar.yml`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       sudo-linux docker restart radarcphadoopstack_radar-integration_1 
       LTIME=$ATIME
   fi
   sleep 5
done
