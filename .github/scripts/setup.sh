#!/usr/bin/env bash
# Toolchain and build dependencies for both variants.
set -euo pipefail

sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
df -h /

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bc bison build-essential cpio curl dwarves fakeroot flex gettext git kmod \
  libdw-dev libelf-dev libncurses-dev libssl-dev openssl pahole perl \
  python3 rsync tar xz-utils zstd

gcc --version
ld --version | head -n1

# ---- clang variant: LLVM + Rust (kernel Rust support) + bindgen -----------
[ "${COMPILER}" = "clang" ] || exit 0

curl -fSL \
  "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz" \
  -o /tmp/llvm.tar.xz
sudo mkdir -p "${LLVM_DIR}"
sudo chown "$(id -u):$(id -g)" "${LLVM_DIR}"
tar -xJf /tmp/llvm.tar.xz --strip-components=1 -C "${LLVM_DIR}"
rm -f /tmp/llvm.tar.xz
echo "${LLVM_DIR}/bin" >> "$GITHUB_PATH"
echo "LD_LIBRARY_PATH=${LLVM_DIR}/lib" >> "$GITHUB_ENV"
echo "LIBCLANG_PATH=${LLVM_DIR}/lib" >> "$GITHUB_ENV"
export PATH="${LLVM_DIR}/bin:${PATH}" LD_LIBRARY_PATH="${LLVM_DIR}/lib"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
echo "$HOME/.cargo/bin" >> "$GITHUB_PATH"
export PATH="$HOME/.cargo/bin:${PATH}"
rustup component add rust-src
cargo install bindgen-cli

clang --version
ld.lld --version
rustc --version
bindgen --version