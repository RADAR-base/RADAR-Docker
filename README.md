# RADAR-Docker

The dockerized RADAR stack for deploying the RADAR-CNS platform. Component repositories can be found at [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 
To install RADAR-CNS stack, do the following: 

1. Install Docker Engine
	  * Installation for macOS (Follow [installer](https://docs.docker.com/engine/installation/mac/) from Docker)
	  * Installation for Windows ( Follow [installer](https://docs.docker.com/docker-for-windows/ from Docker)
	  * Installation for Ubuntu (Follow [Docker instructions](https://docs.docker.com/engine/installation/linux/ubuntu/))
	  * For other Linux distributions, install Docker engine from [the list by Docker](https://docs.docker.com/engine/installation/). Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following the [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
2. Install `docker-compose` by following instructions [here](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose) 	  
3. Verify the Docker installation by running on the command-line:

	```shell
	sudo docker --version
	sudo docker-compose --version
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
