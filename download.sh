#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BITWARDEN_WEB_VERSION=2.18.2
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download/1
ARCH=$(uname -m)
rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build
mkdir -p ${BUILD_DIR}

cd $BUILD_DIR

wget --progress=dot:giga https://github.com/dani-garcia/bw_web_builds/releases/download/v${BITWARDEN_WEB_VERSION}/bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz
tar xf bw_web_v${BITWARDEN_WEB_VERSION}.tar.gz

wget --progress=dot:giga ${DOWNLOAD_URL}/python-${ARCH}.tar.gz
tar xf python-${ARCH}.tar.gz
./python/bin/pip install -r ${DIR}/requirements.txt

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz

wget -c --progress=dot:giga ${DOWNLOAD_URL}/openssl-${ARCH}.tar.gz
tar xf openssl-${ARCH}.tar.gz
