# RADAR platform

This docker-compose stack contains the full operational RADAR platform. Once configured, it is meant to run on a single server with at least 16 GB memory and 4 CPU cores. It is tested on Ubuntu 16.04 and on macOS 11.1 with Docker 17.06.

## Configuration

1. First copy `etc/env.template` file to `./.env` and check and modify all its variables. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work.

2. Copy `etc/smtp.env.template` to `etc/smtp.env` and configure your email settings. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).

3. Copy `etc/redcap-integration/radar.yml.template` to `etc/redcap-integration/radar.yml` and modify it to configure the properties of Redcap instance and the management portal. For reference on configuration of this file look at the Readme file here - <https://github.com/RADAR-CNS/RADAR-RedcapIntegration#configuration>. In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`

4. Copy `etc/managementportal/config/liquibase/oauth_client_details.csv.template` to `etc/managementportal/config/liquibase/oauth_client_details.csv` and change OAuth client credentials for production MP. (Except ManagementPortalapp)

5. Finally, copy `etc/radar.yml.template` to `etc/radar.yml` and edit it, especially concerning the monitor email address configuration.

6. (Optional) Note: To have different flush.size for different topics, you can create multipe property configurations for a single connector. To do that,

	6.1 Create multipe property files that have different `flush.size` for given topics.
	Examples [sink-hdfs-high.properties](https://github.com/RADAR-CNS/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/etc/sink-hdfs-high.properties) , [sink-hdfs-low.properties](https://github.com/RADAR-CNS/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/etc/sink-hdfs-low.properties)

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


### cAdvisor

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

To view current resource performance,if running locally, try <http://localhost:8080>. This will bring up the built-in Web UI. Clicking on `/docker` in `Subcontainers` takes you to a new window with all of the Docker containers listed individually.

### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try <http://localhost/portainer/> for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

### Kafka Manager

The [kafka-manager](https://github.com/yahoo/kafka-manager) is an interactive web based tool for managing Apache Kafka. Kafka manager has beed integrated in the stack. It is accessible at <http://localhost/kafkamanager/>