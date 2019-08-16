#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Please select the Node you want to install in this instance."
select node in "DATA_NODE" "NAME_NODE"; do
  case ${node} in
    "DATA_NODE")
      echo "Please select the Node you want to install in this instance."
      select number in "1" "2" "3"; do
        .lib/perform-install.sh "DATA" ${number}
