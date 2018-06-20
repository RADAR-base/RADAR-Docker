#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin

# maximum file size in byte  to rotate log
minimumsize=10000000

# current time
timestamp=$(date '+%Y-%m-%d %H:%M:%S');

# Write message in the log file
log_info() {
  echo "$timestamp - $@" >> $logfile 2>&1
}

# Remove old lock
checkLock() {
  uptime=$(</proc/uptime)
  uptime=${uptime%%.*}

  if [ "$uptime" -lt "180" ]; then
     if [ -f $lockfile ]; then
       rm $lockfile
       log_info "Removed old lock"
     fi
  fi
}

# Rolling log file
rolloverLog() {
  actualsize=$(wc -c <"$logfile")
  if [ $actualsize -ge $minimumsize ]; then
    timestamp=$(date '+%d-%m-%Y_%H-%M-%S');
    cp $logfile $logfile"_"$timestamp
    > $logfile
  fi
}

# Entry point
touch $logfile
log_info "### $timestamp ###"
log_info "Checking lock ..."
checkLock
