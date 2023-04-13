#!/bin/bash

set -e -x

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

usage() {
    cat >&2 <<EOF
Usage: $0 <target>
Available Targets:
  tpot
  virusalert
  all
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

case $1 in
    (tpot) tpot ;;
    (virusalert) virusalert ;;
    (all) all ;;
    (*) usage ;;
esac