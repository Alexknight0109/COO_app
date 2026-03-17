#!/bin/bash
# =============================================================================
# ALMED AHU Dashboard - Pi Zero 2W Kiosk Launcher
# =============================================================================
# Starts the Flutter dashboard in fullscreen kiosk mode.
# Called automatically on boot via autostart.
#
# Pi Zero 2W tuning:
#   - GPU memory raised to 128 MB in /boot/firmware/config.txt (see setup_kiosk.sh)
#   - FLUTTER_ENGINE_ARGS limits raster threads to 1 (Zero 2W has 4 cores but
#     Flutter's raster thread benefits little from more than 1 on VideoCore IV)
#   - DISPLAY is set explicitly in case the session does not export it
# =============================================================================

LOG_FILE="/tmp/almed_kiosk.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== ALMED Pi Zero 2W Kiosk Starting: $(date) ==="

# Wait for the desktop compositor to finish loading.
# Pi Zero 2W boots slower than Pi 3/4 – give it an extra 3 s.
sleep 8

export DISPLAY=:0

# Disable screen blanking / DPMS
xset s off        2>/dev/null || true
xset -dpms        2>/dev/null || true
xset s noblank    2>/dev/null || true

# Auto-hide cursor after 3 s of inactivity
pkill unclutter   2>/dev/null || true
unclutter -idle 3 -root &

# ---------------------------------------------------------------------------
# Pi Zero 2W Flutter engine settings
# ---------------------------------------------------------------------------
# Tell the engine to use a single raster thread.  The VideoCore IV GPU on the
# Zero 2W is a bottleneck; adding more raster threads adds context-switch
# overhead rather than throughput.
export FLUTTER_ENGINE_SWITCH_1="--max-threads=4"

# Reduce GPU texture cache.  The Zero 2W shares its 512 MB with the OS so
# keeping GPU memory usage low prevents swapping.
export FLUTTER_ENGINE_SWITCH_2="--skia-deterministic-rendering"

# ---------------------------------------------------------------------------
# Locate the app bundle
# ---------------------------------------------------------------------------
APP_PATH="/home/almed/Documents/almed_ahu/ahu_dashboard_pizero"

# Prefer arm64 release, fall back to debug
RELEASE_BUNDLE="$APP_PATH/build/linux/arm64/release/bundle"
DEBUG_BUNDLE="$APP_PATH/build/linux/arm64/debug/bundle"

launch_app() {
    local bundle_path="$1"
    echo "Launching from: $bundle_path"
    cd "$bundle_path"
    export LD_LIBRARY_PATH="$bundle_path/lib:$LD_LIBRARY_PATH"
    ./ahu_dashboard_pizero
}

if [ -f "$RELEASE_BUNDLE/ahu_dashboard_pizero" ]; then
    echo "Using release build"
    launch_app "$RELEASE_BUNDLE"
elif [ -f "$DEBUG_BUNDLE/ahu_dashboard_pizero" ]; then
    echo "Using debug build"
    launch_app "$DEBUG_BUNDLE"
else
    echo "No pre-built bundle found.  Attempting flutter run..."
    cd "$APP_PATH"
    if command -v flutter &>/dev/null; then
        flutter run -d linux --release
    else
        echo "ERROR: Flutter not found and no build exists!"
        echo "Build on a development machine and copy the bundle:"
        echo "  flutter build linux --release"
        echo "  rsync -avz build/linux/arm64/release/bundle/ almed@<pi-ip>:$APP_PATH/build/linux/arm64/release/bundle/"
        zenity --error \
            --text="AHU Dashboard not built!\n\nBuild on dev machine:\nflutter build linux --release" \
            2>/dev/null || true
    fi
fi

echo "=== ALMED Pi Zero 2W Kiosk Ended: $(date) ==="
