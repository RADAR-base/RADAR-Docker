ARG POSTGRES_VERSION=10.4-alpine
FROM postgres:${POSTGRES_VERSION}

COPY ./entrypoint.sh /docker-entrypoint-initdb.d/multi-db-init.sh

