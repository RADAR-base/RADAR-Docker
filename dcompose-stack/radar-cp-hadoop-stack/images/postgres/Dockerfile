ARG POSTGRES_VERSION=10.6-alpine
FROM postgres:${POSTGRES_VERSION}

COPY ./multi-db-init.sh /docker-entrypoint-initdb.d/multi-db-init.sh
COPY ./on-db-ready /usr/bin/on-db-ready
