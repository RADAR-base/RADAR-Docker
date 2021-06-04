#!/bin/bash

set -eu

pushd .
cd dcompose-stack/radar-cp-hadoop-stack
./bin/radar-docker down
popd
