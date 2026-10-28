#!/usr/bin/env bash
# Install packaging dependencies inside the Arch Linux container.
# (Runs as root inside archlinux:latest.)

set -euo pipefail

pacman -Syu --noconfirm --needed \
  base-devel \
  git \
  zstd \
  tar
