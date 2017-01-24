# RADAR-Docker

The dockerized RADAR stack for deploying the RADAR-CNS platform. Component repositories can be found here [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 
To install RADAR-CNS stack, do the following: 

1. Install Docker Engine
	  * Installation for macOS (Follow [installer](https://docs.docker.com/engine/installation/mac/) from Docker)
	  * Installation for Windows ( Follow [installer](https://docs.docker.com/docker-for-windows/ from Docker)
	  * Installation for Ubuntu (Follow our [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu) page)
	  * For other Linux distributions, install Docker engine from [the list by Docker](https://docs.docker.com/engine/installation/). Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following the [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
2. Verify the Docker installation by running on the command-line:

	```shell
	sudo docker --version
	sudo docker-compose --version
	```
	This should show Docker version 1.12 or later and docker-compose version 1.9.0 or later.
3. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for your platform.
4. Clone [RADAR-Docker](https://github.com/RADAR-CNS/RADAR-Docker) repository from GitHub.

    ```shell
    git clone https://github.com/RADAR-CNS/RADAR-Docker.git
    ```
5. Install required component stack following the instructions below.

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
2. Hadoop requires an external network. Create a network named `hadoop`:
 
    ```shell
    sudo docker network create hadoop
    ```
3. Configure monitor settings in `radar.yml`:
 
    ```yaml
    battery_monitor:
      level: CRITICAL
      email_address: notify-me@example.com
      email_host: smtp
      email_port: 25
      email_user: user@example.com
      topics:
        - android_empatica_e4_battery_level
    disconnect_monitor:
      # timeout in milliseconds -> 5 minutes
      timeout: 300000
      email_address: notify-me@example.com
      email_host: smtp
      email_port: 25
      email_user: user@example.com
      # temperature readings are sent very regularly, but
      # not too often.
      topics:
        - android_empatica_e4_temperature
     ```
4. Create `smtp.env` and configure your email settings following `smtp.env.template`. Configure alternative mail providers like Amazon SES or Gmail by using the parameters of the [`namshi/smtp` Docker image](https://hub.docker.com/r/namshi/smtp/).
5. (Optional) Modify topics, flush.size and HDFS direcotory for Cold storage in `sink-hdfs.properties`
 
    ```ini
    topics=topic1,topic2
    flush.size=
    topics.dir=/path/to/data
    ```
6. Configure Hot Storage settings in `.env` file
 
    ```ini
    HOTSTORAGE_USERNAME=mongodb-user
    HOTSTORAGE_PASSWORD=XXXXXXXX
    HOTSTORAGE_NAME=mongodb-database
    ```
    > **Note**: These properties are used to initialise a MongoDB database from scratch and to establish a connection between MongoDB and Rest-API   
7. Modify topics and MongoDB configuration for Hot storage in `sink-mongo.properties`
 
    ```ini
    # Topics that will be consumed
    topics=topic1,topic2
    # MongoDB configuration
    mongo.username=mongodb-user
    mongo.password=XXXXXXXX
    mongo.database=mongodb-database
    ```
    > **Note**: The MongoDB configuration must mirror `.env` file parameters configurated at point 6
8. (Optional) For secuirity reasons, the `auto.creation.topics.enable` has been set to `false`. To create the required topics, modify the comma separated list parameter `RADAR_TOPIC_LIST` in `.env` file
 
    ```ini
    RADAR_TOPIC_LIST=topic1, topic2
    ```
    > **Note**: The parameter has been already set up to support Empatica E4 integration.
9. Start the stack
 
    ```shell
    sudo docker-compose up -d --build
    ```

To stop RADAR-CNS stack on a single node setup, run

```shell
cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
sudo docker-compose down
```

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
