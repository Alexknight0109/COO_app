#!/bin/bash

# AHU Dashboard Deployment Script
# Builds and deploys the Flutter app to Raspberry Pi

set -e

echo "======================================"
echo "AHU Dashboard Deployment Script"
echo "======================================"
echo ""

# Configuration
PI_IP="${PI_IP:-192.168.1.100}"
PI_USER="${PI_USER:-pi}"
APP_DIR="/home/pi/ahu_dashboard"

echo "Configuration:"
echo "  Pi IP: $PI_IP"
echo "  Pi User: $PI_USER"
echo "  App Directory: $APP_DIR"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Step 1: Clean previous build
echo "[1/5] Cleaning previous build..."
flutter clean

# Step 2: Get dependencies
echo "[2/5] Getting dependencies..."
flutter pub get

# Step 3: Generate code
echo "[3/5] Generating JSON serialization code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Step 4: Build Flutter bundle
echo "[4/5] Building Flutter bundle..."
flutter build bundle --release

# Step 5: Deploy to Raspberry Pi
echo "[5/5] Deploying to Raspberry Pi..."

# Check if Pi is reachable
if ! ping -c 1 -W 2 $PI_IP &> /dev/null; then
    echo "Warning: Cannot reach Raspberry Pi at $PI_IP"
    echo "Make sure the Pi is powered on and connected to the network."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create directory on Pi if it doesn't exist
echo "Creating app directory on Pi..."
ssh $PI_USER@$PI_IP "mkdir -p $APP_DIR" || {
    echo "Error: Could not connect to Raspberry Pi"
    echo "Make sure SSH is enabled and you can connect manually:"
    echo "  ssh $PI_USER@$PI_IP"
    exit 1
}

# Copy Flutter bundle to Pi
echo "Copying Flutter bundle..."
rsync -avz --delete build/flutter_assets/ $PI_USER@$PI_IP:$APP_DIR/

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "To run the dashboard on the Pi:"
echo "  ssh $PI_USER@$PI_IP"
echo "  flutter-pi --release $APP_DIR"
echo ""
echo "To set up auto-start, see README.md"
echo ""

