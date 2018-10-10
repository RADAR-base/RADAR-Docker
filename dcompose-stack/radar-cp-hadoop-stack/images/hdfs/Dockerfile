ARG BASE_VERSION=3.0.3-alpine
FROM smizy/hadoop-base:${BASE_VERSION}

ENV HADOOP_DFS_NAME_DIR file://hadoop/dfs/name

COPY ./hdfs-site.xml.mustache ${HADOOP_CONF_DIR}/
COPY ./entrypoint.sh /usr/local/bin/
