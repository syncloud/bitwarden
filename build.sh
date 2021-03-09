#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir -p ${DIR}/build/bin
cp bitwarden_rs ${DIR}/build/bin
