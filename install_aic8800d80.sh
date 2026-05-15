#!/usr/bin/env bash
# ============================================================
# AIC8800D80 Driver Auto-Installer for Linux Kernel 7.x+
# One-command, no user input needed (after sudo)
# ============================================================
# Author: SysLabDE Agent
# Version: 1.0.0
# License: MIT

set -euo pipefail

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# === Check root ===
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)."
    exit 1
fi

# === Check architecture ===
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    error "Unsupported architecture: $ARCH. Only x86_64 and aarch64 are supported."
    exit 1
fi
info "Architecture: $ARCH"

# === Check kernel version (must be 7.x+) ===
KERNEL_VERSION=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d. -f2)
if [[ "$KERNEL_MAJOR" -lt 7 || (! $KERNEL_MAJOR -eq 7 && $KERNEL_MINOR -lt 0) ]]; then
    error "Kernel $KERNEL_VERSION found. This driver requires Kernel 7.0 or newer."
    error "Upgrade your kernel first or use this script on a compatible system."
    exit 1
fi
info "Kernel $KERNEL_VERSION OK (7.x+ compatible)"

# === Check if USB device is connected ===
if ! lsusb | grep -q "368b:8d85"; then
    warn "USB device with PID 8d85 not found. Is the AIC8800D80 dongle connected?"
    warn "If so, try unplugging and replugging it."
fi

# === Install dependencies ===
info "Installing required packages..."
if command -v apt &>/dev/null; then
    # Debian/Ubuntu
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        build-essential \
        linux-headers-$(uname -r) \
        linux-headers-generic \
        dkms \
        kmod \
        bc \
        bison \
        flex \
        libssl-dev \
        git \
        wget
    success "Debian/Ubuntu dependencies installed"
elif command -v dnf &>/dev/null; then
    # Fedora/RHEL
    dnf install -y make gcc kernel-devel kernel-headers dkms kernel-modules \
        bison flex bc openssl-devel wget git
    success "Fedora/RHEL dependencies installed"
elif command -v pacman &>/dev/null; then
    # Arch Linux
    pacman -Syu --noconfirm base-devel linux-headers dkms wget git
    success "Arch Linux dependencies installed"
elif command -v zypper &>/dev/null; then
    # OpenSUSE
    zypper install -y make gcc kernel-devel kernel-headers dkms kernel-modules \
        openssl-devel wget git bison flex
    success "OpenSUSE dependencies installed"
else
    error "No supported package manager found. Install these manually first: build-essential, dkms, linux-headers"
    exit 1
fi

# === Find this script's directory ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Uninstall conflicting drivers ===
info "Removing old drivers..."
if lsmod | grep -qi "rwnx"; then
    rmmod rwnx 2>/dev/null || true
    error "rwnx module was loaded and is now force-removed. Reboot recommended."
fi
if lsmod | grep -qi "rtw89"; then
    rmmod rtw89 2>/dev/null || true
    warn "rtw89 (Realtek) driver was also removed."
fi

# === Backup any existing modules ===
if [[ -f "/lib/modules/$(uname -r)/kernel/drivers/net/wireless/rwnx.ko" ]]; then
    warn "Backing up existing rwnx module..."
    mv "/lib/modules/$(uname -r)/kernel/drivers/net/wireless/rwnx.ko" \
       "/lib/modules/$(uname -r)/kernel/drivers/net/wireless/rwnx.ko.bak.$(date +%s)"
fi

# === Build and install driver ===
info "Building patched AIC8800D80 driver..."
cd "$SCRIPT_DIR/drivers/aic8800"

# Build the module
if make -j$(nproc) 2>&1; then
    success "Driver compiled successfully"
else
    error "Driver build failed!"
    error "Check the output above for errors."
    exit 1
fi

# Install the compiled module
info "Installing driver modules..."
make install 2>&1 || {
    # Fallback: manual install
    info "Standard install failed, installing manually..."
    # Find the newly built .ko
    for ko_file in $(find /tmp -name "*.ko" -o -name "rwnx.ko" 2>/dev/null | head -1); do
        # Actually let's look in the build tree
        build_ko=$(cd /tmp; find "$SCRIPT_DIR/drivers" -name "rwnx.ko" 2>/dev/null | head -1)
        if [[ -n "$build_ko" ]]; then
            install -m 644 "$build_ko" "/lib/modules/$(uname -r)/kernel/drivers/net/wireless/"
        fi
    done
    depmod -a
}

# === Install firmware ===
info "Installing firmware files..."
FW_PATH="/lib/firmware/rtlwifi/aic8800D80"
mkdir -p "$FW_PATH"
cp -rf "$SCRIPT_DIR/fw/aic8800D80/"* "$FW_PATH/"
success "Firmware installed to $FW_PATH"

# === Load the driver ===
info "Loading driver module..."
modprobe rwnx 2>&1

# Wait for the module to load
sleep 2

# Check if the interface appeared
NEW_IFACES=$(ip link show | grep -E "wl[a-f0-9]{12}$" || true)
if [[ -n "$NEW_IFACES" ]]; then
    success "Wireless interface found: $(echo "$NEW_IFACES" | cut -d: -f2 | tr -d ' ')"
else
    warn "No wireless interface found automatically. Try:"
    warn "  1. Unplug and replug the dongle"
    warn "  2. Run: sudo modprobe rwnx"
    warn "  3. Check: sudo dmesg | grep rwnx"
fi

# === Summary ===
echo ""
echo "========================================================"
success "AIC8800D80 driver installation completed!"
echo ""
echo "Next steps:"
info "1. Check your interface:  ip link | grep wl"
info "2. Connect to Wi-Fi:      nmcli device wifi list"
info "3. Test connection:        ping github.com"
info "4. Check logs:             dmesg | grep rwnx"
echo ""
info "If the interface appears but doesn't work:"
info "   Try running this script again to reload the module."
echo "========================================================"
