# RADAR-base stack with S3

This docker-compose stack contains the operational core RADAR-base platform with Simple Storage Service as the intermediate Cold storage of the platform.
We are using [Minio](https://min.io/) as our S3 solution in this stack and an extended version of Confluent platform's [Kafka-connect-s3](https://github.com/RADAR-base/radar-s3-connector)
 
Please note that this is still alpha version and further improvements can follow in the future.

This stack is mainly based on the original RADAR-base stack with HDFS [radar-cp-hadoop-stack](../radar-cp-hadoop-stack) as the Cold storage, aiming at easier migration of existing installations while giving the opportunity to still run on HDFS is preferred.

## Reasons for migrating to S3
- From our experience, managing HDFS sometimes proved tedious and running HDFS on HA became a necessity on Kubernetes environment.
- We do not use many of the exclusive features of HDFS in RADAR-base.
- Use of Object storage has become quite popular in recent days and it serves the requirements of RADAR-base.
- There are well matured open-source S3 solutions like Minio that can be easily deployed on both Docker and Kubernetes.
- Confluent platform supports S3-connector where the official support for Confluent's HDFS-Sink-connector is discontinued.
- Hoping it will reduce the efforts of maintenance in future.


# Installation and configuration
## Prerequisites

- A Linux server that is available 24/7 with HTTP(S) ports open to the internet and with a domain name
- Root access on the server.
- Docker, Docker-compose, Java (JDK or JRE) and Git are installed
- Basic knowledge on docker, docker-compose and git.

## Steps
- Clone this repository and navigate to `RADAR-Docker/dcompose-stack/radar-cp-s3-stack`
- Configure the necessary components as instructed below.
- Run `bin/radar-docker install`
## Configuration

### Required
This is the set of minimal configuration required to run the stack.

1. First copy `etc/env.template` file to `./.env` and check and modify all its variables.

   1.1. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work. For a locally signed certificate, set `SELF_SIGNED_CERT=yes`. If HTTPS is to be disabled altogether, set `ENABLE_HTTPS=no`. If that is because the server is
   behind a reverse proxy or load balancer, set `NGINX_PROXIES=1.2.3.4 5.6.7.8` as a space-separated list of proxy server IP addresses as forwarded in the `X-Forwarded-For` header.

   1.2. Set `MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET` to a secret to be used by the Management Portal frontend.

   1.3. If you want to enable auto import of source types from the catalog server set the variable `MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT` to `true`.

   1.4. Leave the `PORTAINER_PASSWORD_HASH` variable in .env file empty and run the install script (`bin/radar-docker install`). This should query for a new password and set its hash in this variable. To update the password, just empty the variable again and run the install script.

2. Copy `etc/smtp.env.template` to `etc/smtp.env` and configure your email settings. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).

4. Copy `etc/managementportal/config/oauth_client_details.csv.template` to `etc/managementportal/config/oauth_client_details.csv` and change OAuth client credentials for production MP. The OAuth client for the frontend will be loaded automatically and does not need to be listed in this file. This file will be read at each startup. The current implementation overwrites existing clients with the same client ID, so be aware of this if you have made changes to a client listed in this file using the Management Portal frontend. This behaviour might change in the future.

5. Finally, copy `etc/radar-backend/radar.yml.template` to `etc/radar-backend/radar.yml` and edit it, especially concerning the monitor email address configuration.

### Optional
This is a set of optional configuration which is not required but could be useful.

1. For added security, copy the `etc/webserver/ip-access-control.conf.template` to `etc/webserver/ip-access-control.conf` and configure restriction of admin tools (like portainer and kafka-manager) to certain known IP addresses. For easy configuration two examples are included in the comments. By default all IPs are allowed.

