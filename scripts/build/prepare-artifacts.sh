#!/usr/bin/env bash
# Install the built kernel image, modules and boot files into a pkgroot, then
# create kernel-root.tar.zst for the packaging jobs.
#
# Reads (env):
#   MAKE_ARGS - extra make args (job env)
#
# Args:
#   $1 - kernel source directory (required)
#
# Output:
#   <kernel_dir>/kernel-root.tar.zst

set -euo pipefail

kernel_dir="${1:?kernel source directory required}"
cd "${kernel_dir}"

KVER="$(make -s ${MAKE_ARGS} kernelrelease)"
echo "Kernel release: ${KVER}"

mkdir -p pkgroot/boot

cp arch/x86/boot/bzImage "pkgroot/boot/vmlinuz-${KVER}"
cp System.map            "pkgroot/boot/System.map-${KVER}"
cp .config               "pkgroot/boot/config-${KVER}"

# Install modules under /usr/lib/modules (Arch and merged-usr Debian/Ubuntu)
make ${MAKE_ARGS} \
  INSTALL_MOD_PATH="$PWD/pkgroot/usr" \
  INSTALL_MOD_STRIP=1 \
  modules_install

rm -f \
  "pkgroot/usr/lib/modules/${KVER}/build" \
  "pkgroot/usr/lib/modules/${KVER}/source"

depmod -b "$PWD/pkgroot/usr" "${KVER}"

echo "${KVER}" > pkgroot/kernelrelease

tar --zstd -cf kernel-root.tar.zst -C pkgroot .

ls -lh kernel-root.tar.zst
du -sh pkgroot
