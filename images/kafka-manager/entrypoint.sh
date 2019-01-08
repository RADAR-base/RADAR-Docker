#!/bin/bash

rm -f RUNNING_PID
exec ./bin/kafka-manager -Dconfig.file=conf/application.conf
