#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

export LD_LIBRARY_PATH=${DIR}/lib
export PATH=${DIR}/bin:${PATH}

case $1 in
start)
    ${DIR}/bin/openssl "$@"
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
