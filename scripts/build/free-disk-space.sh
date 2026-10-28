#!/usr/bin/env bash
# Free disk space on the GitHub-hosted runner by removing large, unneeded
# toolchains that the kernel build does not use.

set -euo pipefail

sudo rm -rf \
  /usr/share/dotnet \
  /usr/local/lib/android \
  /opt/ghc \
  /opt/hostedtoolcache/CodeQL

df -h /
