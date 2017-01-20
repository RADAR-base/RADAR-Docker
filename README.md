# RADAR-Docker

The dockerized RADAR stack for deploying the RADAR-CNS platform. Component repositories can be found here [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 
To install RADAR-CNS stack, do the following: 

1. Install Docker Engine and verify your installation.
  * Installation for macOS (Follow [installer](https://docs.docker.com/engine/installation/mac/) from Docker)
  * Installation for Windows ( Follow [installer](https://docs.docker.com/docker-for-windows/ from Docker)
  * Installation for Ubuntu (Follow our [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu) page)
  * For other Linux distributions, see [the list by Docker](https://docs.docker.com/engine/installation/).
2. Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following the [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
3. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for your platform. 
4. Clone [RADAR-Docker](https://github.com/RADAR-CNS/RADAR-Docker) repository from GitHub.

  ```
  git clone https://github.com/RADAR-CNS/RADAR-Docker.git
  ```
5. Install required component stack following the instructions below.   

## Usage

RADAR-Docker currently offers two component stacks to run.

1. A Docker-compose for components from [Confluent Kafka Platform](http://docs.confluent.io/3.1.0/) community 
2. A Docker-compose for components from RADAR-CNS platform.

### Confluent Kafka platform
Confluent Kafka platform offers integration of the basic components for streaming such as Zookeeper, Kafka brokers, Schema registry and REST-Proxy. 

To run this stack on a single-node setup:  
```shell
$ cd RADAR-Docker/dcompose-stack/radar-cp-stack/
$ docker-compose up
```

To stop this stack:   
```shell
$ docker-compose down
```
### RADAR-CNS platform

In addition to Confluent Kafka platform compoents, RADAR-CNS platform offers 
* RADAR-HDFS-Connector - Cold storage of selected streams in Hadoop data storage,
* RADAR-MongoDB-Connector - Hot storage of selected streams in MongoDB,
* [RADAR-Dashboard](https://github.com/RADAR-CNS/RADAR-Dashboard),
* RADAR-Streams - real-time aggregated streams,
* RADAR-Monitor - Status monitors,
* [RADAR-HotStorage](https://github.com/RADAR-CNS/RADAR-HotStorage) via MongoDB, 
* [RADAR-REST API](https://github.com/RADAR-CNS/RADAR-RestApi),
* a Hadoop cluster, and
* an email server.

To run RADAR-CNS stack on a single node setup:
 1. Navigate to `radar-hadoop-cp-stack`
 
   ```shell
   $ cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
   ```
 2. Hadoop requires an external network. Create a network named `hadoop`
 
   ```shell
   $ docker network create hadoop
   ```
 3. Configure monitor settings in radar.yml
 
    ```
    battery_monitor:
      level: CRITICAL
      email_address: <notifiersemail>
      email_host: smtp
      email_port: 25
      email_user: user@example.com
      topics:
        - android_empatica_e4_battery_level
     ```
 4. Create `smtp.env` and configure your email settings following `smtp.env.template`
 5. (Optional) Modify topics, flush.size and HDFS direcotory for Cold storage in `sink-hdfs.properties`
 
    ```
    topics=
    flush.size=
    topics.dir=
    ```
 6. (Optional) Modify topics and mongo db configuration  for Cold storage in `sink-radar.properties`
 
    ```
    # Topics that will be consumed
    topics=
    # MongoDB configuration
    mongo.username=
    mongo.password=
    mongo.database=mydbase
    ```
 7. Start the stack 
 
    ```
    $ sudo docker-compose up -d
    ```

To stop RADAR-CNS stack on a single node setup:
```shell
$ cd RADAR-Docker/dcompose-stack/radar-hadoop-cp-stack/
$ docker-compose down
```
### Kerberized stack

In this setup, Kerberos is used to secure the connections between the Kafka brokers, Zookeeper and the Kafka REST API. Unfortunately, the Kerberos container from Confluent is not publicly available, so an alternative has to be found here.

```shell
$ cd wip/radar-cp-sasl-stack/
$ docker-compose up
```

### Multi-host setup

In the end, we aim to deploy the platform in a multi-host environment. We are currently aiming for a deployment with Docker Swarm. This setup uses features that are not yet released in the stable Docker Engine. Once they are, this stack may become the main Docker stack. See the `wip/radar-swarm-cp-stack/` directory for more information.
