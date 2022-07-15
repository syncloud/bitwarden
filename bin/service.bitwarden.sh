#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

export PATH=${DIR}/bin:${PATH}
cd ${SNAP_DATA}/config
exec ${DIR}/bin/vaultwarden
