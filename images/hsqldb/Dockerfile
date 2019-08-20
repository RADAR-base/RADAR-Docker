FROM openjdk:12-oracle

MAINTAINER yatharth.ranjan@kcl.ac.uk

ENV MVN_CENTRAL_URL http://central.maven.org/maven2
ENV HSQLDB_MVN_GRP org/hsqldb
ENV HSQLDB_VERSION 2.5.0
ENV LOG4J_VERSION 1.2.17

ENV SERVER_PROPERTY_PATH /etc/opt/hsqldb/conf/server.properties
ENV SQL_TOOL_RC_PATH /etc/opt/hsqldb/conf/sqltool.rc

RUN mkdir -p /opt/hsqldb/lib /etc/opt/hsqldb/conf /var/opt/hsqldb/data

RUN curl -#o /opt/hsqldb/lib/hsqldb.jar \
       "${MVN_CENTRAL_URL}/${HSQLDB_MVN_GRP}/hsqldb/${HSQLDB_VERSION}/hsqldb-${HSQLDB_VERSION}.jar"
RUN curl -#o /opt/hsqldb/lib/sqltool.jar \
       "${MVN_CENTRAL_URL}/${HSQLDB_MVN_GRP}/sqltool/${HSQLDB_VERSION}/sqltool-${HSQLDB_VERSION}.jar"
RUN curl -#o /opt/hsqldb/lib/log4j.jar \
       "${MVN_CENTRAL_URL}/log4j/log4j/${LOG4J_VERSION}/log4j-${LOG4J_VERSION}.jar"

RUN groupadd --system hsqldb
RUN useradd --system -g hsqldb hsqldb

RUN chown hsqldb:hsqldb -R /var/opt/hsqldb

EXPOSE 9001
USER hsqldb
WORKDIR /var/opt/hsqldb/data

CMD java -cp /opt/hsqldb/lib/*:/etc/opt/hsqldb/conf org.hsqldb.server.Server --props ${SERVER_PROPERTY_PATH}
