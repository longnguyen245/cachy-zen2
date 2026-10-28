#!/usr/bin/env bash
# Decide whether this build variant should run, based on the workflow input.
#
# Reads (env):
#   COMPILER        - the variant this job builds ("clang" or "gcc")
#   INPUT_COMPILER  - the value chosen on workflow_dispatch ("both"|"clang"|"gcc")
#
# Writes:
#   run=true|false  - to $GITHUB_OUTPUT, consumed by later steps via
#                     `if: steps.select.outputs.run == 'true'`

set -euo pipefail

want="${INPUT_COMPILER:-both}"

if [ "$want" != "both" ] && [ "$want" != "$COMPILER" ]; then
  echo "Variant ${COMPILER} not selected (wanted: ${want})"
  echo "run=false" >> "${GITHUB_OUTPUT}"
else
  echo "run=true" >> "${GITHUB_OUTPUT}"
fi
