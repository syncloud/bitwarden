#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BITWARDEN_RS_VERSION=1.19.0
BITWARDEN_WEB_VERSION=2.18.2

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build
mkdir -p ${BUILD_DIR}

cd $BUILD_DIR
wget --progress=dot:giga https://github.com/dani-garcia/bitwarden_rs/archive/${BITWARDEN_RS_VERSION}.tar.gz
tar xf ${BITWARDEN_RS_VERSION}.tar.gz
mv bitwarden_rs-${BITWARDEN_RS_VERSION} bitwarden_rs

wget --progress=dot:giga https://github.com/dani-garcia/bw_web_builds/releases/download/v${BITWARDEN_WEB_VERSION}/bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz
tar xf bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz
