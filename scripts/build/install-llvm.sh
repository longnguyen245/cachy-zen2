#!/usr/bin/env bash
# Download and install a pinned LLVM/Clang toolchain used for the clang variant.
#
# Reads (env):
#   LLVM_VERSION - the release version to fetch (workflow env)
#   LLVM_DIR     - install location (workflow env)
#
# Writes:
#   PATH, LD_LIBRARY_PATH, LIBCLANG_PATH - to $GITHUB_ENV / $GITHUB_PATH

set -euo pipefail

curl -fL \
  "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz" \
  -o /tmp/llvm.tar.xz

sudo mkdir -p "${LLVM_DIR}"
sudo chown "$(id -u):$(id -g)" "${LLVM_DIR}"

tar -xJf /tmp/llvm.tar.xz --strip-components=1 -C "${LLVM_DIR}"

echo "${LLVM_DIR}/bin" >> "${GITHUB_PATH}"
echo "LD_LIBRARY_PATH=${LLVM_DIR}/lib" >> "${GITHUB_ENV}"
echo "LIBCLANG_PATH=${LLVM_DIR}/lib" >> "${GITHUB_ENV}"

export PATH="${LLVM_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${LLVM_DIR}/lib"

clang --version
ld.lld --version
