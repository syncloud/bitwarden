#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

export DOMAIN=http://localhost:3011
export WEBSOCKET_ENABLED=true
export WEBSOCKET_ADDRESS=localhost
export WEBSOCKET_PORT=3012
export LD_LIBRARY_PATH=${DIR}/lib
export DATA_FOLDER=/var/snap/bitwarden/current
. ${SNAP_DATA}/config/.env

case $1 in
start)
    exec ${DIR}/lib/ld.so ${DIR}/bitwarden_rs
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
