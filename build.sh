#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

which openssl
mkdir ${DIR}/build/bin
cp $(which openssl) ${DIR}/build/bin

cd ${DIR}/build/bitwarden_rs
rustup set profile minimal
cargo build --features sqlite --release
ldd target/release/bitwarden_rs
mkdir ${DIR}/build/lib
cp ${DIR}/build/bitwarden_rs/target/release/bitwarden_rs ${DIR}/build/bin

cd ${DIR}/build/lib
cp /usr/lib/*/libssl.so* ${DIR}/build/lib
cp /usr/lib/*/libcrypto.so* ${DIR}/build/lib
cp /lib/*/libgcc_s.so* ${DIR}/build/lib
cp /lib/*/librt.so* ${DIR}/build/lib
cp /lib/*/libpthread.so* ${DIR}/build/lib
cp /lib/*/libm.so* ${DIR}/build/lib
cp /lib/*/libdl.so* ${DIR}/build/lib
cp /lib/*/libc.so* ${DIR}/build/lib
cp $(readlink -f /lib*/ld-linux-*.so*) ./ld.so