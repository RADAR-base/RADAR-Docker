# RADAR-CNS with a HDFS connector

In the Dockerfile 3 HDFS volumes and the name directory are mounted. Create those before running. Also create a docker `hadoop` network.

```shell
DATA_DIR=/usr/local/var/lib/docker
mkdir -p "$DATA_DIR/hadoop-data1" "$DATA_DIR/hadoop-data2" "$DATA_DIR/hadoop-data3" "$DATA_DIR/hadoop-name"
docker network create hadoop
``` 

Data can be extracted from this setup by running
```shell
# Directory to write output to
OUTPUT_DIR=$PWD/output
# HDFS filename to get
HDFS_FILE=/abc/test.txt
# HDFS command to run
HDFS_COMMAND="hdfs dfs -get $HDFS_FILE /home/output"

mkdir -p $OUTPUT_DIR
docker run --rm --network hadoop -v "$OUTPUT_DIR:/home/output" -e CLUSTER_NAME=radar-cns -e CORE_CONF_fs_defaultFS=hdfs://namenode:8020 uhopper/hadoop $HDFS_COMMAND
```