2. To enable optional services, please set the `ENABLE_OPTIONAL_SERVICES` parameter in `.env` file to `true`. By default optional services are disabled. You can check which service are optional in the file `optional-services.yml`

      3.1 Copy `etc/redcap-integration/radar.yml.template` to `etc/redcap-integration/radar.yml` and modify it to configure the properties of Redcap instance and the management portal. For reference on configuration of this file look at [the README](https://github.com/RADAR-base/RADAR-RedcapIntegration#configuration). In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`. Also need to configure the webserver config, just uncomment the location block at `etc/webserver/optional-services.conf.template` and copy it to `etc/webserver/optional-services.conf`.

      3.2 For the Fitbit Connector, please specify the `FITBIT_API_CLIENT_ID` and `FITBIT_API_CLIENT_SECRET` in the .env file. Then copy the `etc/fitbit/docker/users/fitbit-user.yml.template` to `etc/fitbit/docker/users/fitbit-user.yml` and fill out all the details of the fitbit user. If multiple users, then for each user create a separate file in the `etc/fitbit/docker/users/` directory containing all the fields as in the template. For more information about users configuration for fitbit, read [here](https://github.com/RADAR-base/RADAR-REST-Connector#usage).

4. The systemd scripts described in the next paragraph include a health check. To enable system health notifications to Slack, install its [Incoming Webhooks app](https://api.slack.com/incoming-webhooks). With the webhook URL that you configure there, set in `.env`:

      ```shell
      HEALTHCHECK_SLACK_NOTIFY=yes
      HEALTHCHECK_SLACK_WEBHOOK_URL=https://...
      ```
#### Using S3 as the target for eventual restructured data.
Current stack integrates the radar-output as a service, to restructure data from cold storage into `project-> subject-> topic -> hourlydataincsv` format. This service supports writing restructured data into `local filesystem` or to `S3` bucket as well.
The default configuration of this setup uses S3 as the intermediate storage and uses local file system as the eventual data storage. 

If you would like to  write the restructured data to a S3 bucket as well, it can be done by changing the configuration of `radar-output` service.
Current installation setup creates two S3 buckets to and buy default we use one for intermediate storage. 

To write restructured data into a separate S3 bucket on your RADAR-base stack, edit the `etc/output-restructure/restructure.yml` file as follows
```yaml
target:
  type: s3
  s3:
    endpoint: http://minio1:9000
    bucket: radarbase-output
    accessToken: radarbase-minio or <enter the value of MINIO_ACCESS_KEY from .env>
    secretKey: <enter the value of MINIO_SECRET_KEY from .env>
```
 
## Usage

Run
```shell
bin/radar-docker install
```
to start all the RADAR services. Use the `bin/radar-docker start|down|restart` to start, stop or reboot it. In general, `bin/radar-docker` is a convenience script to `docker-compose`, so all commands that work on docker-compose also work on `bin/radar-docker`. Note: whenever `.env` or `docker-compose.yml` are modified, the `install` command needs to be called again. To start a reduced set of containers, call `bin/radar-docker install` with the intended containers as arguments.

To enable a `systemd` service to control the platform, run
```shell
bin/radar-docker install-systemd
```
After that command, the RADAR platform should be controlled via `systemctl`. When running as a user without `sudo` rights, in the following commands replace `sudo systemctl` with `systemctl --user`.
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
bin/docker-prune
sudo systemctl start radar-docker
```

To rebuild an image and restart them, run `bin/radar-docker rebuild IMAGE`. To stop and remove an container, run `bin/radar-docker quit CONTAINER`. To start the HDFS cluster, run `bin/radar-docker hdfs`. For a health check, run `bin/radar-docker health`.

To log to a separate directory, run
```shell
sudo bin/radar-log /my/LOG_DIR
```

This can be useful to separate the logs of RADAR from the generic `/var/log/syslog` file and limiting the total log size. To revert logging to `/var/log/syslog`, run

```shell
sudo rm /etc/rsyslog.d/00-radar.conf /etc/logrotate.d/radar /etc/cron.hourly/logrotate
sudo systemctl restart rsyslog
```

## Optionally install Dashboard pipeline.
Unlike radar-cp-hadoop-stack, we have separated the real-time dashboard visualization stack to a separate docker-compose file [dashboard-pipeline.yml](dashboard-pipeline.yml).
This part of the pipeline is not actively used in community. Thus, we have made it as an on-demand installation.

To install dashboard, 
1. Please install the core stack first by successfully running 
```bash
bin/radar-docker install
```

2. Once the core stack is running, you can optionally install dashboard pipeline by running
```bash
bin/radar-docker install-dashboard
```
3. If you would like to stop the stack after installing dashboard, you can do so buy running
```bash
bin/radar-docker -f docker-compose.yml -f dashboard-pipeline.yml down
```
4. If you would like to only stop part of the services after running dashboard, use
```bash
bin/radar-docker -f docker-compose.yml -f dashboard-pipeline.yml stop <service name>
```
## Upgrading the environment to the latest versions.
You can upgrade to the latest set-up by simply pulling latest version of RADAR-Docker. 
Then run `bin/radar-docker install` and take necessary steps based on the command line logs.

**NOTE:** If you are upgrading from **ManagementPortal version 0.5.3 to higher** or **from [RADAR-Docker:2.0.2](https://github.com/RADAR-base/RADAR-Docker/releases/tag/v2.0.2) or lower to higher version**, read the [migration-guide](Migrating-ManagementPortal-from-0.5.3-to-higher.md) to follow the steps manually. 

### Monitoring a topic

To see current data coming out of a Kafka topic, run
```script
bin/radar-kafka-consumer TOPIC
```

### Postgres Data Migration
If a major Postgres version upgrade is planned, existing data need to be migrated to the new version. To do so run `bin/postgres-upgrade NEW_VERSION`

### Certificate

If systemd integration is enabled, the ssl certificate will be renewed daily. It can then be run directly by running
```
sudo systemctl start radar-renew-certificate.service
```
Otherwise, the following manual commands can be invoked.
If `SELF_SIGNED_CERT=no` in `./.env`, be sure to run `bin/radar-cert-renew` daily to ensure that your certificate does not expire.

### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try <http://localhost/portainer/> for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

### Kafka Manager

The [kafka-manager](https://github.com/yahoo/kafka-manager) is an interactive web based tool for managing Apache Kafka. Kafka manager has beed integrated in the stack. It is accessible at `http://<your-host>/kafkamanager/`

### Check Health
Each of the containers in the stack monitor their own health and show the output as healthy or unhealthy. A script called `bin/radar-docker health` is used to check this output and send an email to the maintainer if a container is unhealthy.

First check that the `MAINTAINER_EMAIL` in the .env file is correct.

Then make sure that the SMTP server is configured properly and running.

If systemd integration is enabled, the `bin/radar-docker health` script will check health of containers every five minutes. It can then be run directly by running if systemd wrappers have been installed
```
sudo systemctl start radar-check-health.service
```
Otherwise, the following manual commands can be invoked.

Add a cron job to run the `bin/radar-docker health` script periodically like -
1. Edit the crontab file for the current user by typing `$ crontab -e`
2. Add your job and time interval. For example, add the following for checking health every 5 mins -

```
*/5 * * * * /home/ubuntu/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack/bin/radar-docker health
```

You can check the logs of CRON by typing `grep CRON /var/log/syslog`.