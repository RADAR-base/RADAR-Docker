#!/bin/bash

set -eu

echo $PWD

pushd .
cd dcompose-stack/radar-cp-hadoop-stack
./bin/radar-docker down
popd
