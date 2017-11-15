FROM openjdk:8-alpine

MAINTAINER Joris Borgdorff <joris@thehyve.nl>

ENV KAFKA_SCHEMA_REGISTRY=http://schema-registry-1:8081
ENV KAFKA_NUM_PARTITIONS=3
ENV KAFKA_NUM_REPLICATION=2
ENV KAFKA_NUM_BROKERS=3
ENV KAFKA_ZOOKEEPER_CONNECT=zookeeper-1:2181

RUN apk add --no-cache rsync tar bash wget

RUN mkdir -p /schema/merged

WORKDIR /schema

ADD https://github.com/RADAR-CNS/RADAR-Schemas/archive/v0.2.tar.gz /schema/RADAR-Schemas-0.2.tar.gz
RUN tar xzf RADAR-Schemas-0.2.tar.gz && mv RADAR-Schemas-0.2 original && rm RADAR-Schemas-0.2.tar.gz

ADD https://github.com/RADAR-CNS/RADAR-Schemas/releases/download/v0.2/radar-schemas-tools-0.2.tar.gz /schema/radar-schemas-tools-0.2.tar.gz
RUN tar xzf radar-schemas-tools-0.2.tar.gz --strip-components=1 -C /usr && rm radar-schemas-tools-0.2.tar.gz

VOLUME /schema/conf

# Copy bash file
COPY ./topic_init.sh ./init.sh ./list_aggregated.sh ./list_raw.sh /usr/bin/
RUN chmod +x /usr/bin/*.sh

ENTRYPOINT ["init.sh"]
CMD ["topic_init.sh"]

