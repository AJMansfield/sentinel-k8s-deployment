#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

set -e -x

usage() {
  cat >&2 <<EOF
Usage: $0 elastic <action>
       $0 virusalert <action>
       $0 honeypot <action> <id>
  <action> is one of "install", "upgrade", or "uninstall".
  <id> can be an arbitrary ID corresponding to a honeypot value file.
EOF
  exit 1
}

elastic() {
  helm $1 elastic "${script_dir}/charts/elastic" \
    --namespace elastic --create-namespace \
    --values "${script_dir}/values/elastic.yaml"
}

virusalert() {
  helm $1 virusalert "${script_dir}/charts/virusalert" \
    --namespace virusalert --create-namespace \
    --values "${script_dir}/values/virusalert.yaml"
}

honeypot() {
  helm $1 "honeypot-${2}" "${script_dir}/charts/teapot" \
    --namespace "honeypot-${2}" --create-namespace \
    --values "${script_dir}/values/honeypot-${2}.yaml"
}

case $1 in
  (elastic) elastic $2 ;;
  (virusalert) virusalert $2 ;;
  (honeypot) honeypot $2 "${3}" ;;
  (*) usage ;;
esac