# RADAR-Docker

The dockerized RADAR stack for deploying the RADAR-CNS platform. Component repositories can be found at [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 
To install RADAR-CNS stack, do the following: 

1. Install [Docker Engine](https://docs.docker.com/engine/installation/)
2. Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following our [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
3. Verify the Docker installation by running on the command-line:

    ```shell
    docker --version
    docker-compose --version
    ```
    This should show Docker version 1.12 or later and docker-compose version 1.9.0 or later.
4. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for your platform.
    1. For Ubuntu

        ```shell
        sudo apt-get install git
        ```
	
5. Clone [RADAR-Docker](https://github.com/RADAR-CNS/RADAR-Docker) repository from GitHub.

    ```shell
    git clone https://github.com/RADAR-CNS/RADAR-Docker.git
    ```

6. Install required component stack following the instructions below.

## Usage

RADAR-Docker currently offers two component stacks to run.

1. A Docker-compose for components from [Confluent Kafka Platform](http://docs.confluent.io/3.1.0/) community 
2. A Docker-compose for components from RADAR-CNS platform.

> **Note**: on macOS, remove `sudo` from all `docker` and `docker-compose` commands in the usage instructions below.

### Confluent Kafka platform
Confluent Kafka platform offers integration of the basic components for streaming such as Zookeeper, Kafka brokers, Schema registry and REST-Proxy. 

Run this stack in a single-node setup on the command-line:

```shell
cd RADAR-Docker/dcompose-stack/radar-cp-stack/
sudo docker-compose up -d
```

To stop this stack, run:

```shell
sudo docker-compose down
```

### RADAR-CNS platform

In addition to Confluent Kafka platform components, RADAR-CNS platform offers

* RADAR-HDFS-Connector - Cold storage of selected streams in Hadoop data storage,
* RADAR-MongoDB-Connector - Hot storage of selected streams in MongoDB,
* [RADAR-Dashboard](https://github.com/RADAR-CNS/RADAR-Dashboard),
* RADAR-Streams - real-time aggregated streams,
* RADAR-Monitor - Status monitors,
* [RADAR-HotStorage](https://github.com/RADAR-CNS/RADAR-HotStorage) via MongoDB, 
* [RADAR-REST API](https://github.com/RADAR-CNS/RADAR-RestApi),
* a Hadoop cluster, and
* an email server.

To run RADAR-CNS stack in a single node setup:

1. Navigate to `radar-hadoop-cp-stack`:

    ```shell
    cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
    ```
2. Configure monitor settings in `radar.yml`:
 
    ```yaml
    battery_monitor:
      level: CRITICAL
      email_address:
       - notify-1@example.com
       - notify-2@example.com
      email_host: smtp
      email_port: 25
      email_user: user@example.com
      topics:
        - android_empatica_e4_battery_level
	
    disconnect_monitor:
      # timeout in milliseconds -> 5 minutes
      timeout: 300000
      email_address:
       - notify-1@example.com
       - notify-2@example.com      
      email_host: smtp
      email_port: 25
      email_user: user@example.com
      # temperature readings are sent very regularly, but
      # not too often.
      topics:
        - android_empatica_e4_temperature
     ```
3. Create `smtp.env` and configure your email settings following `smtp.env.template`. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).
4. (Optional) Modify flush.size and HDFS direcotory for Cold storage in `sink-hdfs.properties`

    ```ini
    flush.size=
    topics.dir=/path/to/data
    ```
	Note: To have different flush.size for different topics, you can create multipe property configurations for a single connector. To do that,
	
	4.1 Create multipe property files that have different `flush.size` for given topics. 
	Examples [sink-hdfs-high.properties](https://github.com/RADAR-CNS/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/sink-hdfs-high.properties) , [sink-hdfs-low.properties](https://github.com/RADAR-CNS/RADAR-Docker/blob/dev/dcompose-stack/radar-cp-hadoop-stack/sink-hdfs-low.properties)
	
	4.2 Add `CONNECTOR_PROPERTY_FILE_PREFIX: <prefix-value>` enviornment variable to `radar-hdfs-connector` service in `docker-compose` file.  
	
	4.3 Add created property files to the `radar-hdfs-connector` service in `docker-compose` with name abides to prefix-value mentioned in `CONNECTOR_PROPERTY_FILE_PREFIX`

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
 
5. Configure Hot Storage settings in `.env` file
 
    ```ini
    HOTSTORAGE_USERNAME=mongodb-user
    HOTSTORAGE_PASSWORD=XXXXXXXX
    HOTSTORAGE_NAME=mongodb-database
    ```   
6. To install the stack
 
    ```shell
    sudo ./install-radar-stack.sh
    ```

To stop RADAR-CNS stack on a single node setup, run

```shell
cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
sudo ./stop-radar-stack.sh 
```
To reboot RADAR-CNS stack on a single node setup, run

```shell
cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
sudo ./reboot-radar-stack.sh
```
To start RADAR-CNS stack on a single node setup after installing, run

```shell
cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
sudo ./start-radar-stack.sh
```

#### cAdvisor 

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

To view current resource performance,if running locally, try [http://localhost:8181](http://localhost:8181). This will bring up the built-in Web UI. Clicking on `/docker` in `Subcontainers` takes you to a new window with all of the Docker containers listed individually.

#### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try [http://localhost:8182](http://localhost:8182) for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

#### Kafka Manager
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

### Logging

Set up logging by going to the `dcompose-stack/logging` directory and follow the README there.

## Work in progress

The two following stacks will not work on with only Docker and docker-compose. For the Kerberos stack, the Kerberos image is not public. For the multi-host setup, also docker-swarm and Docker beta versions are needed.

### Kerberized stack

In this setup, Kerberos is used to secure the connections between the Kafka brokers, Zookeeper and the Kafka REST API. Unfortunately, the Kerberos container from Confluent is not publicly available, so an alternative has to be found here.

```shell
$ cd wip/radar-cp-sasl-stack/
$ docker-compose up
```

### Multi-host setup

In the end, we aim to deploy the platform in a multi-host environment. We are currently aiming for a deployment with Docker Swarm. This setup uses features that are not yet released in the stable Docker Engine. Once they are, this stack may become the main Docker stack. See the `wip/radar-swarm-cp-stack/` directory for more information.
