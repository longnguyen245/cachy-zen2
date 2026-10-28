#!/usr/bin/env bash
# Install bindgen-cli, needed for Rust kernel support with Clang.

set -euo pipefail

cargo install bindgen-cli
bindgen --version
