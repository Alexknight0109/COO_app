#!/bin/bash
# =============================================================================
# AHU Dashboard Pi Zero 2W – Deployment Script
# =============================================================================
# Builds a Linux ARM64 release bundle on this (development) machine and
# rsyncs it to the Pi Zero 2W.
#
# Usage:
#   PI_IP=192.168.1.101 PI_USER=almed ./deploy.sh
#
# Prerequisites on the Pi Zero 2W:
#   - SSH enabled
#   - Flutter Linux runtime libs present  (see README_PIZERO.md)
#   - Kiosk setup done with setup_kiosk.sh
# =============================================================================

set -e

echo "============================================"
echo "  AHU Dashboard – Pi Zero 2W Deploy Script"
echo "============================================"
echo ""

PI_IP="${PI_IP:-192.168.1.101}"
PI_USER="${PI_USER:-almed}"
APP_NAME="ahu_dashboard_pizero"
REMOTE_DIR="/home/$PI_USER/Documents/almed_ahu/$APP_NAME"
BUNDLE_SUBDIR="build/linux/arm64/release/bundle"

echo "Configuration:"
echo "  Pi IP   : $PI_IP"
echo "  Pi User : $PI_USER"
echo "  Remote  : $REMOTE_DIR/$BUNDLE_SUBDIR"
echo ""

if ! command -v flutter &>/dev/null; then
    echo "Error: Flutter not found in PATH"
    exit 1
fi

# 1 – Clean
echo "[1/5] Cleaning previous build..."
flutter clean

# 2 – Dependencies
echo "[2/5] Getting dependencies..."
flutter pub get

# 3 – Code generation (JSON serialisation)
echo "[3/5] Generating serialisation code..."
dart run build_runner build --delete-conflicting-outputs

# 4 – Build Linux ARM64 release
echo "[4/5] Building Linux ARM64 release bundle..."
flutter build linux --release
echo "  ✓ Build complete"

# 5 – Deploy to Pi Zero 2W
echo "[5/5] Deploying to Pi Zero 2W at $PI_IP..."

if ! ping -c 1 -W 2 "$PI_IP" &>/dev/null; then
    echo "  ⚠ Cannot ping $PI_IP"
    read -p "  Continue anyway? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

ssh "$PI_USER@$PI_IP" "mkdir -p $REMOTE_DIR/$BUNDLE_SUBDIR" || {
    echo "Error: SSH connection failed.  Check that SSH is enabled on the Pi:"
    echo "  ssh $PI_USER@$PI_IP"
    exit 1
}

rsync -avz --delete \
    "$BUNDLE_SUBDIR/" \
    "$PI_USER@$PI_IP:$REMOTE_DIR/$BUNDLE_SUBDIR/"

echo ""
echo "============================================"
echo "  Deployment Complete!"
echo "============================================"
echo ""
echo "To restart the kiosk on the Pi:"
echo "  ssh $PI_USER@$PI_IP 'pkill $APP_NAME; sleep 1; $REMOTE_DIR/rpi_kiosk_setup/launch_kiosk.sh &'"
echo ""
echo "Or reboot the Pi:"
echo "  ssh $PI_USER@$PI_IP sudo reboot"
echo ""
