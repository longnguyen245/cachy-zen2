#!/usr/bin/env bash
# Resolve the CachyOS/linux ref to build and clone it with the EEVDF config.
set -euo pipefail

# A tag pushed to this repo must have the same name as the tag in
# CachyOS/linux (e.g. cachyos-7.1.8-1) and builds exactly that tag.
if [ "${GITHUB_REF_TYPE}" = "tag" ]; then
  ref="${GITHUB_REF_NAME}"
elif [ -n "${INPUT_REF:-}" ]; then
  ref="${INPUT_REF}"
else
  ref="${KERNEL_REF_DEFAULT}"
fi

if ! printf '%s' "${ref}" | grep -Eq '^[A-Za-z0-9._/-]+$'; then
  echo "Invalid kernel ref: ${ref}" >&2
  exit 1
fi

echo "Building CachyOS/linux ref: ${ref} (${VARIANT})"

git clone --depth=1 --branch="${ref}" "${KERNEL_REPO}" kernel
git -C kernel log -1 --oneline
curl -fSL "${CONFIG_URL}" -o kernel/.config