#!/usr/bin/env bash
# Install packaging dependencies inside the Arch Linux container.
# (Runs as root inside archlinux:latest.)

set -euo pipefail

pacman -Syu --noconfirm
pacman -Sy --noconfirm --needed \
  base-devel \
  zstd \
  tar
