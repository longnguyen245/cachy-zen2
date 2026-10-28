#!/usr/bin/env bash
# Download the CachyOS EEVDF kernel config into the kernel tree as .config.
#
# Reads (env):
#   CONFIG_URL - URL of the upstream config (workflow env)
#
# Args:
#   $1 - kernel source directory (required)

set -euo pipefail

kernel_dir="${1:?kernel source directory required}"

curl -fL "${CONFIG_URL}" -o "${kernel_dir}/.config"
