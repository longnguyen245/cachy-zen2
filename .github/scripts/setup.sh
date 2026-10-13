#!/usr/bin/env bash
# Build dependencies for the GCC toolchain.
set -euo pipefail

sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
df -h /

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bc bison build-essential cpio curl dwarves fakeroot flex gettext git kmod \
  libdw-dev libelf-dev libncurses-dev libssl-dev openssl pahole perl \
  python3 rsync tar xz-utils zstd

gcc --version
ld --version | head -n1