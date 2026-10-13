#!/usr/bin/env bash
set -euo pipefail
cd kernel

export KBUILD_BUILD_USER=github-actions KBUILD_BUILD_HOST=github-actions
make -j"$(nproc)" KCFLAGS="${CPU_CFLAGS}"