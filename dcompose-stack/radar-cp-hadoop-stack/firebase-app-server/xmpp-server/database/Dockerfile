FROM openjdk:8-jre-alpine

MAINTAINER yatharth.ranjan@kcl.ac.uk

ENV MVN_CENTRAL_URL http://central.maven.org/maven2
ENV HSQLDB_MVN_GRP org/hsqldb
ENV HSQLDB_VERSION 2.4.0
ENV LOG4J_VERSION 1.2.17

ENV SERVER_PROPERTY_PATH /etc/opt/hsqldb/conf/server.properties
ENV SQL_TOOL_RC_PATH /etc/opt/hsqldb/conf/sqltool.rc

RUN apk update \
    && apk add ca-certificates wget openssl \
    && update-ca-certificates && \
    mkdir -p /opt/hsqldb/lib \
    && wget -O /opt/hsqldb/lib/hsqldb.jar \
       "${MVN_CENTRAL_URL}/${HSQLDB_MVN_GRP}/hsqldb/${HSQLDB_VERSION}/hsqldb-${HSQLDB_VERSION}.jar" \
    && wget -O /opt/hsqldb/lib/sqltool.jar \
       "${MVN_CENTRAL_URL}/${HSQLDB_MVN_GRP}/sqltool/${HSQLDB_VERSION}/sqltool-${HSQLDB_VERSION}.jar" \
    && wget -O /opt/hsqldb/lib/log4j.jar \
       "${MVN_CENTRAL_URL}/log4j/log4j/${LOG4J_VERSION}/log4j-${LOG4J_VERSION}.jar" \
    && mkdir -p /etc/opt/hsqldb/conf \
    && mkdir -p /var/opt/hsqldb/sql \
    && mkdir -p /var/opt/hsqldb/data \
    && mkdir -p /var/opt/hsqldb/run \
    && addgroup -S hsqldb \
    && adduser -S -g hsqldb hsqldb

#
#RUN chown hsqldb:hsqldb -R /opt/hsqldb \
#    && chown hsqldb:hsqldb -R /var/opt/hsqldb \
#    && chown hsqldb:hsqldb -R /etc/opt/hsqldb

EXPOSE 9001
#USER hsqldb

CMD java -cp /opt/hsqldb/lib/*:/etc/opt/hsqldb/conf org.hsqldb.server.Server --props ${SERVER_PROPERTY_PATH}