#!/bin/bash

set -eo pipefail

wait_until() {
    local hostname=${1?}
    local port=${2?}
    local retry=${3:-100}
    local sleep_secs=${4:-2}

    local address_up=0

    while [ ${retry} -gt 0 ] ; do
        echo  "Waiting until ${hostname}:${port} is up ... with retry count: ${retry}"
        if nc -z ${hostname} ${port}; then
            address_up=1
            break
        fi
        retry=$((retry-1))
        sleep ${sleep_secs}
    done

    if [ $address_up -eq 0 ]; then
        echo "GIVE UP waiting until ${hostname}:${port} is up! "
        exit 1
    fi
}

format_hdfs() {
  NAME_DIR=$1
  shift
  IFS=',' read -r -a namedirs <<< $(echo "$NAME_DIR" | sed -e 's#file://##g')

  for namedir in "${namedirs[@]}"; do
    mkdir -p "$namedir"
    if [ ! -d "$namedir" ]; then
      echo "Namenode name directory not found: $namedir"
      exit 2
    fi

    if [ ! -e "$namedir/current/VERSION" ]; then
      echo "Formatting namenode name directory: $namedir is not yet formatted"
      hdfs namenode $@
      return 0
    fi
  done
  return 1
}

# apply template
for template in $(ls ${HADOOP_CONF_DIR}/*.mustache)
do
    conf_file=${template%.mustache}
    cat ${conf_file}.mustache | mustache.sh > ${conf_file}
done

USAGE=$'Usage: $0 [CMD] ...\n\tCMD: journalnode|namenode-1|namenode-2|datanode|resourcemanager-1|nodemanager|historyserver-1'

if [ "$#" == "0" ]; then
	echo "$USAGE"
	exit 1
fi

CMD=$1
shift

case $CMD in
"journalnode")
  exec hdfs journalnode "$@"
  ;;
"namenode-1")
  if format_hdfs "$HADOOP_DFS_NAME_DIR" -format -force && [ "${HADOOP_NAMENODE_HA}" != "" ]; then
    hdfs zkfc -formatZK -force
  fi
#    wait_until ${HADOOP_QJOURNAL_ADDRESS%%:*} 8485
  if [ "${HADOOP_NAMENODE_HA}" != "" ]; then
      hdfs zkfc &
  fi
  exec hdfs namenode "$@"
  ;;
"namenode-2")
  wait_until ${HADOOP_NAMENODE1_HOSTNAME} 8020
  if format_hdfs "$HADOOP_DFS_NAME_DIR" -bootstrapStandby && [ "${HADOOP_NAMENODE_HA}" != "" ]; then
    hdfs zkfc -formatZK -force
  fi

  hdfs zkfc &
  exec hdfs namenode "$@"
  ;;
"datanode")
  wait_until ${HADOOP_NAMENODE1_HOSTNAME} 8020
  exec hdfs datanode "$@"
  ;;
"resourcemanager-1")
  exec su-exec yarn yarn resourcemanager "$@"
  ;;
"nodemanager")
  wait_until ${YARN_RESOURCEMANAGER_HOSTNAME} 8031
  exec su-exec yarn yarn nodemanager "$@"
  ;;
"historyserver-1")
  wait_until ${HADOOP_NAMENODE1_HOSTNAME}  8020

  set +e -x

  hdfs dfs -ls /tmp > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      hdfs dfs -mkdir -p /tmp
      hdfs dfs -chmod 1777 /tmp
  fi

  hdfs dfs -ls /user > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      hdfs dfs -mkdir -p /user/hdfs
      hdfs dfs -chmod 755 /user
  fi

  hdfs dfs -ls ${YARN_REMOTE_APP_LOG_DIR} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      su-exec yarn hdfs dfs -mkdir -p ${YARN_REMOTE_APP_LOG_DIR}
      su-exec yarn hdfs dfs -chmod -R 1777 ${YARN_REMOTE_APP_LOG_DIR}
      su-exec yarn hdfs dfs -chown -R yarn:hadoop ${YARN_REMOTE_APP_LOG_DIR}
  fi

  hdfs dfs -ls ${YARN_APP_MAPRED_STAGING_DIR} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      su-exec mapred hdfs dfs -mkdir -p ${YARN_APP_MAPRED_STAGING_DIR}
      su-exec mapred hdfs dfs -chmod -R 1777 ${YARN_APP_MAPRED_STAGING_DIR}
      su-exec mapred hdfs dfs -chown -R mapred:hadoop ${YARN_APP_MAPRED_STAGING_DIR}
  fi

  set -e +x

  exec su-exec mapred mapred historyserver "$@"
  ;;
*)
  exec "$CMD" "$@"
  ;;
esac
