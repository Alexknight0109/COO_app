#!/bin/bash
# =============================================================================
# ALMED AHU Dashboard - Kiosk Launcher
# =============================================================================
# This script launches the Flutter dashboard in fullscreen kiosk mode
# It is called automatically on boot via autostart
# =============================================================================

# Log file for debugging
LOG_FILE="/tmp/almed_kiosk.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== ALMED Kiosk Starting: $(date) ==="

# Wait for desktop to fully load
sleep 5

# Disable screen blanking and power management
export DISPLAY=:0
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true
xset s 0 0 2>/dev/null || true
xset dpms 0 0 0 2>/dev/null || true

# Ensure desktop lockers are not active in kiosk mode.
pkill light-locker 2>/dev/null || true
pkill xscreensaver 2>/dev/null || true

# Hide mouse cursor after 3 seconds of inactivity
pkill unclutter 2>/dev/null || true
unclutter -idle 3 -root &

# Hide the taskbar/panel for cleaner kiosk look (optional)
# lxpanelctl command hide 2>/dev/null || true

# Path to the Flutter app
APP_PATH="/home/almed/Documents/almed_ahu/ahu_dashboard"

# Try release build first, then debug
RELEASE_BUNDLE="$APP_PATH/build/linux/arm64/release/bundle"
DEBUG_BUNDLE="$APP_PATH/build/linux/arm64/debug/bundle"

launch_app() {
    local bundle_path="$1"
    echo "Launching from: $bundle_path"
    cd "$bundle_path"
    
    # Set library path for Flutter
    export LD_LIBRARY_PATH="$bundle_path/lib:$LD_LIBRARY_PATH"
    
    # Run the app in fullscreen
    ./ahu_dashboard
}

if [ -f "$RELEASE_BUNDLE/ahu_dashboard" ]; then
    echo "Using release build"
    launch_app "$RELEASE_BUNDLE"
elif [ -f "$DEBUG_BUNDLE/ahu_dashboard" ]; then
    echo "Using debug build"
    launch_app "$DEBUG_BUNDLE"
else
    echo "No pre-built bundle found. Attempting flutter run..."
    cd "$APP_PATH"
    
    # Check if flutter is available
    if command -v flutter &> /dev/null; then
        flutter run -d linux --release
    else
        echo "ERROR: Flutter not found and no build exists!"
        echo "Please build the app first:"
        echo "  cd $APP_PATH && flutter build linux --release"
        
        # Show error message on screen
        zenity --error --text="AHU Dashboard not built!\n\nPlease run:\nflutter build linux --release" 2>/dev/null || true
    fi
fi

echo "=== ALMED Kiosk Ended: $(date) ==="
