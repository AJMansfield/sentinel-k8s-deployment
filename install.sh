#!/bin/bash

set -e -x
script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
pkg_root="${script_dir}/system"
sys_root="${1:-}"

# install RKE2 if not already installed
# TODO pass sys_root to the RKE2 install script too
[ -f /usr/local/bin/rke2 ] || { curl -sfL https://get.rke2.io | sudo sh - ; }

# install our custom kubernetes manifest files
shopt -s globstar
pushd "${pkg_root}"
for f in **/*.*; do
    sudo install --mode=644 "${pkg_root}/${f}" "${sys_root}/${f}"
done
popd

# enable and start the systemd units
# systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service

# copy authentication for installed server to user's config
cp --backup --force ~/.kube/config ~/.kube/config
sudo cat /etc/rancher/rke2/rke2.yaml | tee ~/.kube/config