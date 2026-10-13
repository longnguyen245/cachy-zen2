#!/usr/bin/env bash
set -euo pipefail
cd kernel

# ---- CPU target ------------------------------------------------------------
# amd:     Zen2 tuning if the CPU-optimization patchset is available, else
#          GENERIC_CPU with -march=znver2
# generic: no CPU tuning at all, runs on any x86-64 machine
scripts/config --disable X86_NATIVE_CPU || true
case "${VARIANT}" in
  amd)
    if grep -q '^config MZEN2' arch/x86/Kconfig.cpu; then
      scripts/config --disable GENERIC_CPU
      scripts/config --enable MZEN2
      echo "CPU_CFLAGS=" >> "$GITHUB_ENV"
    else
      echo "MZEN2 not available, using GENERIC_CPU with -march=znver2"
      scripts/config --enable GENERIC_CPU
      echo "CPU_CFLAGS=-march=znver2" >> "$GITHUB_ENV"
    fi
    ;;
  generic)
    scripts/config --enable GENERIC_CPU
    echo "CPU_CFLAGS=" >> "$GITHUB_ENV"
    ;;
  *)
    echo "Unknown variant: ${VARIANT}" >&2
    exit 1
    ;;
esac

# ---- optimisation ----------------------------------------------------------
# -O3 option only exists with the CachyOS patches
if grep -rq 'CC_OPTIMIZE_FOR_PERFORMANCE_O3' init/Kconfig; then
  scripts/config --disable CC_OPTIMIZE_FOR_PERFORMANCE
  scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE_O3
fi

# The upstream config is built for clang: drop everything GCC cannot use.
# GCC has no ThinLTO/Full LTO counterpart, so stay on LTO_NONE (-O2).
scripts/config --enable LTO_NONE
scripts/config --disable LTO_CLANG_THIN
scripts/config --disable LTO_CLANG_FULL
scripts/config --disable CFI_CLANG || true
scripts/config --disable AUTOFDO_CLANG || true
scripts/config --disable PROPELLER_CLANG || true
# Rust support needs bindgen/libclang, which the GCC build does not ship
scripts/config --disable RUST || true

# ---- laptop tuning (Zen2 mobile / Renoir class) ---------------------------
#  - THP "always" causes latency spikes on large anon mappings; madvise mode
#    keeps the memory savings for apps that opt in without the stutter.
#  - Automatic NUMA balancing only pays off on big multi-socket servers.
#  - EDAC (ECC reporting) and AMD HFI (Zen4+ frequency steering) are dead
#    weight on Zen2 without ECC.
scripts/config --disable TRANSPARENT_HUGEPAGE_ALWAYS
scripts/config --enable  TRANSPARENT_HUGEPAGE_MADVISE
scripts/config --disable NUMA_BALANCING
scripts/config --disable EDAC_AMD64 || true
scripts/config --disable AMD_HFI || true

# Disable debug info and BTF to save disk space and build time
scripts/config --enable DEBUG_INFO_NONE
scripts/config --disable DEBUG_INFO_BTF
scripts/config --disable DEBUG_INFO_BTF_MODULES

scripts/config --set-str LOCALVERSION "${KERNEL_SUFFIX}"
scripts/config --disable LOCALVERSION_AUTO

make olddefconfig

# ---- sanity checks ---------------------------------------------------------
grep -q '^CONFIG_CC_IS_GCC=y' .config || { echo "Kernel is not configured for gcc"; exit 1; }
grep -q '^CONFIG_LTO_NONE=y' .config || { echo "LTO should be off for a GCC build"; exit 1; }
if grep -q '^CONFIG_LTO_CLANG' .config; then
  echo "Clang LTO unexpectedly enabled in GCC build"; exit 1
fi

if [ "${VARIANT}" = "amd" ]; then
  grep -qE '^CONFIG_(MZEN2|GENERIC_CPU)=y' .config \
    || { echo "No valid CPU target selected"; exit 1; }
else
  grep -q '^CONFIG_GENERIC_CPU=y' .config \
    || { echo "generic variant must use GENERIC_CPU"; exit 1; }
fi

# ---- config report ---------------------------------------------------------
grep -E '^CONFIG_(CC_IS_|CC_VERSION_TEXT|GCC_VERSION)' .config || true
grep -E '^CONFIG_(GENERIC_CPU|MZEN|MNATIVE_|X86_NATIVE_CPU|X86_AMD_PSTATE|LTO|CC_OPTIMIZE_FOR_PERFORMANCE|TRANSPARENT_HUGEPAGE|NUMA_BALANCING|EDAC_AMD64|AMD_HFI|HZ_)' .config || true