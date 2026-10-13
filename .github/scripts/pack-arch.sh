#!/usr/bin/env bash
set -euo pipefail

mkdir -p package artifacts
tar --zstd -xf build/kernel-root.tar.zst -C package

kver="$(cat package/kernelrelease)"
rm -f package/kernelrelease

# Arch layout: vmlinuz lives in /usr/lib/modules/<version>/
install -Dm644 "package/boot/vmlinuz-${kver}" \
  "package/usr/lib/modules/${kver}/vmlinuz"
echo "${PKG_NAME}" > "package/usr/lib/modules/${kver}/pkgbase"
rm -rf package/boot

pkgver="${kver//-/_}"
pkgver="${pkgver//+/_}"

mkdir -p archpkg/pkgroot-headers
cp -a package archpkg/pkgroot
tar --zstd -xf build/headers-root.tar.zst -C archpkg/pkgroot-headers

cat > archpkg/PKGBUILD <<EOF
pkgbase=${PKG_NAME}
pkgname=('${PKG_NAME}' '${PKG_NAME}-headers')
pkgver=${pkgver}
pkgrel=1
arch=('x86_64')
license=('GPL-2.0-only')
options=('!strip' '!debug')

package_${PKG_NAME}() {
    pkgdesc="CachyOS Linux kernel with EEVDF for ${TARGET_DESC}"
    cp -a "\${startdir}/pkgroot/." "\${pkgdir}/"
}

package_${PKG_NAME}-headers() {
    pkgdesc="Headers and scripts for building modules for the CachyOS EEVDF kernel (${TARGET_DESC})"
    depends=('${PKG_NAME}')
    cp -a "\${startdir}/pkgroot-headers/." "\${pkgdir}/"
}
EOF

useradd -m builder
chown -R builder:builder archpkg
su builder -c "cd archpkg && makepkg --skipinteg --nocheck --nodeps"

find archpkg -maxdepth 1 -type f -name '*.pkg.tar.zst' -exec cp {} artifacts/ \;
ls -lah artifacts