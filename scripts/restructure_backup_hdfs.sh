#!/bin/bash

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

. ./util.sh

# extract file from hdfs to backup storage if no other instance is running
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
rolloverLog