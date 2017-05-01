# RADAR-CNS with a HDFS connector

## Configuration

First move `etc/env.template` file to `./.env` and check and modify all its variables.

Modify `etc/smtp.env.template` to set a SMTP host to send emails with, and move it to `etc/smtp.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container. This container supports a.o. regular SMTP and GMail.

Finally, edit `etc/radar.yml`, especially concerning the monitor email address configuration.

## Usage

Run
```shell
./install-radar-stack.sh
```
to start all the RADAR services. Use the `(start|stop|reboot)-radar-stack.sh` to start, stop or reboot it.

Raw data can be extracted from this setup by running:

```shell
./hdfs_extract.sh <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.

CSV-structured data can be gotten from HDFS by running

```shell
./hdfs_restructure.sh /topicAndroidNew <destination directory>
```
This will put all CSV files in the destination directory, with subdirectory structure `PatientId/SensorType/Date_Hour.csv`.
