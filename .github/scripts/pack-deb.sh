#!/usr/bin/env bash
set -euo pipefail

mkdir -p package package-headers artifacts
tar --zstd -xf build/kernel-root.tar.zst -C package
kver="$(cat package/kernelrelease)"
rm -f package/kernelrelease

mkdir -p package/DEBIAN
cat > package/DEBIAN/control <<EOF
Package: ${PKG_NAME}
Version: ${kver}
Section: kernel
Priority: optional
Architecture: amd64
Maintainer: GitHub Actions <noreply@github.com>
Description: CachyOS Linux kernel with EEVDF for AMD Zen 2 (${COMPILER})
EOF

cat > package/DEBIAN/postinst <<EOF
#!/bin/sh
set -e
depmod "${kver}" || true
command -v update-initramfs >/dev/null 2>&1 && update-initramfs -c -k "${kver}" || true
command -v update-grub >/dev/null 2>&1 && update-grub || true
exit 0
EOF

cat > package/DEBIAN/prerm <<'EOF'
#!/bin/sh
exit 0
EOF

cat > package/DEBIAN/postrm <<EOF
#!/bin/sh
set -e
rm -f "/boot/initrd.img-${kver}" || true
depmod -a || true
command -v update-grub >/dev/null 2>&1 && update-grub || true
exit 0
EOF

chmod 0755 package/DEBIAN/{postinst,prerm,postrm}
dpkg-deb --build --root-owner-group package \
  "artifacts/${PKG_NAME}_${kver}_amd64.deb"

# Headers package
tar --zstd -xf build/headers-root.tar.zst -C package-headers
mkdir -p package-headers/DEBIAN
cat > package-headers/DEBIAN/control <<EOF
Package: ${PKG_NAME}-headers
Version: ${kver}
Section: kernel
Priority: optional
Architecture: amd64
Depends: ${PKG_NAME}
Maintainer: GitHub Actions <noreply@github.com>
Description: Headers and scripts for CachyOS Zen 2 EEVDF kernel (${COMPILER})
EOF

dpkg-deb --build --root-owner-group package-headers \
  "artifacts/${PKG_NAME}-headers_${kver}_amd64.deb"

for d in artifacts/*.deb; do dpkg-deb --info "$d"; done
ls -lah artifacts