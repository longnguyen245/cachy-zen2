#!/usr/bin/env bash
# Install build dependencies needed to compile the kernel on Ubuntu 24.04.

set -euo pipefail

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  bc \
  bison \
  build-essential \
  cpio \
  flex \
  fakeroot \
  libelf-dev \
  libssl-dev \
  libdw-dev \
  dwarves \
  gettext \
  git \
  kmod \
  libncurses-dev \
  openssl \
  pahole \
  perl \
  python3 \
  rsync \
  tar \
  xz-utils \
  zstd \
  curl
