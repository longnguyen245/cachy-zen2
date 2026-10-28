#!/usr/bin/env bash
# Shallow-clone the CachyOS/linux kernel at the resolved ref.
#
# Reads (env):
#   KERNEL_REF  - ref to check out (set by resolve-ref.sh)
#   KERNEL_REPO - upstream URL (workflow env)
#
# Args:
#   $1 - destination directory (default: kernel)

set -euo pipefail

dest="${1:-kernel}"

git clone \
  --depth=1 \
  --branch="${KERNEL_REF}" \
  "${KERNEL_REPO}" \
  "${dest}"

git -C "${dest}" log -1 --oneline
