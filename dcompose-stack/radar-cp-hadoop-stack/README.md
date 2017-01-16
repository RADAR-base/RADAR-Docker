# RADAR-CNS with a HDFS connector

In the Dockerfile, 2 redundant HDFS volumes and the name directory are mounted. The local root path for those volumes has to be created before the first run. Also, create a docker `hadoop` network.

```shell
DOCKER_DATA=/usr/local/var/lib/docker
mkdir -p $DOCKER_DATA
docker network create hadoop
``` 

For a redundant data storage, instead of the directories created in `$DOCKER_DATA`, make symlinks to different volumes:

```shell
DOCKER_DATA=/usr/local/var/lib/docker
VOLUME_1=/volume1
VOLUME_2=/volume1
mkdir -p "$VOLUME_1/hdfs-data" "$VOLUME_1/hdfs-name"
mkdir -p "$VOLUME_2/hdfs-data" "$VOLUME_2/hdfs-name"
ln -s "$VOLUME_1/hdfs-data" "$DOCKER_DATA/hdfs-data1"
ln -s "$VOLUME_2/hdfs-data" "$DOCKER_DATA/hdfs-data2"
ln -s "$VOLUME_1/hdfs-name" "$DOCKER_DATA/hdfs-name1"
ln -s "$VOLUME_2/hdfs-name" "$DOCKER_DATA/hdfs-name2"
```

Modify `mail.env.template` to set a SMTP host to send emails with, and move it to `mail.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container.

Run the full setup with
```shell
sudo docker-compose up -d
```

Data can be extracted from this setup by running:

```shell
./extract_from_hdfs <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.
