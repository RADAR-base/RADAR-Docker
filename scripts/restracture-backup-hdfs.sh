#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin

# log file
logfile=

# working directory
working_directory=

# landing folder
storage_directory=

# lock file
lockfile=

# involved HDFS directory
hdfs_directory=/topicAndroidNew

# maximum file size in byte  to rotate log
minimumsize=10000000

# current time
timestamp=$(date '+%Y-%m-%d %H:%M:%S');

# write message in the log file
log_info() {
  echo "$timestamp - $@" >> $logfile 2>&1
}

# remove old lock
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

# extract file from hdfs to backup storage if no other instance is running
touch $logfile
log_info "### $timestamp ###"
log_info "Checking lock ..."
if [ ! -f $lockfile ]; then
  log_info "Creating lock ..."
  touch $lockfile
  (cd $working_directory && ./hdfs_restructure.sh $hdfs_directory $storage_directory >> $logfile 2>&1)
  log_info "Removing lock ..."
  rm $lockfile
else
  log_info "Another instance is already running ... "
fi
log_info "### DONE ###"

# check if log size exceeds the limit. If so, it rotates the log file
actualsize=$(wc -c <"$logfile")

if [ $actualsize -ge $minimumsize ]; then
  timestamp=$(date '+%d-%m-%Y_%H-%M-%S');
  cp $logfile $logfile"_"$timestamp
  > $logfile
fi