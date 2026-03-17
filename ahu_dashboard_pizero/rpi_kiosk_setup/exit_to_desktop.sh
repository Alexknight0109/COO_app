#!/bin/bash
# Exit kiosk mode and return to Raspberry Pi desktop
# This script is called from the Flutter app's admin screen

# Kill the Flutter dashboard process
pkill -f "ahu_dashboard" || true

# Show the taskbar/panel if it was hidden
if command -v lxpanelctl &> /dev/null; then
    lxpanelctl restart &
fi

# Restore mouse cursor
pkill unclutter || true

# Optional: Open file manager to show desktop
# pcmanfm --desktop &

echo "Exited kiosk mode. Desktop should now be accessible."
