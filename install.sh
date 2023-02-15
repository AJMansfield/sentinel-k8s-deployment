#!/bin/bash

set -e -x
script_path==$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

sudo cp --interactive --verbose --backup --recursive "$script_path/system/" "/"

curl -sfL https://get.rke2.io | sudo sh -

sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service