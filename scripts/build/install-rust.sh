#!/usr/bin/env bash
# Install the Rust toolchain via rustup (minimal profile + rust-src).
# Required for the clang/Rust kernel build variant.

set -euo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
  | sh -s -- -y --profile minimal

echo "$HOME/.cargo/bin" >> "${GITHUB_PATH}"
export PATH="$HOME/.cargo/bin:${PATH}"

rustup component add rust-src

rustc --version
cargo --version
