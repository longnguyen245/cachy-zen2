#!/usr/bin/env bash
# Assemble a kernel headers tree sufficient for building out-of-tree modules,
# then create headers-root.tar.zst for the packaging jobs.
#
# Reads (env):
#   MAKE_ARGS - extra make args (job env)
#
# Args:
#   $1 - kernel source directory (required)
#
# Output:
#   <kernel_dir>/headers-root.tar.zst

set -euo pipefail

kernel_dir="${1:?kernel source directory required}"
cd "${kernel_dir}"

KVER="$(make -s ${MAKE_ARGS} kernelrelease)"
hdr="$PWD/hdrroot"
builddir="${hdr}/usr/lib/modules/${KVER}/build"

install -Dt "${builddir}" -m644 .config Makefile Module.symvers System.map
install -Dt "${builddir}/kernel" -m644 kernel/Makefile
install -Dt "${builddir}/arch/x86" -m644 arch/x86/Makefile

cp -t "${builddir}" -a scripts
cp -t "${builddir}" -a include
cp -t "${builddir}/arch/x86" -a arch/x86/include

if [ -f arch/x86/kernel/asm-offsets.s ]; then
  install -Dt "${builddir}/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s
fi

# Needed to build external modules when objtool / BTF are enabled
if [ -f tools/objtool/objtool ]; then
  install -Dt "${builddir}/tools/objtool" tools/objtool/objtool
fi
if [ -f tools/bpf/resolve_btfids/resolve_btfids ]; then
  install -Dt "${builddir}/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/resolve_btfids
fi

# Private headers that some out-of-tree modules include
for f in \
  drivers/md/*.h \
  net/mac80211/*.h \
  drivers/media/i2c/msp3400-driver.h \
  drivers/media/usb/dvb-usb/*.h \
  drivers/media/dvb-frontends/*.h \
  drivers/media/tuners/*.h \
  drivers/iio/common/hid-sensors/*.h
do
  if [ -f "$f" ]; then
    install -Dm644 "$f" "${builddir}/${f}"
  fi
done

# Kconfig files
find . -path ./hdrroot -prune -o -name 'Kconfig*' -type f -print0 \
  | while IFS= read -r -d '' f; do
      install -Dm644 "$f" "${builddir}/${f}"
    done

# Keep only x86
for d in "${builddir}"/arch/*/; do
  case "$d" in
    */x86/) ;;
    *) rm -rf "$d" ;;
  esac
done

# Cleanup
find -L "${builddir}" -type l -delete
find "${builddir}" -type f -name '*.o' -delete

mkdir -p "${hdr}/usr/src"
ln -sr "${builddir}" "${hdr}/usr/src/linux-headers-${KVER}"

tar --zstd -cf headers-root.tar.zst -C "${hdr}" .

ls -lh headers-root.tar.zst
du -sh "${hdr}"
