#!/bin/bash
# This is a preliminary check on health

set -eu

DB_CONTAINER=radar-cp-hadoop-stack_radarbase-postgresql_1

./wait-for-it.sh -t 150 localhost:80 --strict -- echo "Postgres database is ready!"

# Restore the prostgres database
rm -rf /tmp/postgres_dump
aws s3 cp s3://radar-codedeploy/radar_backend_postgres_dump /tmp/postgres_dump
docker cp /tmp/postgres_dump $DB_CONTAINER:/tmp/postgres_dump
docker exec -it $DB_CONTAINER psql -U postgres -f /tmp/postgres_dump postgres