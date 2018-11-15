#!/bin/bash
set -e
set -u

DB_HOST="localhost"
DB_PORT=5432

function wait_for_db() {
  echo "Waiting for postgres database..."
  for count in {1..120}; do
    if nc -z ${DB_HOST} ${DB_PORT}; then
      echo "Database ready."
      sleep 5
      return 0
    fi
    sleep 1
  done
  return 1
}

function create_user_and_database() {
  local database=$1
  echo "Processing database '$database'"
  local query_databases="select datname from pg_database;"
  local database_exist=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='$database'")
  if [[ "$database_exist" == 1 ]]; then
    echo "Database already exists"
  else
    echo "Database does not exist"
    echo "  Creating database '$database' for user '$POSTGRES_USER'"
    psql -v ON_ERROR_STOP=1  <<-EOSQL
    CREATE DATABASE $database;
    GRANT ALL PRIVILEGES ON DATABASE $database TO $POSTGRES_USER;
EOSQL
  fi
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
  echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
  #waiting for postgres
  if ! wait_for_db; then
    echo "Postgres database timeout"
    exit 1
  fi
  for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
    create_user_and_database $db
  done
  echo "Multiple databases created"
fi
