#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

values_basepaths=("${script_dir}/values")
if [ -n "${VALUES_DIR}" ]
then
  values_basepaths+=("${VALUES_DIR}")
else
  if [ "$(readlink -f "${HOME}/values")" != "$(readlink -f "${script_dir}/../values")" ]
  then
    values_basepaths+=("${HOME}/values")
  fi
  values_basepaths+=("${script_dir}/../values")
fi

set_values_flags() {
  values_flags=()
  for p in "${values_basepaths[@]}"
  do
    for f in "$@"
    do
      if [ -f "$p/$f" ]
      then
        values_flags+=(--values "$p/$f")
      fi
    done
  done
}

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
    set -e -x
    helm $1 elastic --namespace elastic
  else
    set_values_flags elastic.yaml
    set -e -x
    helm $1 elastic "${script_dir}/charts/elastic" \
      --namespace elastic --create-namespace \
      "${values_flags[@]}"
  fi
}

virusalert() {
  if [ $1 == "uninstall" ]
  then
    set -e -x
    helm $1 virusalert --namespace virusalert
  else
    set_values_flags virusalert-config.yaml virusalert-secret.yaml
    set -e -x
    helm $1 virusalert "${script_dir}/charts/virusalert" \
      --namespace virusalert --create-namespace \
      "${values_flags[@]}"
  fi
}

lad() {
  if [ $1 == "uninstall" ]
  then
    set -e -x
    helm $1 lad --namespace lad
  else
    set_values_flags lad.yaml
    set -e -x
    helm $1 lad "${script_dir}/charts/lad" \
      --namespace lad --create-namespace \
      "${values_flags[@]}"
  fi
}

honeypot() {
  if [ $1 == "uninstall" ]
  then
    set -e -x
    helm $1 "honeypot-${2}" --namespace "honeypot-${2}"
  else
    set_values_flags "honeypot-${2}.yaml"
    set -e -x
    helm $1 "honeypot-${2}" "${script_dir}/charts/teapot" \
      --namespace "honeypot-${2}" --create-namespace \
      "${values_flags[@]}"
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