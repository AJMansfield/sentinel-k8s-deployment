#!/bin/bash


usage() {
    cat >&2 <<EOF
Usage: $0 [-n <hostname>] [-p <password>] [-d <sys_root>] 
  -h <hostname>: FQDN hostname for Rancher (default: "$(hostname -f)")
  -p <password>: Bootstrap password for Rancher (default: random).
  -d <sys_root>: System root to install into (default: "/").
EOF
    exit 1
}

hostname=$(hostname -f)
password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
sys_root=''
while getopts h:p:d o; do
  case $o in
    (h) hostname="$OPTARG";;
    (p) password="$OPTARG";;
    (d) sys_root="$OPTARG";;
    (*) usage
  esac
done
shift "$((OPTIND - 1))"



set -e -x
script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
pkg_root="${script_dir}/system"
sys_root="${sys_root}"


# hacky on-the-fly editing the rancher config to set hostname + bootstrap pass
config_file="${pkg_root}/var/lib/rancher/rke2/server/manifests/rancher-config.yaml"

temp_dir=$(mktemp -d)
pushd "${temp_dir}"

csplit "${config_file}" '/### INSTALLER POSTSCRIPT MARKER ###/1'
cat xx00 - > "${config_file}" <<EOF
    ### BEGIN GENERATED CONFIGURATION ###
    hostname: "${hostname}"
    bootstrapPassword: "${password}"
EOF

popd
rm -rd "${temp_dir}"
# end hacky on-the-fly config modifications


# install RKE2 if not already installed
[ -f "${sys_root}/usr/local/bin/rke2" ] || { 
    # INSTALL_RKE2_TAR_PREFIX="${sys_root}/usr/local" # maybe??
    curl -sfL https://get.rke2.io | sudo sh - ; 
}

# install our custom kubernetes manifest files
shopt -s globstar
pushd "${pkg_root}"
for f in **/*.*; do
    echo sudo mkdir -p --mode=755 "$(dirname -- "${sys_root}/${f}")"
    echo sudo install --mode=644 "${pkg_root}/${f}" "${sys_root}/${f}"
done
popd

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
bootstrap password: ${bootstrapPassword}
EOF
