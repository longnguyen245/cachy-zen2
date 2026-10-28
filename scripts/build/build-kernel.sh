#!/usr/bin/env bash
# Build the kernel image and modules.
#
# Adds -Wno-default-const-init-var-unsafe for clang to suppress noisy warnings
# introduced by newer Clang against the kernel sources.
#
# Reads (env):
#   COMPILER    - "clang" or "gcc"
#   CPU_CFLAGS  - extra CFLAGS for the CPU target (set by configure-kernel.sh)
#   MAKE_ARGS   - extra make args (job env)
#   KBUILD_BUILD_USER / KBUILD_BUILD_HOST - build attribution (step env)
#
# Args:
#   $1 - kernel source directory (required)

set -euo pipefail

kernel_dir="${1:?kernel source directory required}"
cd "${kernel_dir}"

if [ "${COMPILER}" = "clang" ]; then
  kcf="${CPU_CFLAGS:-} -Wno-default-const-init-var-unsafe"
else
  kcf="${CPU_CFLAGS:-}"
fi

make -j"$(nproc)" \
  ${MAKE_ARGS} \
  KCFLAGS="${kcf}"
