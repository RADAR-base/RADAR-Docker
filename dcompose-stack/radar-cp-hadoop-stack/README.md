# RADAR-CNS with a HDFS connector

## Configuration

First move `env.template` file to .env and check and modify all its variables.

Modify `smtp.env.template` to set a SMTP host to send emails with, and move it to `smtp.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container. This container supports a.o. regular SMTP and GMail.

Finally, edit `radar.yml`, especially concerning the monitor email address configuration.

## Usage

Run
```shell
./install-radar-stack.sh
```
to start all the RADAR services. Use the `(start|stop|reboot)-radar-stack.sh` to start, stop or reboot it.

Data can be extracted from this setup by running:

```shell
./extract_from_hdfs <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.
