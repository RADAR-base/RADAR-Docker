#!/bin/bash

set -m

cmd="mongod"

if [ "$AUTH" == "yes" ]; then
    cmd="$cmd --auth"
fi

echo "=> Starting MongoDB"

$cmd &

/db_init.sh

fg