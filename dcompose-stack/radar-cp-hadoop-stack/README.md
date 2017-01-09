# RADAR-CNS with a HDFS connector

In the Dockerfile, 2 redundant HDFS volumes and the name directory are mounted. The local paths for those volumes have to be created before the first run. Also, create a docker `hadoop` network.

```shell
DATA_DIR=/usr/local/var/lib/docker
mkdir -p "$DATA_DIR/hadoop-data1" "$DATA_DIR/hadoop-data2" "$DATA_DIR/hadoop-name"
docker network create hadoop
``` 

Data can be extracted from this setup by running:

```shell
./extract_from_hdfs <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.
