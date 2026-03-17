#!/bin/bash
# Disable desktop elements for a cleaner kiosk experience
# Run this once during setup

set -e

echo "Configuring kiosk mode desktop settings..."

# Create autostart directory if it doesn't exist
mkdir -p ~/.config/autostart

# Disable desktop icons and wallpaper manager for LXDE/PIXEL
if [ -f ~/.config/pcmanfm/LXDE-pi/desktop-items-0.conf ]; then
    sed -i 's/show_documents=1/show_documents=0/' ~/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
    sed -i 's/show_trash=1/show_trash=0/' ~/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
    sed -i 's/show_mounts=1/show_mounts=0/' ~/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
fi

# Hide taskbar/panel (optional - uncomment if you want this)
# mkdir -p ~/.config/lxpanel/LXDE-pi/panels
# echo "" > ~/.config/lxpanel/LXDE-pi/panels/panel

echo "Desktop configured for kiosk mode"


