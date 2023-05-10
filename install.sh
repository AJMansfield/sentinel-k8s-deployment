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

  pkg_root="${script_dir}/system"
}

install_system_packages() {
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
    global:
      cattle:
        psp:
          enabled: false
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

  pushd "${pkg_root}"
  find * -type f \
  | while IFS=$'\n' read f
  do 
    sudo mkdir --verbose --parents --mode=755 "$(dirname -- "${sys_root}/${f}")"
    sudo cp --verbose --update "${pkg_root}/${f}" "${sys_root}/${f}"
  done
  popd
}

start_rke2() {
  # apply the exclusions in /etc/NetworkManager/conf.d/rke2-canal.conf
  sudo systemctl reload NetworkManager || true

  # enable and start the systemd units
  systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
  systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service
}

copy_authentication() {
  # copy authentication for installed server to user's config
  mkdir -p ~/.kube
  cp --backup --force ~/.kube/config ~/.kube/config || true
  sudo cat /etc/rancher/rke2/rke2.yaml \
  | tee ~/.kube/config > /dev/null
}

wait_until_rancher_is_up() {
  echo "Waiting for Rancher to come up..."
  # could take as long a 3 minutes (=180 seconds)
  # check in 5-second steps, so 40 steps in all
  max_retry=40
  counter=0
  until curl -sfk "https://${hostname}/"
  do
    [[ $counter -ge $max_retry ]] && { echo "Failed!" ; return 1 ; }
    echo -n .
    ((counter++))
    sleep 5
  done
  echo "Complete!"
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
wait_until_rancher_is_up
display_success_message