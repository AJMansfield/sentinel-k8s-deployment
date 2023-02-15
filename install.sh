#!/bin/bash

set -e -x
script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# install RKE2 if not already installed
[ -f /usr/local/bin/rke2 ] || { curl -sfL https://get.rke2.io | sudo sh - ; }

# install our custom configurations
sudo cp --verbose --recursive "$script_path/system/." "/."

# enable and start the system units
systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service

# copy authentication for installed server to user's config
cp --backup --force ~/.kube/config ~/.kube/config
sudo cat /etc/rancher/rke2/rke2.yaml | tee ~/.kube/config