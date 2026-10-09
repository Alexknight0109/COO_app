#!/bin/bash
# Build the kiosk bundle with the version shown at the bottom of the role
# screen (v1.0.<commit count> · <hash>). Same build the OTA updater runs.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_PATH"

VERSION="1.0.$(git rev-list --count HEAD)"
COMMIT="$(git rev-parse --short HEAD)"
echo "Building AHU dashboard v$VERSION ($COMMIT)"

flutter pub get
flutter build linux --release \
    --dart-define=APP_VERSION="$VERSION" \
    --dart-define=APP_COMMIT="$COMMIT"

echo "Built v$VERSION ($COMMIT). Restart the kiosk to use it."
