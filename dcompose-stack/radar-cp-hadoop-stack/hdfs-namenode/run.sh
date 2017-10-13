#!/bin/bash

if [ -z "$CLUSTER_NAME" ]; then
  echo "Cluster name not specified"
  exit 2
fi

IFS=',' read -r -a namedirs <<< $(echo "$HDFS_CONF_dfs_namenode_name_dir" | sed -e 's#file://##g')

for namedir in "${namedirs[@]}"; do
  mkdir -p "$namedir"
  if [ ! -d "$namedir" ]; then
    echo "Namenode name directory not found: $namedir"
    exit 2
  fi
  
  if [ -z "$(ls -A "$namedir")" ]; then
    echo "Formatting namenode name directory: $namedir is not yet formatted"
    $HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR namenode -format $CLUSTER_NAME 
    break
  fi
done

$HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR namenode
