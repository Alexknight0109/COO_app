#!/bin/bash
# =============================================================================
# ALMED AHU Dashboard - Pi Zero 2W Kiosk Mode Setup
# =============================================================================
# This script configures the Raspberry Pi Zero 2W to:
# 1. Boot directly into the AHU Dashboard (kiosk mode)
# 2. Replace the boot splash with ALMED logo
# 3. Hide the Raspberry Pi boot logo
# 4. Auto-hide cursor and disable screen blanking
# 5. Allocate 128 MB GPU memory (required for Flutter on VideoCore IV)
# 6. Enable a 512 MB swap file to compensate for the 512 MB RAM limit
#
# Run with: sudo ./setup_kiosk.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "=============================================="
echo "   ALMED AHU Dashboard - Pi Zero 2W Kiosk Setup"
echo "=============================================="
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo${NC}"
    echo "Usage: sudo ./setup_kiosk.sh"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-almed}"
USER_HOME="/home/$ACTUAL_USER"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Setting up Pi Zero 2W kiosk mode for user: $ACTUAL_USER${NC}"
echo ""

# =============================================================================
# Step 0: Pi Zero 2W hardware optimisations
# =============================================================================
echo -e "${GREEN}[0/8] Applying Pi Zero 2W hardware settings...${NC}"

CONFIG_FILE=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
fi

if [ -n "$CONFIG_FILE" ]; then
    # Raise GPU memory to 128 MB.  The default 64 MB is too small for Flutter's
    # raster cache on a 1024×600 display with the VideoCore IV GPU.
    if grep -q "^gpu_mem=" "$CONFIG_FILE"; then
        sed -i "s/^gpu_mem=.*/gpu_mem=128/" "$CONFIG_FILE"
    else
        echo "" >> "$CONFIG_FILE"
        echo "# Pi Zero 2W – Flutter needs at least 128 MB GPU memory" >> "$CONFIG_FILE"
        echo "gpu_mem=128" >> "$CONFIG_FILE"
    fi
    echo "  ✓ GPU memory set to 128 MB"
fi

# Enable / enlarge the swap file so the 512 MB RAM is less of a constraint.
# dphys-swapfile is available on Raspberry Pi OS Lite and Desktop.
if command -v dphys-swapfile &>/dev/null; then
    SWAP_CONF="/etc/dphys-swapfile"
    if [ -f "$SWAP_CONF" ]; then
        sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/" "$SWAP_CONF"
    else
        echo "CONF_SWAPSIZE=512" > "$SWAP_CONF"
    fi
    dphys-swapfile setup  > /dev/null 2>&1 || true
    dphys-swapfile swapon > /dev/null 2>&1 || true
    echo "  ✓ Swap set to 512 MB"
else
    echo "  ⚠ dphys-swapfile not found – swap not configured"
fi

# =============================================================================
# Step 1: Network & MQTT (ESP32 mDNS compatible – no direct IP needed)
# =============================================================================
# ESP32 uses mqttHost = "almed-ahu.local" – Pi must advertise via mDNS
echo -e "${GREEN}[1/8] Configuring network & MQTT for ESP32 compatibility...${NC}"

HOSTNAME="almed-ahu"

# Set hostname so almed-ahu.local resolves
hostnamectl set-hostname "$HOSTNAME"
echo "$HOSTNAME" | tee /etc/hostname > /dev/null
if grep -q "127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1	$HOSTNAME" >> /etc/hosts
fi
echo "  ✓ Hostname set to $HOSTNAME (almed-ahu.local after reboot)"

# Install avahi + libnss-mdns for mDNS (.local resolution)
apt-get install -y -qq avahi-daemon libnss-mdns > /dev/null 2>&1
systemctl enable avahi-daemon
systemctl start avahi-daemon
echo "  ✓ mDNS enabled – Pi discoverable as $HOSTNAME.local"

# Install and configure Mosquitto MQTT broker
apt-get install -y -qq mosquitto mosquitto-clients libgtk-3-0 libblkid1 liblzma5 > /dev/null 2>&1
tee /etc/mosquitto/conf.d/almed.conf > /dev/null <<'MQTT'
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
MQTT
mosquitto_passwd -b -c /etc/mosquitto/passwd almed 'Almed1234$'
systemctl enable mosquitto
systemctl restart mosquitto
echo "  ✓ MQTT broker on almed-ahu.local:1883 (user: almed)"

# =============================================================================
# Step 2: Install required packages
# =============================================================================
echo -e "${GREEN}[2/8] Installing required packages...${NC}"
apt-get install -y -qq unclutter plymouth plymouth-themes xdotool > /dev/null 2>&1
echo "  ✓ Packages installed"

# =============================================================================
# Step 3: Create ALMED Plymouth Boot Theme
# =============================================================================
echo -e "${GREEN}[3/8] Creating ALMED boot splash theme...${NC}"

PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/almed"
mkdir -p "$PLYMOUTH_THEME_DIR"

# Copy the logo
if [ -f "$PROJECT_DIR/assets/images/logo_dark.png" ]; then
    cp "$PROJECT_DIR/assets/images/logo_dark.png" "$PLYMOUTH_THEME_DIR/logo.png"
    echo "  ✓ Logo copied"
else
    echo -e "${YELLOW}  ⚠ Logo not found, using default${NC}"
fi

# Create Plymouth theme descriptor
cat > "$PLYMOUTH_THEME_DIR/almed.plymouth" << 'EOF'
[Plymouth Theme]
Name=ALMED
Description=ALMED AHU Dashboard Boot Splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/almed
ScriptFile=/usr/share/plymouth/themes/almed/almed.script
EOF

# Create Plymouth script for boot animation
cat > "$PLYMOUTH_THEME_DIR/almed.script" << 'EOF'
# ALMED Boot Splash Script
# Background color (dark blue-gray matching app theme)
Window.SetBackgroundTopColor(0.06, 0.09, 0.16);
Window.SetBackgroundBottomColor(0.12, 0.16, 0.25);

# Load and position the logo
logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);

# Scale logo to reasonable size (max 300px width)
logo_scale = 300 / logo.image.GetWidth();
if (logo_scale > 1) logo_scale = 1;

scaled_width = logo.image.GetWidth() * logo_scale;
scaled_height = logo.image.GetHeight() * logo_scale;

logo.sprite.SetX(Window.GetWidth() / 2 - scaled_width / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - scaled_height / 2 - 50);
logo.sprite.SetOpacity(1);

# Loading text
loading_text.image = Image.Text("Loading ALMED AHU Dashboard...", 1, 1, 1);
loading_text.sprite = Sprite(loading_text.image);
loading_text.sprite.SetX(Window.GetWidth() / 2 - loading_text.image.GetWidth() / 2);
loading_text.sprite.SetY(Window.GetHeight() / 2 + scaled_height / 2);

# Progress bar background
progress_bg.image = Image.Text("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", 0.3, 0.3, 0.3);
progress_bg.sprite = Sprite(progress_bg.image);
progress_bg.sprite.SetX(Window.GetWidth() / 2 - progress_bg.image.GetWidth() / 2);
progress_bg.sprite.SetY(Window.GetHeight() / 2 + scaled_height / 2 + 40);

# Spinner dots for loading animation
spinner_index = 0;
dots = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

fun refresh_callback() {
    spinner_index++;
    if (spinner_index >= 10) spinner_index = 0;
}

Plymouth.SetRefreshFunction(refresh_callback);

# Handle boot progress
fun boot_progress_callback(duration, progress) {
    # Update progress indication
}

Plymouth.SetBootProgressFunction(boot_progress_callback);

# Handle password prompts (if encrypted disk)
fun password_dialogue_setup(prompt) {
    # Handle password entry if needed
}

Plymouth.SetDisplayPasswordFunction(password_dialogue_setup);

# Handle messages
fun message_callback(text) {
    # Handle boot messages
}

Plymouth.SetMessageFunction(message_callback);
EOF

# Set permissions
chmod 644 "$PLYMOUTH_THEME_DIR/almed.plymouth"
chmod 644 "$PLYMOUTH_THEME_DIR/almed.script"
[ -f "$PLYMOUTH_THEME_DIR/logo.png" ] && chmod 644 "$PLYMOUTH_THEME_DIR/logo.png"

echo "  ✓ Plymouth theme created"

# =============================================================================
# Step 3: Configure boot settings
# =============================================================================
echo -e "${GREEN}[4/8] Configuring boot settings...${NC}"

# Backup original cmdline.txt
if [ ! -f /boot/firmware/cmdline.txt.backup ]; then
    cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup 2>/dev/null || \
    cp /boot/cmdline.txt /boot/cmdline.txt.backup 2>/dev/null || true
fi

