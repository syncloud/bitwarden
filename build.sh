#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# upstream binary
#mkdir -p build/bin
#cp /bitwarden_rs build/bin

# custom build
cd ${DIR}/build/bitwarden_rs

export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=UTC TERM=xterm-256color
export USER=root
export RUSTFLAGS='-C link-arg=-s'

rustup set profile minimal
rustup target add x86_64-unknown-linux-musl
cargo build --features sqlite --release --target=x86_64-unknown-linux-musl
#ldd target/x86_64-unknown-linux-musl/release/bitwarden_rs
cp ${DIR}/build/bitwarden_rs/target/x86_64-unknown-linux-musl/release/bitwarden_rs ${DIR}/build/bin

#mkdir ${DIR}/build/lib
#cp /usr/lib/*/libssl.so* ${DIR}/build/lib
#cp /usr/lib/*/libcrypto.so* ${DIR}/build/lib
#cp /lib/*/libgcc_s.so* ${DIR}/build/lib
#cp /lib/*/librt.so* ${DIR}/build/lib
#cp /lib/*/libpthread.so* ${DIR}/build/lib
#cp /lib/*/libm.so* ${DIR}/build/lib
#cp /lib/*/libdl.so* ${DIR}/build/lib
#cp /lib/*/libc.so* ${DIR}/build/lib
#cp $(readlink -f /lib*/ld-linux-*.so*) ${DIR}/build/lib/ld.so
