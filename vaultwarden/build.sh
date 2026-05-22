#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

mkdir -p ${BUILD_DIR}/bin
cp /vaultwarden ${BUILD_DIR}/bin
cp -r /web-vault ${BUILD_DIR}