# Update cmdline.txt to hide boot messages and use Plymouth
CMDLINE_FILE=""
if [ -f /boot/firmware/cmdline.txt ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/cmdline.txt ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
fi

if [ -n "$CMDLINE_FILE" ]; then
    # Read current cmdline
    CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
    
    # Remove existing splash/quiet/logo settings
    NEW_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/splash//g; s/quiet//g; s/logo.nologo//g; s/vt.global_cursor_default=0//g; s/loglevel=[0-9]//g; s/  */ /g')
    
    # Add our settings
    NEW_CMDLINE="$NEW_CMDLINE quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0 loglevel=3"
    
    # Clean up extra spaces
    NEW_CMDLINE=$(echo "$NEW_CMDLINE" | sed 's/  */ /g; s/^ //; s/ $//')
    
    echo "$NEW_CMDLINE" > "$CMDLINE_FILE"
    echo "  ✓ Boot cmdline configured"
fi

# Update config.txt to disable rainbow splash
CONFIG_FILE=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
fi

if [ -n "$CONFIG_FILE" ]; then
    # Backup
    if [ ! -f "${CONFIG_FILE}.backup" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    fi
    
    # Add disable_splash if not present
    if ! grep -q "disable_splash=1" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# ALMED Kiosk - Disable rainbow splash" >> "$CONFIG_FILE"
        echo "disable_splash=1" >> "$CONFIG_FILE"
    fi
    
    echo "  ✓ Boot config updated"
fi

# Set Plymouth theme
plymouth-set-default-theme -R almed 2>/dev/null || echo "  ⚠ Plymouth theme set (rebuild may be needed)"

# =============================================================================
# Step 4: Create kiosk autostart
# =============================================================================
echo -e "${GREEN}[5/8] Setting up autostart...${NC}"

# Create autostart directory
AUTOSTART_DIR="$USER_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Create autostart entry
cat > "$AUTOSTART_DIR/almed-kiosk.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ALMED AHU Dashboard
Comment=Auto-start AHU Dashboard in kiosk mode
Exec=$SCRIPT_DIR/launch_kiosk.sh
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$AUTOSTART_DIR/almed-kiosk.desktop"
chmod +x "$SCRIPT_DIR/launch_kiosk.sh"

echo "  ✓ Autostart configured"

# =============================================================================
# Step 5: Create exit-to-desktop script
# =============================================================================
echo -e "${GREEN}[6/8] Creating exit-to-desktop helper...${NC}"

cat > "$SCRIPT_DIR/exit_to_desktop.sh" << 'EOF'
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
EOF

chmod +x "$SCRIPT_DIR/exit_to_desktop.sh"
chown "$ACTUAL_USER:$ACTUAL_USER" "$SCRIPT_DIR/exit_to_desktop.sh"

echo "  ✓ Exit helper created"

# =============================================================================
# Step 6: Configure desktop for kiosk
# =============================================================================
echo -e "${GREEN}[7/8] Configuring desktop environment...${NC}"

# Run the disable_desktop script as the actual user
if [ -f "$SCRIPT_DIR/disable_desktop.sh" ]; then
    chmod +x "$SCRIPT_DIR/disable_desktop.sh"
    su - "$ACTUAL_USER" -c "bash $SCRIPT_DIR/disable_desktop.sh" 2>/dev/null || true
fi

# Disable screen blanking system-wide
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-blanking.conf << 'EOF'
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

echo "  ✓ Desktop configured"

# =============================================================================
# Step 7: Build the Flutter app (if needed)
# =============================================================================
echo -e "${GREEN}[8/8] Checking Flutter build...${NC}"

BUNDLE_PATH="$PROJECT_DIR/build/linux/arm64/release/bundle"
if [ ! -f "$BUNDLE_PATH/ahu_dashboard_pizero" ]; then
    echo "  ⚠ Release build not found. Cross-compile on a dev machine:"
    echo "    cd $PROJECT_DIR && flutter build linux --release"
    echo "  Then copy the bundle to this Pi:"
    echo "    rsync -avz build/linux/arm64/release/bundle/ $ACTUAL_USER@<pi-ip>:$PROJECT_DIR/build/linux/arm64/release/bundle/"
else
    echo "  ✓ Release build found"
fi

# =============================================================================
# Done!
# =============================================================================
echo ""
echo -e "${GREEN}=============================================="
echo "   Kiosk Mode Setup Complete!"
echo "==============================================${NC}"
echo ""
echo "What was configured:"
echo "  ✓ Hostname almed-ahu + mDNS – ESP32 connects to almed-ahu.local (no direct IP)"
echo "  ✓ MQTT broker on port 1883 (user: almed / Almed1234\$)"
echo "  ✓ ALMED boot splash (replaces Raspberry Pi logo)"
echo "  ✓ Dashboard auto-starts on boot"
echo "  ✓ Screen blanking disabled"
echo "  ✓ Mouse cursor auto-hides"
echo "  ✓ Exit button in Admin screen returns to desktop"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Build the Flutter app if not done:"
echo "     cd $PROJECT_DIR && flutter build linux --release"
echo ""
echo "  2. Reboot to test kiosk mode:"
echo "     sudo reboot"
echo ""
echo "  3. To exit kiosk mode:"
echo "     - Use the Exit button in Admin Settings"
echo "     - Or press Ctrl+Alt+T for terminal, then run:"
echo "       $SCRIPT_DIR/exit_to_desktop.sh"
echo ""
echo -e "${BLUE}To undo kiosk mode, run:${NC}"
echo "  sudo $SCRIPT_DIR/disable_kiosk.sh"
echo ""


