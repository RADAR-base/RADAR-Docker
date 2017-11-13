# RADAR-CNS platform

## Configuration

1. First copy `etc/env.template` file to `./.env` and check and modify all its variables. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work.

2. Copy `etc/smtp.env.template` to `etc/smtp.env` and configure your email settings. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).

3. Copy `etc/redcap-integration/radar.yml.template` to `etc/redcap-integration/radar.yml` and modify it to configure the properties of Redcap instance and the management portal. For reference on configuration of this file look at the Readme file here - https://github.com/RADAR-CNS/RADAR-RedcapIntegration#configuration
In the REDcap portal under Project Setup, define the Data Trigger as `https://<YOUR_HOST_URL>/redcapint/trigger`

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

### cAdvisor

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

To view current resource performance,if running locally, try [http://localhost:8181](http://localhost:8181). This will bring up the built-in Web UI. Clicking on `/docker` in `Subcontainers` takes you to a new window with all of the Docker containers listed individually.

### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try [http://localhost:8182](http://localhost:8182) for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

### Kafka Manager
The [kafka-manager](https://github.com/yahoo/kafka-manager) is an interactive web based tool for managing Apache Kafka. Kafka manager has beed integrated in the stack. However, the following istructions are included so that its easy for someone in the futuer to update the stack or for using kafka-manager in other projects.
Instructions for deploying kafka-manager in a docker container and proxied through nginx-


1. Clone the GitHub repo - `$ git clone https://github.com/yahoo/kafka-manager.git`
2. Change the working directory - `$ cd kafka-manager`
3. Create a zip distribution using scala - `$ ./sbt clean dist`
4. Note the path of the zip file created.
5. Unzip the zip file to the stack location at `RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack/`
6. change directory to unzipped folder (in my case `$ cd kafka-manager-1.3.3.14/`)
7. Create a file named Dockerfile for specifying the docker build - `$ sudo vim Dockerfile`
8. Add the following content to the Dockerfile -
```dockerfile
	FROM hseeberger/scala-sbt

	RUN mkdir /kafka-manager-1.3.3.14
	ADD . /kafka-manager-1.3.3.14
	ENV ZK_HOSTS=zookeeper-1:2181

	WORKDIR /kafka-manager-1.3.3.14

	EXPOSE 9000
	ENTRYPOINT ["./bin/kafka-manager","-Dconfig.file=conf/application.conf"]
 ```
9. Note- Change the version of `kafka-manger-{Version}` in the Dockerfile above according to the version you cloned and specified by the unzipped folder.
10. Change the `play.http.context` parameter in the conf/application.conf file to point to the location path you are going to specify in the nginx.conf file later. In my case it was - `play.http.context = "/kafkamanager/“`
11. Now edit the `etc/nginx.conf.template` file to include the path to kafka-manager so that it is accessible from the browser. Add the following inside the server tag of nginx.conf file -
```nginx
	location /kafkamanager/{
		proxy_pass         http://kafka-manager:9000;
		proxy_set_header   Host $host;
	}
```
12. Now start the stack with ./install-radar-stack.sh. This will build a docker image for kafka and start it in a container. You can access it with a browser at `https://host/kafkamanager/`. Open the link and add all the information. In this case the zookeeper host is at `zookeeper-1:2181`. This will look something like the image -

![Add a Cluster](/img/add_cluster.png)

Note- You can also take the easy route and just pull the docker image from docker hub located at `radarcns/kafka-manager`. But remember that the context path is `/kafka-manager` so you will need to specify this in your `nginx.conf` file



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
