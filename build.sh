#!/bin/sh -e

SCRIPT=$(readlink -f "$0")
DIR=$(dirname "$SCRIPT")

BUILD_DIR=$DIR/build/snap
mkdir -p $BUILD_DIR

# upstream binary
mkdir -p $BUILD_DIR/bin
cp /vaultwarden $BUILD_DIR/bin
cp -r /web-vault $BUILD_DIR
# custom build
#cd ${DIR}/build/bitwarden_rs
#export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=UTC TERM=xterm-256color
#export USER=root
#export RUSTFLAGS='-C link-arg=-s'
#rustup set profile minimal
#rustup target add x86_64-unknown-linux-musl
#cargo build --features sqlite --release --target=x86_64-unknown-linux-musl
#cp ${DIR}/build/bitwarden_rs/target/x86_64-unknown-linux-musl/release/bitwarden_rs ${DIR}/build/bin