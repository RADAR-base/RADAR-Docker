FROM hseeberger/scala-sbt:8u171-2.12.6-1.2.0 as builder
ENV SBT_VERSION=0.13.9

RUN mkdir /code

WORKDIR /code

RUN sbt -sbt-version ${SBT_VERSION}

ENV KM_VERSION=1.3.3.18

RUN wget https://github.com/yahoo/kafka-manager/archive/${KM_VERSION}.tar.gz && \
    tar xxf ${KM_VERSION}.tar.gz && \
    cd kafka-manager-${KM_VERSION} && \
    sbt clean dist && \
    unzip  -d / ./target/universal/kafka-manager-${KM_VERSION}.zip && \
    mv /kafka-manager-${KM_VERSION} /kafka-manager

FROM openjdk:8-alpine
MAINTAINER Yatharth Ranjan <https://github.com/yatharthranjan>

ENV ZK_HOSTS=zookeeper-1:2181
RUN apk add --no-cache bash

COPY --from=builder /kafka-manager /kafka-manager
COPY ./conf/application.conf /kafka-manager/conf/application.conf
COPY ./entrypoint.sh /kafka-manager/
WORKDIR /kafka-manager

EXPOSE 9000
ENTRYPOINT ["./entrypoint.sh"]
