#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

case $1 in
start)
    export DOMAIN=http://localhost:3011
    export WEBSOCKET_ENABLED=true
    export WEBSOCKET_ADDRESS=localhost
    export WEBSOCKET_PORT=3012
    export LD_LIBRARY_PATH=${DIR}/lib
    exec ${DIR}/bitwarden_rs "${@}"
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
