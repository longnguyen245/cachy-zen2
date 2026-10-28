#!/usr/bin/env bash
# Configure the kernel for the target compiler and AMD Zen 2 CPU.
#
# - Selects MZEN2 when the CachyOS CPU-optimization patch is present, otherwise
#   falls back to GENERIC_CPU with -march=znver2.
# - Applies compiler-specific options (ThinLTO for clang, LTO_NONE for gcc,
#   disables Rust/CFI/AutoFDO/Propeller for gcc).
# - Disables debug info / BTF to save disk and build time.
# - Verifies the resulting .config matches the selected compiler and CPU.
#
# Reads (env):
#   COMPILER       - "clang" or "gcc"
#   KERNEL_SUFFIX  - LOCALVERSION string (job env)
#   MAKE_ARGS      - extra make args (job env, e.g. "LLVM=1")
#
# Writes:
#   CPU_CFLAGS=<flags> - to $GITHUB_ENV (consumed by build-kernel.sh)
#
# Args:
#   $1 - kernel source directory (required)

set -euo pipefail

kernel_dir="${1:?kernel source directory required}"
cd "${kernel_dir}"

# CPU target: MZEN2 only exists when the CPU-optimization patch is applied.
# Otherwise fall back to GENERIC_CPU + -march=znver2.
scripts/config --disable X86_NATIVE_CPU || true
if grep -q '^config MZEN2' arch/x86/Kconfig.cpu; then
  echo "MZEN2 available, using it"
  scripts/config --disable GENERIC_CPU
  scripts/config --enable MZEN2
  echo "CPU_CFLAGS=" >> "${GITHUB_ENV}"
else
  echo "MZEN2 not available, using GENERIC_CPU with -march=znver2"
  scripts/config --enable GENERIC_CPU
  echo "CPU_CFLAGS=-march=znver2" >> "${GITHUB_ENV}"
fi

if [ "${COMPILER}" = "clang" ]; then
  # ThinLTO (Full LTO is likely to OOM or time out on hosted runners)
  scripts/config --disable LTO_NONE
  scripts/config --disable LTO_CLANG_FULL
  scripts/config --enable LTO_CLANG_THIN
else
  # GCC: no Clang-only features. The CachyOS config enables ThinLTO,
  # CFI, AutoFDO, etc.; these depend on CC_IS_CLANG and are dropped
  # by olddefconfig, but turn the obvious ones off explicitly.
  scripts/config --enable LTO_NONE
  scripts/config --disable LTO_CLANG_THIN
  scripts/config --disable LTO_CLANG_FULL
  scripts/config --disable CFI_CLANG || true
  scripts/config --disable AUTOFDO_CLANG || true
  scripts/config --disable PROPELLER_CLANG || true
  # Rust support needs bindgen/libclang; skip it for the GCC variant
  scripts/config --disable RUST || true
fi

# -O3 option only exists with the CachyOS patches
if grep -rq 'CC_OPTIMIZE_FOR_PERFORMANCE_O3' init/Kconfig; then
  scripts/config --disable CC_OPTIMIZE_FOR_PERFORMANCE
  scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE_O3
else
  echo "O3 option not available, keeping default"
fi

# Disable debug info and BTF to save disk space and build time
scripts/config --enable DEBUG_INFO_NONE
scripts/config --disable DEBUG_INFO_BTF
scripts/config --disable DEBUG_INFO_BTF_MODULES

scripts/config --set-str LOCALVERSION "${KERNEL_SUFFIX}"
scripts/config --disable LOCALVERSION_AUTO

make ${MAKE_ARGS} olddefconfig

echo "===== COMPILER ====="
grep -E '^CONFIG_(CC_IS_|CC_VERSION_TEXT|GCC_VERSION|CLANG_VERSION)' .config || true

echo "===== CPU CONFIG ====="
grep -E '^CONFIG_(GENERIC_CPU|MZEN|MZEN2|MZEN3|MZEN4|MNATIVE_AMD|MNATIVE_INTEL|X86_NATIVE_CPU)=' .config || true

echo "===== SCHEDULER ====="
grep -E '^CONFIG_(SCHED_|PREEMPT|HZ_)' .config | head -100 || true

echo "===== AMD PSTATE ====="
grep -E '^CONFIG_X86_AMD_PSTATE' .config || true

echo "===== LTO / OPT ====="
grep -E '^CONFIG_(LTO|LTO_CLANG|LTO_CLANG_FULL|LTO_CLANG_THIN|CC_OPTIMIZE_FOR_PERFORMANCE)' .config || true

echo "===== VERIFY ====="
grep -q '^CONFIG_MZEN2=y' .config || grep -q '^CONFIG_GENERIC_CPU=y' .config \
  || { echo "No valid CPU target selected"; exit 1; }

if [ "${COMPILER}" = "clang" ]; then
  grep -q '^CONFIG_CC_IS_CLANG=y' .config || { echo "Kernel is not configured for clang"; exit 1; }
  grep -q '^CONFIG_LTO_CLANG_THIN=y' .config || { echo "LTO_CLANG_THIN not enabled"; exit 1; }
else
  grep -q '^CONFIG_CC_IS_GCC=y' .config || { echo "Kernel is not configured for gcc"; exit 1; }
  if grep -q '^CONFIG_LTO_CLANG' .config; then
    echo "Clang LTO unexpectedly enabled in GCC build"; exit 1
  fi
fi
