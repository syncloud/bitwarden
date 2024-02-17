#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download
ARCH=$(uname -m)
BUILD_DIR=${DIR}/build/snap

apt update
apt -y install wget unzip

mkdir -p $BUILD_DIR
cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

wget --progress=dot:giga ${DOWNLOAD_URL}/openssl/openssl-${ARCH}.tar.gz
tar xf openssl-${ARCH}.tar.gz
mv openssl ${BUILD_DIR}
