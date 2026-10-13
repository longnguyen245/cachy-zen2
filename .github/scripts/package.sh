#!/usr/bin/env bash
# Turn the built tree into kernel-root.tar.zst and headers-root.tar.zst.
set -euo pipefail
cd kernel

kver="$(make -s kernelrelease)"
echo "Kernel release: ${kver}"

# ---- /boot + modules -------------------------------------------------------
root="$PWD/pkgroot"
mkdir -p "${root}/boot"
cp arch/x86/boot/bzImage "${root}/boot/vmlinuz-${kver}"
cp System.map          "${root}/boot/System.map-${kver}"
cp .config             "${root}/boot/config-${kver}"

# Install modules under /usr/lib/modules (Arch and merged-usr Debian/Ubuntu)
make INSTALL_MOD_PATH="${root}/usr" INSTALL_MOD_STRIP=1 modules_install
rm -f "${root}/usr/lib/modules/${kver}/build" \
      "${root}/usr/lib/modules/${kver}/source"
depmod -b "${root}/usr" "${kver}"

echo "${kver}" > "${root}/kernelrelease"
tar --zstd -cf kernel-root.tar.zst -C "${root}" .
rm -rf "${root}"

# ---- headers ---------------------------------------------------------------
hdr="$PWD/hdrroot"
builddir="${hdr}/usr/lib/modules/${kver}/build"

install -Dt "${builddir}" -m644 .config Makefile Module.symvers System.map
install -Dt "${builddir}/kernel" -m644 kernel/Makefile
install -Dt "${builddir}/arch/x86" -m644 arch/x86/Makefile
cp -t "${builddir}" -a scripts include
cp -t "${builddir}/arch/x86" -a arch/x86/include

# Needed to build external modules when objtool / BTF are enabled
for f in arch/x86/kernel/asm-offsets.s tools/objtool/objtool tools/bpf/resolve_btfids/resolve_btfids; do
  if [ -f "$f" ]; then install -Dt "${builddir}/$f" "$f"; fi
done

# Private headers that some out-of-tree modules include
for pat in drivers/md/*.h net/mac80211/*.h drivers/media/i2c/msp3400-driver.h \
           drivers/media/usb/dvb-usb/*.h drivers/media/dvb-frontends/*.h \
           drivers/media/tuners/*.h drivers/iio/common/hid-sensors/*.h; do
  for f in $pat; do
    if [ -f "$f" ]; then install -Dm644 "$f" "${builddir}/${f}"; fi
  done
done

# Kconfig files
find . -path ./hdrroot -prune -o -name 'Kconfig*' -type f -print0 \
  | while IFS= read -r -d '' f; do
      install -Dm644 "$f" "${builddir}/${f}"
    done

# Keep only x86, then drop symlinks and object files
for d in "${builddir}"/arch/*/; do
  [ "$d" = "${builddir}/arch/x86/" ] || rm -rf "$d"
done
find -L "${builddir}" -type l -delete
find "${builddir}" -type f -name '*.o' -delete

mkdir -p "${hdr}/usr/src"
ln -sr "${builddir}" "${hdr}/usr/src/linux-headers-${kver}"
tar --zstd -cf headers-root.tar.zst -C "${hdr}" .
rm -rf "${hdr}"

ls -lh kernel-root.tar.zst headers-root.tar.zst