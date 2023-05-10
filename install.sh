#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

usage() {
  cat >&2 <<EOF
Usage: $0 [-h <hostname>] [-p <password>] [-d <sys_root>] 
  -h <hostname>: FQDN hostname for Rancher (default: "$(hostname -f)").
  -p <password>: Bootstrap password for Rancher (default: random).
  -d <sys_root>: System root to install into (default: "/").
EOF
  exit 1
}

hostname=$(hostname -f)
password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
sys_root=''
while getopts h:p:d: o; do
  case $o in
    (h) hostname="$OPTARG";;
    (p) password="$OPTARG";;
    (d) sys_root="$OPTARG";;
    (*) usage
  esac
done
shift "$((OPTIND - 1))"

set -e -x
pkg_root="${script_dir}/system"
sys_root="${sys_root}"

sudo apt install -y nfs-common

# template out the config with the hostname and password
config_file="${pkg_root}/var/lib/rancher/rke2/server/manifests/rancher-config.yaml"
cat > "${config_file}" <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rancher
  namespace: kube-system
spec:
  valuesContent: |- 
    hostname: "${hostname}"
    bootstrapPassword: "${password}"
EOF

# install RKE2 if not already installed
[ -f "${sys_root}/usr/local/bin/rke2" ] || { 
    curl -sfL https://get.rke2.io | \
    INSTALL_RKE2_TAR_PREFIX="${sys_root}/usr/local" sudo sh - ; 
}

# install our custom kubernetes manifest files
shopt -s globstar
pushd "${pkg_root}"
for f in **/*.*; do
  sudo mkdir -p --mode=755 "$(dirname -- "${sys_root}/${f}")"
  sudo install --mode=644 "${pkg_root}/${f}" "${sys_root}/${f}"
done
popd

# apply the exclusions in /etc/NetworkManager/conf.d/rke2-canal.conf
systemctl reload NetworkManager || true

# enable and start the systemd units
systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service

# copy authentication for installed server to user's config
mkdir -p ~/.kube
cp --backup --force ~/.kube/config ~/.kube/config || true
sudo cat /etc/rancher/rke2/rke2.yaml | tee ~/.kube/config > /dev/null

set +x
cat - <<EOF

Install Complete!
=================
hostname: https://${hostname}/dashboard/
bootstrap password: ${password}
EOF