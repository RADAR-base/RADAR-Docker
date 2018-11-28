FROM openjdk:8-alpine

MAINTAINER Joris Borgdorff <joris@thehyve.nl>

ENV KAFKA_SCHEMA_REGISTRY=http://schema-registry-1:8081
ENV KAFKA_NUM_PARTITIONS=3
ENV KAFKA_NUM_REPLICATION=2
ENV KAFKA_NUM_BROKERS=3
ENV KAFKA_ZOOKEEPER_CONNECT=zookeeper-1:2181

RUN apk add --no-cache \
  bash \
  curl \
  rsync \
  tar

RUN mkdir -p /schema/merged /schema/java/src /schema/java/classes /usr/share/java

WORKDIR /schema

ENV JQ_VERSION=1.5
RUN curl -L#o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 \
    && chmod +x /usr/bin/jq
RUN curl -#o /usr/share/java/avro-tools.jar \
 "$(curl -s http://www.apache.org/dyn/closer.cgi/avro/\?as_json \
  | jq --raw-output ".preferred")avro/avro-1.8.2/java/avro-tools-1.8.2.jar"

ARG SCHEMAS_VERSION=0.4.2

ENV RADAR_SCHEMAS_VERSION=${SCHEMAS_VERSION}

RUN curl -#L https://github.com/RADAR-base/RADAR-Schemas/releases/download/v${RADAR_SCHEMAS_VERSION}/radar-schemas-tools-${RADAR_SCHEMAS_VERSION}.tar.gz \
  | tar xz -C /usr --strip-components 1

RUN mkdir original \
  && curl -#L https://github.com/RADAR-base/RADAR-Schemas/archive/v${RADAR_SCHEMAS_VERSION}.tar.gz \
  | tar xz -C original --strip-components 1

VOLUME /schema/conf

# Copy bash file
COPY ./topic_init.sh ./init.sh ./list_aggregated.sh ./list_raw.sh /usr/bin/
RUN chmod +x /usr/bin/*.sh

ENTRYPOINT ["init.sh"]
CMD ["topic_init.sh"]
