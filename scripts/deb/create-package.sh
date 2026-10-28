#!/usr/bin/env bash
# Build Debian packages (kernel + headers) from the downloaded build
# artifacts, generating DEBIAN control and maintainer scripts.
#
# Reads (env):
#   COMPILER  - "clang" or "gcc" (used in Description)
#   PKG_NAME  - package base name (job env)
#
# Args:
#   $1 - build directory containing kernel-root.tar.zst and headers-root.tar.zst
#
# Output:
#   artifacts/*.deb
#
# NOTE: ${KVER}, ${PKG_NAME}, ${COMPILER} expand here at generation time when
# writing the DEBIAN/control and maintainer scripts (unquoted heredocs).

set -euo pipefail

build_dir="${1:?build directory required}"

# ----------------------------------------------------------------- Kernel .deb
mkdir -p package
tar --zstd -xf "${build_dir}/kernel-root.tar.zst" -C package

KVER="$(cat package/kernelrelease)"
rm -f package/kernelrelease

mkdir -p package/DEBIAN

cat > package/DEBIAN/control <<EOF
Package: ${PKG_NAME}
Version: ${KVER}
Section: kernel
Priority: optional
Architecture: amd64
Maintainer: GitHub Actions <noreply@github.com>
Description: CachyOS Linux kernel with EEVDF for AMD Zen 2 (${COMPILER})
EOF

cat > package/DEBIAN/postinst <<EOF
#!/bin/sh
set -e

depmod "${KVER}" || true

if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -c -k "${KVER}" || true
fi

if command -v update-grub >/dev/null 2>&1; then
    update-grub || true
fi

exit 0
EOF

cat > package/DEBIAN/prerm <<EOF
#!/bin/sh
exit 0
EOF

cat > package/DEBIAN/postrm <<EOF
#!/bin/sh
set -e

rm -f "/boot/initrd.img-${KVER}" || true
depmod -a || true

if command -v update-grub >/dev/null 2>&1; then
    update-grub || true
fi

exit 0
EOF

chmod 0755 \
  package/DEBIAN/postinst \
  package/DEBIAN/prerm \
  package/DEBIAN/postrm

mkdir -p artifacts

dpkg-deb \
  --build \
  --root-owner-group \
  package \
  "artifacts/${PKG_NAME}_${KVER}_amd64.deb"

dpkg-deb --info \
  "artifacts/${PKG_NAME}_${KVER}_amd64.deb"

# --------------------------------------------------------------- Headers .deb
mkdir -p package-headers
tar --zstd -xf "${build_dir}/headers-root.tar.zst" -C package-headers
mkdir -p package-headers/DEBIAN

cat > package-headers/DEBIAN/control <<EOF
Package: ${PKG_NAME}-headers
Version: ${KVER}
Section: kernel
Priority: optional
Architecture: amd64
Depends: ${PKG_NAME}
Maintainer: GitHub Actions <noreply@github.com>
Description: Headers and scripts for CachyOS Zen 2 EEVDF kernel (${COMPILER})
EOF

dpkg-deb \
  --build \
  --root-owner-group \
  package-headers \
  "artifacts/${PKG_NAME}-headers_${KVER}_amd64.deb"

dpkg-deb --info \
  "artifacts/${PKG_NAME}-headers_${KVER}_amd64.deb"

ls -lah artifacts
