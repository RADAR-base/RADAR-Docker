# RADAR-Docker

The dockerized RADAR stack or deploying the RADAR-CNS platform. Component repositories can be found here [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 
To install RADAR-CNS stack, do the following: 

1. Install Docker Engine and verify your installation.
  * Installation for macOS (Follow [installer](https://docs.docker.com/engine/installation/mac/) from Docker)
  * Installation for Windows ( Follow [installer](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu) from Docker)
  * Installation for Ubuntu (Follow our [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu) page)
  * For other Linux distributions, see [the list by Docker](https://docs.docker.com/engine/installation/).
2. Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following the [wiki](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
3. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for your platform. 
3. Clone [RADAR-Docker](https://github.com/RADAR-CNS/RADAR-Docker) repository from GitHub.

  ```
  git clone https://github.com/RADAR-CNS/RADAR-Docker.git
  ```
  
## Usage

RADAR-Docker currently offers two component stacks to run.

1. A Docker-compose for components from [Confluent Kafka Platform](http://docs.confluent.io/3.1.1/) community 
2. A Docker-compose for components from RADAR-CNS platform.

### Confluent Kafka platform

In this stack, only the Confluent Kafka Platform is set up.

```shell
$ cd dcompose-stack/radar-cp-stack/
$ docker-compose up
```

### RADAR-CNS platform

In this stack, the Confluent platform is set up with a Hadoop data storage, email server, RADAR-Dashboard, RADAR-HotStorage, and a REST API. See the README in the `dcompose-stack/radar-hadoop-cp-stack` directory for more information on how to run it.

## Work in progress

### Kerberized stack

In this setup, Kerberos is used to secure the connections between the Kafka brokers, Zookeeper and the Kafka REST API. Unfortunately, the Kerberos container from Confluent is not publicly available, so an alternative has to be found here.

```shell
$ cd wip/radar-cp-sasl-stack/
$ docker-compose up
```

### Multi-host setup

In the end, we aim to deploy the platform in a multi-host environment. We are currently aiming for a deployment with Docker Swarm. This setup uses features that are not yet released in the stable Docker Engine. Once they are, this stack may become the main Docker stack. See the `wip/radar-swarm-cp-stack/` directory for more information.
