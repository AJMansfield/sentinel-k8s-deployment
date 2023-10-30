#!/bin/bash

script_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
script_name="$0"

usage() {
  cat >&2 <<EOF
Usage: $script_name [-h <hostname>] [-p <password>] [-d <sys_root>] [-a <agent_config_path>]
  -h <hostname>: FQDN hostname for Rancher (default: "$(hostname -f)").
  -p <password>: Bootstrap password for Rancher (default: random).
  -d <sys_root>: System root to install into (default: "/").
  -a <agent_config_path>: Path to write the agent config to (default: stdout).
EOF
  exit 1
}

parse_opts() {
  hostname=$(hostname -f)
  password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  sys_root=''
  agent_config_path='-'
  while getopts h:p:d:a: o; do
    case $o in
      (h) hostname="$OPTARG";;
      (p) password="$OPTARG";;
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
  # enable and start the systemd units
  systemctl is-enabled --quiet rke2-server.service || sudo systemctl enable rke2-server.service
  systemctl is-active --quiet rke2-server.service || sudo systemctl start rke2-server.service
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

copy_authentication() {
  # copy authentication for installed server to user's config
  mkdir -p ~/.kube
  cp --backup --force ~/.kube/config ~/.kube/config || true
  sudo cat /etc/rancher/rke2/rke2.yaml \
  | tee ~/.kube/config > /dev/null
}

output_agent_config() {
  token=$(sudo cat "${pkg_root}/var/lib/rancher/rke2/server/node-token")
  read -d '' agent_config_content <<EOF
server: https://${hostname}:9345
token: ${token}
EOF
  if [ "${agent_config_path}" = '-' ]; then
    # tricky pipe operations to write the header separator parts to stderr, and only the actual config contents to stdout (so it could theoretically be piped out).
    cat >&2 <<EOF

Agent Config (copy to agent node's /etc/rancher/rke2/config.yaml):
------------------------------------------------------------------
EOF
    cat <<<"${agent_config_content}"
    cat >&2 <<EOF
------------------------------------------------------------------
EOF
  else
    echo "Writing agent config to ${agent_config_path}" >&2
    cat > "${agent_config_path}" <<<"${agent_config_content}"
}

wait_until_rancher_is_up() {
  echo "Waiting for Rancher to come up..." >&2
  # could take as long a 3 minutes (=180 seconds)
  # check in 5-second steps, so 40 steps in all
  for i in $(seq 40);
  do
    curl -sfk "https://${hostname}/" >/dev/null
    if [ $? -eq 0 ]; then
      echo "Complete!" >&2
      return 0
    else
      echo -n "." >&2
    fi
    sleep 5
  done
  return 1
}

display_success_message() {
  cat >&2 <<EOF

Install Complete!
=================
hostname: https://${hostname}/dashboard/
bootstrap password: ${password}
EOF
}

parse_opts "$@"
set -e
install_system_packages
create_chart_configs
install_system_files
do_netconfig
install_rke2
set +e
start_rke2
copy_authentication
output_agent_config
wait_until_rancher_is_up
display_success_message