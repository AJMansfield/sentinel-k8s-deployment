#!/bin/bash

set -e
script_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
script_name="$0"

usage() {
  cat >&2 <<EOF
Usage: $script_name [-h <hostname>] [-p <password>] [-d <sys_root>] 
  -h <hostname>: FQDN hostname for Rancher (default: "$(hostname -f)").
  -p <password>: Bootstrap password for Rancher (default: random).
  -d <sys_root>: System root to install into (default: "/").
EOF
  exit 1
}

parse_opts() {
  hostname=$(hostname -f)
  password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  sys_root=''
  while getopts h:p:d: o; do
    case $o in
      (h) hostname="$OPTARG";;
      (p) password="$OPTARG";;
      (d) sys_root="$OPTARG";;
      (*) usage "$@"
    esac
  done
  shift "$((OPTIND - 1))"

  set -x
  pkg_root="${script_dir}/system"
  sys_root="${sys_root}"
}

install_system_packages() {
  set -x
  sudo apt install -y nfs-common
}

create_chart_configs() {
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
}

install_rke2() {
  # install RKE2 -- if not already installed
  [ -f "${sys_root}/usr/local/bin/rke2" ] && return 0
   
  curl -sfL https://get.rke2.io | \
  INSTALL_RKE2_TAR_PREFIX="${sys_root}/usr/local" sudo sh - 
}

install_system_files() {
  # mostly we're installing /var/lib/rancher/rke2/server/manifests/*
  # but there's also some other misc config in /system that this also puts elsewhere
  shopt -s globstar
  set -x
  pushd "${pkg_root}"
  for f in **/*.*; do
    sudo mkdir -p --mode=755 "$(dirname -- "${sys_root}/${f}")"
    sudo install --mode=644 "${pkg_root}/${f}" "${sys_root}/${f}"
  done
  popd
}

start_rke2() {
  set -x
  # apply the exclusions in /etc/NetworkManager/conf.d/rke2-canal.conf
  systemctl reload NetworkManager || true

  # enable and start the systemd units
  systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
  systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service
}

copy_authentication() {
  set -x
  # copy authentication for installed server to user's config
  mkdir -p ~/.kube
  cp --backup --force ~/.kube/config ~/.kube/config || true
  sudo cat /etc/rancher/rke2/rke2.yaml \
  | tee ~/.kube/config > /dev/null
}

display_success_message() {
  cat - <<EOF

Install Complete!
=================
hostname: https://${hostname}/dashboard/
bootstrap password: ${password}
EOF
}

parse_opts "$@"
install_system_packages
create_chart_configs
install_system_files
install_rke2
start_rke2
copy_authentication
display_success_message