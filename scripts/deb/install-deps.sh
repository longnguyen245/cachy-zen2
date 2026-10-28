#!/usr/bin/env bash
# Install packaging dependencies for creating Debian packages on Ubuntu.

set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  dpkg-dev \
  zstd \
  tar
