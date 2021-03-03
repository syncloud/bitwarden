#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BITWARDEN_VERSION=1.19.0

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build
mkdir -p ${BUILD_DIR}

cd $BUILD_DIR
wget --progress=dot:giga https://github.com/dani-garcia/bitwarden_rs/archive/${BITWARDEN_VERSION}.tar.gz
tar xf ${BITWARDEN_VERSION}.tar.gz
mv bitwarden_rs-${BITWARDEN_VERSION} bitwarden_rs
