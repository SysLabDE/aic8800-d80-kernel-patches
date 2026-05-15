# AIC8800D80 Kernel 7.x Driver Patches

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux Kernel 7.x](https://img.shields.io/badge/Kernel-7.0%2B-green)](https://www.kernel.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04%20%7C%2026.04-blue?logo=ubuntu)]
[![Contributions Welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen)](https://github.com/SysLabDE/aic8800-d80-kernel-patches/blob/main/CONTRIBUTING.md)

Backports and kernel-level fixes for the [Aetheric AIC8800D80](https://www.aetheric.com/) USB Wi-Fi adapter on Linux Kernel 7.x and newer.

## Overview

This repository tracks critical driver patches required to stabilize the `rwnx_main` and related kernel modules for the AIC8800D80 chip across modern Linux kernels. It focuses on bridging the gap between Realtek's original driver code and the breaking API changes introduced in Linux Kernel 7.0+.

## Key Features

- **Kernel 7.x Compatibility**: Corrected `cfg80211_ops` function signatures and fixed context transitions (`in_irq` -> `in_serving_softirq`).
- **Firmware Path Fixes**: Updated firmware loading paths and integration for modern distributions.
- **Build Support**: Includes DKMS support, manual compilation scripts, and dependency checkers.
- **Testing**: Verified on Kernel 7.0.0-15-generic and modern Ubuntu LTS releases.

## Hardware Details

- **Vendor ID**: `368b` (Aetheric)
- **Product ID**: `8d85`
- **Interface**: Wireless LAN (`wlx...`)
- **Driver Module**: `rwnx` (Wireless LAN Controller)

## Quick Install

### 1. Clone the repository
```bash
git clone https://github.com/SysLabDE/aic8800-d80-kernel-patches.git
cd aic8800-d80-kernel-patches
```

### 2. Apply patches to your kernel source
(See `patches/` directory for detailed instructions)

### 3. Reboot and verify interface

## Repository Structure

- `patches/` — Targeted driver patches (`rwnx_main.c`, etc.) for specific kernel versions.
- `firmware/` — Required AIC8800D80 firmware files (`aic8800D80.bx.bin`, etc.).
- `scripts/` — Utility scripts for DKMS installation and kernel compilation.
- `docs/` — Detailed installation guides, API diffs, and testing results.

## Troubleshooting

Check the detailed guide in `docs/troubleshooting.md`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit patches.
