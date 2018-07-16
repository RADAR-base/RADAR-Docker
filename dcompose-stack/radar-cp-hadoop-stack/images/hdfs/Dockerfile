ARG BASE_VERSION=3.0.3-alpine
FROM smizy/hadoop-base:${BASE_VERSION}

COPY ./hdfs-site.xml.mustache ${HDFS_CONF_DIR}/
COPY ./entrypoint.sh /usr/local/bin/
