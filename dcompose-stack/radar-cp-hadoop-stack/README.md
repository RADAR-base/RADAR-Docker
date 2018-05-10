# RADAR platform

This docker-compose stack contains the full operational RADAR platform. Once configured, it is meant to run on a single server with at least 16 GB memory and 4 CPU cores. It is tested on Ubuntu 16.04 and on macOS 11.1 with Docker 17.06.

## Configuration

1. First copy `etc/env.template` file to `./.env` and check and modify all its variables.
   
   
   1.1. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work. 
 
   1.2. Set `MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET` to a secret to be used by the Management Portal frontend.
     
   1.3. If you want to enable auto import of source types from the catalog server set the variable `MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT` to `true`.

2. Copy `etc/smtp.env.template` to `etc/smtp.env` and configure your email settings. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).

3. Copy `etc/redcap-integration/radar.yml.template` to `etc/redcap-integration/radar.yml` and modify it to configure the properties of Redcap instance and the management portal. For reference on configuration of this file look at the Readme file here - <https://github.com/RADAR-base/RADAR-RedcapIntegration#configuration>. In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`

4. Copy `etc/managementportal/config/oauth_client_details.csv.template` to `etc/managementportal/config/oauth_client_details.csv` and change OAuth client credentials for production MP. The OAuth client for the frontend will be loaded automatically and does not need to be listed in this file. This file will be read at each startup. The current implementation overwrites existing clients with the same client ID, so be aware of this if you have made changes to a client listed in this file using the Management Portal frontend. This behaviour might change in the future.

5. Finally, copy `etc/radar-backend/radar.yml.template` to `etc/radar-backend/radar.yml` and edit it, especially concerning the monitor email address configuration.

6. (Optional) Note: To have different flush.size for different topics, you can create multipe property configurations for a single connector. To do that,

	6.1 Create multipe property files that have different `flush.size` for given topics.
	Examples [sink-hdfs-high.properties](https://github.com/RADAR-base/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/etc/sink-hdfs-high.properties) , [sink-hdfs-low.properties](https://github.com/RADAR-base/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/etc/sink-hdfs-low.properties)

	6.2 Add `CONNECTOR_PROPERTY_FILE_PREFIX: <prefix-value>` environment variable to `radar-hdfs-connector` service in `docker-compose` file.

	6.3 Add created property files to the `radar-hdfs-connector` service in `docker-compose` with name abides to prefix-value mentioned in `CONNECTOR_PROPERTY_FILE_PREFIX`

	```ini
	    radar-hdfs-connector:
	      image: radarcns/radar-hdfs-connector-auto:0.2
	      restart: on-failure
	      volumes:
		- ./sink-hdfs-high.properties:/etc/kafka-connect/sink-hdfs-high.properties
		- ./sink-hdfs-low.properties:/etc/kafka-connect/sink-hdfs-low.properties
	      environment:
		CONNECT_BOOTSTRAP_SERVERS: PLAINTEXT://kafka-1:9092,PLAINTEXT://kafka-2:9092,PLAINTEXT://kafka-3:9092
		CONNECTOR_PROPERTY_FILE_PREFIX: "sink-hdfs"
	```

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
sudo systemctl disable radar-check-health
sudo systemctl disable radar-renew-certificate
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
This will put all CSV files in the destination directory, with subdirectory structure `ProjectId/SubjectId/SensorType/Date_Hour.csv`.

## Cerificate

If systemd integration is enabled, the ssl certificate will be renewed daily. It can then be run directly by running
```
sudo systemctl start radar-renew-certificate.service
```
Otherwise, the following manual commands can be invoked.
If `SELF_SIGNED_CERT=no` in `./.env`, be sure to run `./renew_ssl_certificate.sh` daily to ensure that your certificate does not expire.


### cAdvisor

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

To view current resource performance,if running locally, try <http://localhost:8080>. This will bring up the built-in Web UI. Clicking on `/docker` in `Subcontainers` takes you to a new window with all of the Docker containers listed individually.

### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try <http://localhost/portainer/> for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

### Kafka Manager

The [kafka-manager](https://github.com/yahoo/kafka-manager) is an interactive web based tool for managing Apache Kafka. Kafka manager has beed integrated in the stack. It is accessible at `http://<your-host>/kafkamanager/`

### Check Health
Each of the containers in the stack monitor their own health and show the output as healthy or unhealthy. A script called check-health.sh is used to check this output and send an email to the maintainer if a container is unhealthy.

First check that the `MAINTAINER_EMAIL` in the .env file is correct.

Then make sure that the SMTP server is configured properly and running.

If systemd integration is enabled, the check-health.sh script will check health of containers every five minutes. It can then be run directly by running if systemd wrappers have been installed
```
sudo systemctl start radar-check-health.service
```
Otherwise, the following manual commands can be invoked.

Add a cron job to run the `check-health.sh` script periodically like -
1. Edit the crontab file for the current user by typing `$ crontab -e`
2. Add your job and time interval. For example, add the following for checking health every 5 mins - 

```*/5 * * * * /home/ubuntu/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack/check-health.sh```

You can check the logs of CRON by typing `$ grep CRON /var/log/syslog`
Also you will need to change the directory. So just add the following to the top of the check-health.sh script - 
```sh
cd "$( dirname "${BASH_SOURCE[0]}" )"
```

