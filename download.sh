#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BITWARDEN_WEB_VERSION=2.18.2
#BITWARDEN_RS_VERSION=master
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download
ARCH=$(uname -m)
BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR

cd ${DIR}/build

#wget --progress=dot:giga https://github.com/cyberb/bitwarden_rs/archive/${BITWARDEN_RS_VERSION}.tar.gz
#tar xf ${BITWARDEN_RS_VERSION}.tar.gz
#mv bitwarden_rs-${BITWARDEN_RS_VERSION} bitwarden_rs

wget --progress=dot:giga https://github.com/dani-garcia/bw_web_builds/releases/download/v${BITWARDEN_WEB_VERSION}/bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz
tar xf bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz
mv web-vault ${BUILD_DIR}

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

wget --progress=dot:giga ${DOWNLOAD_URL}/openssl/openssl-${ARCH}.tar.gz
tar xf openssl-${ARCH}.tar.gz
mv openssl ${BUILD_DIR}
