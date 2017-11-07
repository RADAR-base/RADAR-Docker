FROM hseeberger/scala-sbt as builder
ENV KM_VERSION=1.3.3.14

RUN mkdir -p /tmp && \
    cd /tmp && \
    wget https://github.com/yahoo/kafka-manager/archive/${KM_VERSION}.tar.gz && \
    tar xxf ${KM_VERSION}.tar.gz && \
    cd /tmp/kafka-manager-${KM_VERSION} && \
    sbt clean dist && \
    unzip  -d / ./target/universal/kafka-manager-${KM_VERSION}.zip && \
    rm -fr /tmp/${KM_VERSION} /tmp/kafka-manager-${KM_VERSION} && \
    mv /kafka-manager-${KM_VERSION} /kafka-manager

COPY ./conf/application.conf /kafka-manager-${KM_VERSION}/conf/application.conf
WORKDIR /kafka-manager-${KM_VERSION}

FROM openjdk:8-alpine
MAINTAINER Yatharth Ranjan <https://github.com/yatharthranjan>

ENV ZK_HOSTS=zookeeper-1:2181
RUN apk add --no-cache bash

COPY --from=builder /kafka-manager /kafka-manager
COPY ./conf/application.conf /kafka-manager/conf/application.conf
WORKDIR /kafka-manager

EXPOSE 9000
ENTRYPOINT ["./bin/kafka-manager","-Dconfig.file=conf/application.conf"]
