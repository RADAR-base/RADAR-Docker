#!/bin/bash

# network interface
network=eduroam
# network interface
nic=wlp5s1
# lock file
lockfile=/home/radar/RADAR-Network/LOCK_RETRY
# log file
logfile=/home/radar/RADAR-Network/radar-network.log
# url to check against
url=https://www.empatica.com

. ./util.sh

# check connection and force reconnection if needed
if [ ! -f $lockfile ]; then
  touch $lockfile
  if ! isConnected; then
    connect
  fi
  rm $lockfile
else
  log_info "Another instance is already running ... "
fi
log_info "### DONE ###"

# check if log size exceeds the limit. If so, it rotates the log file
rolloverLog
