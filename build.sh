#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

set -e -x

usage() {
    cat >&2 <<EOF
Usage: $0 [target]
Available Targets:
  local (default)
  all
  tpot
  virusalert
EOF
    exit 1
}

tpot() {
    "${script_dir}/charts/teapot/build/tpot.py"
}

virusalert() {
    pushd "${script_dir}/charts/virusalert/container"
        docker build . -t ajmansfield/virusalert
        docker push ajmansfield/virusalert
    popd
}
lad() {
    pushd "${script_dir}/charts/lad/container"
        docker build . -t ajmansfield/log-anomaly-detector
        docker push ajmansfield/log-anomaly-detector
    popd
}


all() {
    tpot
    virusalert
    lad
}
local() { # targets that need to be built locally on each machine
    tpot
}

target=${1:-local}
case $target in
    (tpot) tpot ;;
    (virusalert) virusalert ;;
    (lad) lad ;;
    (all) all ;;
    (local) local ;;
    (*) usage ;;
esac