#!/usr/bin/env bash
# Build Arch Linux packages (kernel + headers) from the downloaded build
# artifacts, generating a PKGBUILD and running makepkg.
#
# Reads (env):
#   COMPILER  - "clang" or "gcc" (used in pkgdesc)
#   PKG_NAME  - package base name (job env)
#
# Args:
#   $1 - build directory containing kernel-root.tar.zst and headers-root.tar.zst
#
# Output:
#   artifacts/*.pkg.tar.zst

set -euo pipefail

build_dir="${1:?build directory required}"

mkdir -p package
tar --zstd -xf "${build_dir}/kernel-root.tar.zst" -C package

KVER="$(cat package/kernelrelease)"
rm -f package/kernelrelease

# Arch layout: vmlinuz lives in /usr/lib/modules/<version>/
install -Dm644 "package/boot/vmlinuz-${KVER}" \
  "package/usr/lib/modules/${KVER}/vmlinuz"
echo "${PKG_NAME}" > "package/usr/lib/modules/${KVER}/pkgbase"
rm -rf package/boot

PKGVER="${KVER//-/_}"
PKGVER="${PKGVER//+/_}"

mkdir -p archpkg/pkgroot-headers
cp -a package archpkg/pkgroot
tar --zstd -xf "${build_dir}/headers-root.tar.zst" -C archpkg/pkgroot-headers

# NOTE: ${PKG_NAME}, ${PKGVER}, ${COMPILER} expand here at generation time.
# \${startdir} and \${pkgdir} stay literal and are expanded by makepkg later.
cat > archpkg/PKGBUILD <<EOF
pkgbase=${PKG_NAME}
pkgname=('${PKG_NAME}' '${PKG_NAME}-headers')
pkgver=${PKGVER}
pkgrel=1
arch=('x86_64')
license=('GPL-2.0-only')
options=('!strip' '!debug')

package_${PKG_NAME}() {
    pkgdesc="CachyOS Linux kernel with EEVDF for AMD Zen 2 (${COMPILER})"
    cp -a "\${startdir}/pkgroot/." "\${pkgdir}/"
}

package_${PKG_NAME}-headers() {
    pkgdesc="Headers and scripts for building modules for the CachyOS Zen 2 EEVDF kernel (${COMPILER})"
    depends=('${PKG_NAME}')
    cp -a "\${startdir}/pkgroot-headers/." "\${pkgdir}/"
}
EOF

useradd -m builder
chown -R builder:builder archpkg

su builder -c "cd archpkg && makepkg --skipinteg --nocheck --nodeps"

mkdir -p artifacts
find archpkg -maxdepth 1 -type f -name '*.pkg.tar.zst' -exec cp {} artifacts/ \;

ls -lah artifacts
