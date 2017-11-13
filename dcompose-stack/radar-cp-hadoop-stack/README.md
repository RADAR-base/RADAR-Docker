# RADAR-CNS with a HDFS connector

## Configuration

1. First move `etc/env.template` file to `./.env` and check and modify all its variables. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work.

2. Modify `etc/smtp.env.template` to set a SMTP host to send emails with, and move it to `etc/smtp.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container. This container supports a.o. regular SMTP and GMail.

3. Modify the `etc/redcap-integration/radar.yml.template` to configure the properties of Redcap instance and the management portal, and move it to `etc/redcap-integration/radar.yml`. For reference on configuration of this file look at the Readme file here - https://github.com/RADAR-CNS/RADAR-RedcapIntegration#configuration
In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`

4. Move `etc/managementportal/config/liquibase/oauth_client_details.csv.template` to `etc/managementportal/config/liquibase/oauth_client_details.csv` and change OAuth client credentials for production MP. (Except ManagementPortalapp)

5. Finally, move `etc/radar.yml.template` to `etc/radar.yml` and edit it, especially concerning the monitor email address configuration.

## Usage

Run
```shell
./install-radar-stack.sh
```
to start all the RADAR services. Use the `(start|stop|reboot)-radar-stack.sh` to start, stop or reboot it. Note: whenever `.env` or `docker-compose.yml` are modified, this script needs to be called again. To start a reduced set of containers, call `install-radar-stack.sh` with the intended containers as arguments.

To enable a `systemd` service to control the platform, run
```shell
./install-systemd-wrappers.sh
```
After that command, the RADAR platform should be controlled via `systemctl`.
```shell
# query the latest status and logs
sudo systemctl status radar-docker

# Stop radar-docker
sudo systemctl stop radar-docker

# Restart all containers
sudo systemctl reload radar-docker

# Start radar-docker
sudo systemctl start radar-docker

# Full radar-docker system logs
sudo journalctl -u radar-docker
```
The control scripts in this directory should preferably not be used if `systemctl` is used. To remove `systemctl` integration, run
```
sudo systemctl disable radar-docker
sudo systemctl disable radar-output
```

To clear all data from the platform, run
```
sudo systemctl stop radar-docker
./docker-prune.sh
sudo systemctl start radar-docker
```

## Data extraction

If systemd integration is enabled, HDFS data will be extracted to the `./output` directory every hour. It can then be run directly by running
```
sudo systemctl start radar-output.service
```
Otherwise, the following manual commands can be invoked.

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

If `SELF_SIGNED_CERT=no` in `./.env`, be sure to run `./renew_ssl_certificate.sh` daily to ensure that your certificate does not expire.
