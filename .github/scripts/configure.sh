#!/usr/bin/env bash
set -euo pipefail
cd kernel

# CPU target: MZEN2 only exists when the CPU-optimization patch is applied.
# Otherwise fall back to GENERIC_CPU + -march=znver2.
scripts/config --disable X86_NATIVE_CPU || true
if grep -q '^config MZEN2' arch/x86/Kconfig.cpu; then
  scripts/config --disable GENERIC_CPU
  scripts/config --enable MZEN2
  echo "CPU_CFLAGS=" >> "$GITHUB_ENV"
else
  scripts/config --enable GENERIC_CPU
  echo "CPU_CFLAGS=-march=znver2" >> "$GITHUB_ENV"
fi

# -O3 option only exists with the CachyOS patches. LTO is only worth its
# icache/codegen overhead when we actually optimise above -O2.
o3=no
if grep -rq 'CC_OPTIMIZE_FOR_PERFORMANCE_O3' init/Kconfig; then
  scripts/config --disable CC_OPTIMIZE_FOR_PERFORMANCE
  scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE_O3
  o3=yes
else
  echo "O3 option not available, keeping default optimisation level"
fi

if [ "${COMPILER}" = "clang" ]; then
  if [ "${o3}" = yes ]; then
    # ThinLTO (Full LTO is likely to OOM or time out on hosted runners)
    scripts/config --disable LTO_NONE
    scripts/config --disable LTO_CLANG_FULL
    scripts/config --enable LTO_CLANG_THIN
  else
    scripts/config --enable LTO_NONE
    scripts/config --disable LTO_CLANG_THIN
    scripts/config --disable LTO_CLANG_FULL
  fi
else
  # GCC: no Clang-only features. The CachyOS config enables ThinLTO, CFI,
  # AutoFDO, etc.; these depend on CC_IS_CLANG and are dropped by olddefconfig,
  # but turn the obvious ones off explicitly.
  scripts/config --enable LTO_NONE
  scripts/config --disable LTO_CLANG_THIN
  scripts/config --disable LTO_CLANG_FULL
  scripts/config --disable CFI_CLANG || true
  scripts/config --disable AUTOFDO_CLANG || true
  scripts/config --disable PROPELLER_CLANG || true
  # Rust support needs bindgen/libclang; skip it for the GCC variant
  scripts/config --disable RUST || true
fi

# Disable debug info and BTF to save disk space and build time
scripts/config --enable DEBUG_INFO_NONE
scripts/config --disable DEBUG_INFO_BTF
scripts/config --disable DEBUG_INFO_BTF_MODULES

scripts/config --set-str LOCALVERSION "${KERNEL_SUFFIX}"
scripts/config --disable LOCALVERSION_AUTO

make ${MAKE_ARGS} olddefconfig

# ---- sanity checks ---------------------------------------------------------
grep -qE '^CONFIG_(MZEN2|GENERIC_CPU)=y' .config \
  || { echo "No valid CPU target selected"; exit 1; }

if [ "${COMPILER}" = "clang" ]; then
  grep -q '^CONFIG_CC_IS_CLANG=y' .config || { echo "Kernel is not configured for clang"; exit 1; }
  if [ "${o3}" = yes ]; then
    grep -q '^CONFIG_LTO_CLANG_THIN=y' .config || { echo "LTO_CLANG_THIN not enabled"; exit 1; }
  else
    grep -q '^CONFIG_LTO_NONE=y' .config || { echo "LTO should be off without -O3"; exit 1; }
  fi
else
  grep -q '^CONFIG_CC_IS_GCC=y' .config || { echo "Kernel is not configured for gcc"; exit 1; }
  if grep -q '^CONFIG_LTO_CLANG' .config; then
    echo "Clang LTO unexpectedly enabled in GCC build"; exit 1
  fi
fi

# ---- config report ---------------------------------------------------------
grep -E '^CONFIG_(CC_IS_|CC_VERSION_TEXT|GCC_VERSION|CLANG_VERSION)' .config || true
grep -E '^CONFIG_(GENERIC_CPU|MZEN|MNATIVE_|X86_NATIVE_CPU|X86_AMD_PSTATE|LTO|CC_OPTIMIZE_FOR_PERFORMANCE)' .config || true