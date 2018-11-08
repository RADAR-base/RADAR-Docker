#!/bin/bash
set -e
set -u

DB_HOST="localhost"
DB_PORT=5432

function wait_for_db() {
    for count in {1..30}; do
          echo "Pinging postgres database attempt "${count}
          if  $(nc -z ${DB_HOST} ${DB_PORT}) ; then
            echo "Can connect into database"
            break
          fi
          sleep 1
    done
}
function create_user_and_database() {
	local database=$1
	echo "Processing database '$database'"
	local query_databases="select datname from pg_database;"
    local database_exist=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='$database'")
	if [[ "$database_exist" == 1 ]];
    then
        echo "Database already exists"
    else
        echo "Database does not exist"
        echo "  Creating database '$database' for user '$POSTGRES_USER'"
        psql -v ON_ERROR_STOP=1  <<-EOSQL
	    CREATE DATABASE '$database';
	    GRANT ALL PRIVILEGES ON DATABASE '$database' TO '$POSTGRES_USER';
EOSQL
    fi

}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	  #waiting for postgres
    wait_for_db
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_user_and_database $db
	done
	echo "Multiple databases created"
fi