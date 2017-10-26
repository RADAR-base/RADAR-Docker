FROM hseeberger/scala-sbt

RUN mkdir /kafka-manager-1.3.3.14
ADD . /kafka-manager-1.3.3.14
ENV ZK_HOSTS=zookeeper-1:2181
WORKDIR /kafka-manager-1.3.3.14

EXPOSE 9000
ENTRYPOINT ["./bin/kafka-manager","-Dconfig.file=conf/application.conf"]
