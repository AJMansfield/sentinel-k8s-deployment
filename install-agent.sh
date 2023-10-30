#!/bin/bash

script_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
script_name="$0"

usage() {
  cat >&2 <<EOF
Usage: $script_name [-d <sys_root>] [-a <agent_config_path>]
  -d <sys_root>: System root to install into (default: "/").
  -a <agent_config_path>: Path to read agent config from (default: stdin).
EOF
  exit 1
}

parse_opts() {
  hostname=$(hostname -f)
  password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  sys_root=''
  agent_config_path='-'
  while getopts h:p:d: o; do
    case $o in
      (d) sys_root="$OPTARG";;
      (a) agent_config_path="$OPTARG";;
      (*) usage "$@"
    esac
  done
  shift "$((OPTIND - 1))"

  pkg_root="${script_dir}/system"
}

install_system_packages() {
  sudo apt install -y nfs-common python3-slugify python3-yaml
  sudo snap install helm --classic
}

install_rke2() {
  # install RKE2 -- if not already installed
  [ -f "${sys_root}/usr/local/bin/rke2" ] && return 0
  
  curl -sfL https://get.rke2.io | \
  INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_TAR_PREFIX="${sys_root}/usr/local" sudo sh -
}

install_system_files() {
  # only installing the misc /system/etc parts; the manifests are only installed on the server

  pushd "${pkg_root}/etc"
  find * -type f \
  | while IFS=$'\n' read f
  do 
    sudo mkdir --verbose --parents --mode=755 "$(dirname -- "${sys_root}/etc/${f}")"
    sudo cp --verbose --update "${pkg_root}/etc/${f}" "${sys_root}/etc/${f}"
  done
  popd
}

read_agent_config() {
  sudo cp --verbose "${pkg_root}/etc/rancher/rke2/config.yaml" "${sys_root}/etc/rancher/rke2/config.yaml"
  if [ "${agent_config_path}" = '-' ] && [ -t 0 ]; then
    echo "Input Agent Configuration (^D to finish):" >&2
  else
    echo "Copying agent configuration." >&2
  fi
  {
    echo '' # extra newline padding just to be a bit careful
    cat "${agent_config_path}"
  } | sudo tee -a "${sys_root}/etc/rancher/rke2/config.yaml" >/dev/null

}

start_rke2() {
  # enable and start the systemd units
  systemctl is-enabled --quiet rke2-agent.service || sudo systemctl enable rke2-agent.service
  systemctl is-active --quiet rke2-agent.service || sudo systemctl start rke2-agent.service
}

do_netconfig() {
  sudo systemctl daemon-reload

  # apply the exclusions in /etc/NetworkManager/conf.d/rke2-canal.conf
  sudo systemctl reload NetworkManager || true

  # enable responders for different name resolution protocols
  sudo systemctl enable multicast-dns
  sudo systemctl start multicast-dns
  sudo systemctl restart systemd-resolved
}


display_success_message() {
  echo "Install Complete!" >&2
}

parse_opts "$@"
set -e
install_system_packages
install_system_files
read_agent_config
do_netconfig
install_rke2
set +e
start_rke2
display_success_message