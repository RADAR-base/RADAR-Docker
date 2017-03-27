#!/bin/bash

# network interface
nic=wlp5s1
# lock file
lockfile=/home/radar/RADAR-Network/LOCK_RETRY
# log file
logfile=/home/radar/RADAR-Network/radar-network.log

# maximum file size in byte  to rotate log
minimumsize=10000000

# current time
timestamp=$(date '+%d/%m/%Y %H:%M:%S');

# write message in the log file
log_info() {
  echo "$timestamp - $@" >> $logfile 2>&1
}

# check connection
isConnected() {
  case "$(curl -s --max-time 5 -I http://www.kcl.ac.uk | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
    [23]) log_info "HTTP connectivity is up" && return 0;;
    5) log_info "The web proxy won't let us through" && return 1;;
    *) log_info "The network is down or very slow" && return 1;;
esac
}

# force connection
connect() {
  log_info "Forcing reconnection"
  sudo ifconfig $nic down >> $logfile 2>&1
  log_info "Turning wifi NIC off"
  sudo ifconfig $nic up >> $logfile 2>&1
  log_info "Turning wifi NIC on"
  #sudo wpa_supplicant -i $nic -Dwext -c/etc/wpa_supplicant/wpa_supplicant.conf >> $logfile 2>&1
  #log_info "Authenticating"
  #sudo dhclient $nic >> $logfile 2>&1
  #log_info "Getting IP address"
  log_info "Completed"
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

# check connection and force reconnection if needed
touch $logfile
checkLock
if [ ! -f $lockfile ]; then
  touch $lockfile
  if ! isConnected; then
    connect
  fi
  rm $lockfile
else
  log_info "Another instance is already running ... "
fi

# check if log size exceeds the limit. If so, it rotates the log file
actualsize=$(wc -c <"$logfile")

if [ $actualsize -ge $minimumsize ]; then
  timestamp=$(date '+%d-%m-%Y_%H-%M-%S');
  cp $logfile $logfile"_"$timestamp
  > $logfile
fi