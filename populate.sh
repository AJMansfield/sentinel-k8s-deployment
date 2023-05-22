#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

set -e -x

usage() {
  cat >&2 <<EOF
Usage: $0 elastic <action>
       $0 virusalert <action>
       $0 lad <action>
       $0 honeypot <action> <id>
  <action> is one of "install", "upgrade", or "uninstall".
  <id> can be an arbitrary ID corresponding to a honeypot value file.
EOF
  exit 1
}

elastic() {
  if [ $1 == "uninstall" ]
  then
    helm $1 elastic --namespace elastic
  else
    helm $1 elastic "${script_dir}/charts/elastic" \
      --namespace elastic --create-namespace \
      --values "${script_dir}/values/elastic.yaml"
  fi
}

virusalert() {
  if [ $1 == "uninstall" ]
  then
    helm $1 virusalert --namespace virusalert
  else
    helm $1 virusalert "${script_dir}/charts/virusalert" \
      --namespace virusalert --create-namespace \
      --values "${script_dir}/values/virusalert-config.yaml" \
      --values "${script_dir}/values/virusalert-secret.yaml"
  fi
}

lad() {
  if [ $1 == "uninstall" ]
  then
    helm $1 lad --namespace lad
  else
    helm $1 lad "${script_dir}/charts/lad" \
      --namespace lad --create-namespace \
      --values "${script_dir}/values/lad.yaml"
  fi
}

honeypot() {
  if [ $1 == "uninstall" ]
  then
    helm $1 "honeypot-${2}" --namespace "honeypot-${2}"
  else
    helm $1 "honeypot-${2}" "${script_dir}/charts/teapot" \
      --namespace "honeypot-${2}" --create-namespace \
      --values "${script_dir}/values/honeypot-${2}.yaml"
  fi
}

module=$1
shift
case $module in
  (elastic) elastic $@ ;;
  (virusalert) virusalert $@ ;;
  (lad) lad $@ ;;
  (honeypot) honeypot $@ ;;
  (*) usage ;;
esac