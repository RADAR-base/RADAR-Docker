# Kafka manager

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
12. Now start the stack with `dcompose-stack/radar-cp-hadoop-stack//install-radar-stack.sh`. This will build a docker image for kafka and start it in a container. You can access it with a browser at `https://host/kafkamanager/`. Open the link and add all the information. In this case the zookeeper host is at `zookeeper-1:2181`. This will look something like the image -

![Add a Cluster](/images/kafka-manager/img/add_cluster.png)

Note- You can also take the easy route and just pull the docker image from docker hub located at `radarcns/kafka-manager`. But remember that the context path is `/kafka-manager` so you will need to specify this in your `nginx.conf` file
