#!/usr/bin/env bash
set -euo pipefail
cd kernel

# -Wno-default-const-init-var-unsafe is only understood by clang
if [ "${COMPILER}" = "clang" ]; then
  kcflags="${CPU_CFLAGS} -Wno-default-const-init-var-unsafe"
else
  kcflags="${CPU_CFLAGS}"
fi

export KBUILD_BUILD_USER=github-actions KBUILD_BUILD_HOST=github-actions
make -j"$(nproc)" ${MAKE_ARGS} KCFLAGS="${kcflags}"