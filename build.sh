#!/bin/sh

mkdir -p build/bin

# upstream binary
#cp /bitwarden_rs build/bin

# custom build
cd ${DIR}/build/bitwarden_rs

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=UTC TERM=xterm-256color
ENV USER "root"
ENV RUSTFLAGS='-C link-arg=-s'

rustup set profile minimal
rustup target add x86_64-unknown-linux-musl
cargo build --features sqlite --release --target=x86_64-unknown-linux-musl
ldd target/release/bitwarden_rs
cp ${DIR}/build/bitwarden_rs/target/release/bitwarden_rs ${DIR}/build/bin

mkdir ${DIR}/build/lib
cp /usr/lib/*/libssl.so* ${DIR}/build/lib
cp /usr/lib/*/libcrypto.so* ${DIR}/build/lib
cp /lib/*/libgcc_s.so* ${DIR}/build/lib
cp /lib/*/librt.so* ${DIR}/build/lib
cp /lib/*/libpthread.so* ${DIR}/build/lib
cp /lib/*/libm.so* ${DIR}/build/lib
cp /lib/*/libdl.so* ${DIR}/build/lib
cp /lib/*/libc.so* ${DIR}/build/lib
cp $(readlink -f /lib*/ld-linux-*.so*) ${DIR}/build/lib/ld.so
