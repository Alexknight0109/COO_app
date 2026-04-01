#!/bin/bash
# =============================================================================
# ALMED AHU Dashboard - Disable Kiosk Mode
# =============================================================================
# Run with: sudo ./disable_kiosk.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Disabling kiosk mode...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-almed}"
USER_HOME="/home/$ACTUAL_USER"

# Remove autostart entry
rm -f "$USER_HOME/.config/autostart/almed-kiosk.desktop"
rm -f "$USER_HOME/.config/autostart/light-locker.desktop"
echo "  ✓ Autostart removed"

# Restore original boot config
if [ -f /boot/firmware/cmdline.txt.backup ]; then
    cp /boot/firmware/cmdline.txt.backup /boot/firmware/cmdline.txt
    echo "  ✓ Boot cmdline restored"
elif [ -f /boot/cmdline.txt.backup ]; then
    cp /boot/cmdline.txt.backup /boot/cmdline.txt
    echo "  ✓ Boot cmdline restored"
fi

# Restore Plymouth to default
plymouth-set-default-theme -R spinner 2>/dev/null || true
echo "  ✓ Plymouth theme reset to default"

# Remove screen blanking config
rm -f /etc/X11/xorg.conf.d/10-blanking.conf

echo ""
echo -e "${GREEN}Kiosk mode disabled. Reboot to apply changes.${NC}"
echo "Run: sudo reboot"


