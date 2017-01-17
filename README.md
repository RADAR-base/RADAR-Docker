# RADAR-Docker

The dockerized RADAR stack or deploying the RADAR-CNS platform. Component repositories can be found here [RADAR-CNS DockerHub org](https://hub.docker.com/u/radarcns/dashboard/)

## Installation instructions 

First install Docker and `docker-compose` for your respective platform. Docker has installers for [macOS](https://docs.docker.com/engine/installation/mac/) and [Windows](https://docs.docker.com/engine/installation/windows/). For Ubuntu, see our [wiki page](https://github.com/RADAR-CNS/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu). For other Linux distributions, see [the list by Docker](https://docs.docker.com/engine/installation/).

## Usage

We currently have two stacks available to run, one for the community parts of the Confluent Kafka Platform and another for the complete RADAR-CNS platform.

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
