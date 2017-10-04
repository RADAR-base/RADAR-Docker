# RADAR-CNS with a HDFS connector

## Configuration

1. First move `etc/env.template` file to `./.env` and check and modify all its variables. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work.

2. Modify `etc/smtp.env.template` to set a SMTP host to send emails with, and move it to `etc/smtp.env`. The configuration settings are passed to a [namshi/smtp](https://hub.docker.com/r/namshi/smtp/) Docker container. This container supports a.o. regular SMTP and GMail.

3. Modify the `etc/redcap-integration/radar.yml.template` to configure the properties of Redcap instance and the management portal, and move it to `etc/redcap-integration/radar.yml`. For reference on configuration of this file look at the Readme file here - https://github.com/RADAR-CNS/RADAR-RedcapIntegration#configuration
In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`

4. ### Build ManagementPortal from source ( Required to build it from source for secured deployment at the moment)

4.1. Clone ManagementPortal 
```shell
git clone https://github.com/RADAR-CNS/ManagementPortal.git
```
4.2. Change OAuth2 client credentials for production environment at `src/main/resources/config/liquibase/oauth_client_details.csv`

4.3. Change the base href url to  `<base href="/managementportal/" />` at `src/main/webapp/index.html`.
 
4.4. Build ManagementPortal for production
```shell
./gradlew bootRepackage -Pprod buildDocker
```
4.5. Copy built `.war` file to `/managementportal/`

5. Finally, move `etc/radar.yml.template` to `etc/radar.yml` and edit it, especially concerning the monitor email address configuration.

## Usage

Run
```shell
./install-radar-stack.sh
```
to start all the RADAR services. Use the `(start|stop|reboot)-radar-stack.sh` to start, stop or reboot it. Note: whenever `.env` or `docker-compose.yml` are modified, this script needs to be called again. To start a reduced set of containers, call `install-radar-stack.sh` with the intended containers as arguments.

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
