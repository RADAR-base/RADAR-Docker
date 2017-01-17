# RADAR-CNS with a HDFS connector

In the Dockerfile, 2 redundant HDFS volumes and 2 redundant directories are mounted. Set these directories in the `.env` file, and ensure that their parent directory exists. For proper redundancy, the directories should be set to different physical volumes.

Modify `smtp.env.template` to set a SMTP host to send emails with, and move it to `smtp.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container. This container supports a.o. regular SMTP and GMail.

Then, create a docker `hadoop` network.

```shell
docker network create hadoop
```

Run the full setup with
```shell
sudo docker-compose up -d
```

Data can be extracted from this setup by running:

```shell
./extract_from_hdfs <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.
