#!/usr/bin/env bash
# Resolve which CachyOS/linux ref (branch/tag) to build.
#
# Precedence:
#   1. A git tag pushed to this repo (must match a tag in CachyOS/linux).
#   2. The kernel_ref workflow_dispatch input.
#   3. KERNEL_REF_DEFAULT (workflow env).
#
# Reads (env):
#   GITHUB_REF_TYPE     - "tag" or "branch" (set by Actions)
#   GITHUB_REF_NAME     - the ref name (set by Actions)
#   INPUT_REF           - kernel_ref input
#   KERNEL_REF_DEFAULT  - default ref (workflow env)
#   COMPILER            - for logging
#
# Writes:
#   KERNEL_REF=<ref>    - to $GITHUB_ENV

set -euo pipefail

if [ "${GITHUB_REF_TYPE}" = "tag" ]; then
  ref="${GITHUB_REF_NAME}"
elif [ -n "${INPUT_REF:-}" ]; then
  ref="${INPUT_REF}"
else
  ref="${KERNEL_REF_DEFAULT}"
fi

if ! printf '%s' "${ref}" | grep -Eq '^[A-Za-z0-9._/-]+$'; then
  echo "Invalid kernel ref: ${ref}"
  exit 1
fi

echo "Building CachyOS/linux ref: ${ref} with ${COMPILER}"
echo "KERNEL_REF=${ref}" >> "${GITHUB_ENV}"
