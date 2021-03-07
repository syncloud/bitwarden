#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

export LD_LIBRARY_PATH=${DIR}/lib
export PATH=${DIR}/bin:${PATH}
cd ${SNAP_DATA}/config

case $1 in
start)
    exec ${DIR}/lib/ld.so ${DIR}/bin/bitwarden_rs
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
