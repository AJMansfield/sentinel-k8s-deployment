#!/bin/bash

set -e -x
script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

curl -sfL https://get.rke2.io | sudo sh -

sudo cp --interactive --verbose --backup --recursive "$script_path/system/." "/."

sudo systemctl enable rke2-server.service

# sudo journalctl --follow --unit=rke2-server.service --output=cat &
# journalctl_job=$!
# function finish {
#   kill $journalctl_job
# }
# trap finish EXIT

sudo systemctl start rke2-server.service