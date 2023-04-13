#!/bin/bash

set -e -x

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

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

all() {
    tpot
    virusalert
}
local() { # targets that need to be built locally on each machine
    tpot
}

target=${1:-local}
case $target in
    (tpot) tpot ;;
    (virusalert) virusalert ;;
    (all) all ;;
    (local) local ;;
    (*) usage ;;
esac