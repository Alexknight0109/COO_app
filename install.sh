#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  install.sh
#
#  Run once on the Raspberry Pi Zero 2W to install everything.
#  Prerequisites:
#    • Raspberry Pi OS (64-bit recommended)
#    • Python 3.10+
#    • User "almed" already created
#    • Repo cloned to ~/Documents/almed_ahu
#
#  Usage:
#    chmod +x install.sh
#    ./install.sh
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

REPO_DIR="$HOME/Documents/almed_ahu"
DISPLAY_DIR="$REPO_DIR/pi_eco_display"
SERVICE_NAME="pi-eco-display"
VENV_DIR="$DISPLAY_DIR/venv"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ALMED Pi Eco Display — Installer"
echo "═══════════════════════════════════════════════════"
echo ""

# ── 1. System packages ───────────────────────────────────────────────────────
echo "[1/6] Installing system packages…"
sudo apt-get update -qq
sudo apt-get install -y \
    python3-full python3-venv python3-pip \
    libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev \
    libsdl2-2.0-0 libfreetype6-dev \
    fonts-dejavu-core \
    mosquitto mosquitto-clients \
    --no-install-recommends

# ── 2. Python virtual environment ───────────────────────────────────────────
echo "[2/6] Creating Python venv at $VENV_DIR …"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -r "$DISPLAY_DIR/requirements.txt" -q
echo "       Done."

# ── 3. Configure Mosquitto ────────────────────────────────────────────────────
echo "[3/6] Configuring Mosquitto MQTT broker…"
MOSQ_CONF="/etc/mosquitto/mosquitto.conf"
MOSQ_PASS="/etc/mosquitto/passwd"

sudo tee "$MOSQ_CONF" > /dev/null <<'MOSQ'
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
persistence true
persistence_location /var/lib/mosquitto/
log_dest file /var/log/mosquitto/mosquitto.log
MOSQ

if [ ! -f "$MOSQ_PASS" ]; then
    echo "       Creating MQTT user 'almed' (password: Almed1234\$) …"
    sudo mosquitto_passwd -b -c "$MOSQ_PASS" almed 'Almed1234$'
else
    echo "       Password file already exists — skipping user creation."
fi

sudo systemctl enable mosquitto
sudo systemctl restart mosquitto
echo "       Mosquitto running."

# ── 4. WiFi Hotspot (PiSpot) ────────────────────────────────────────────────
echo "[4/6] Checking hotspot setup…"
if ! systemctl is-active --quiet hostapd 2>/dev/null; then
    echo "       hostapd not active. Setting up PiSpot hotspot…"
    sudo apt-get install -y hostapd dnsmasq -q

    # Static IP for wlan0
    if ! grep -q "interface wlan0" /etc/dhcpcd.conf 2>/dev/null; then
        sudo tee -a /etc/dhcpcd.conf > /dev/null <<'DHCP'

interface wlan0
    static ip_address=10.42.0.1/24
    nohook wpa_supplicant
DHCP
    fi

    # dnsmasq
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
    sudo tee /etc/dnsmasq.conf > /dev/null <<'DNSMASQ'
interface=wlan0
dhcp-range=10.42.0.10,10.42.0.100,255.255.255.0,24h
DNSMASQ

    # hostapd
    sudo tee /etc/hostapd/hostapd.conf > /dev/null <<'HOSTAPD'
interface=wlan0
driver=nl80211
ssid=PiSpot
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
HOSTAPD

    sudo tee /etc/default/hostapd > /dev/null <<'DCONF'
DAEMON_CONF="/etc/hostapd/hostapd.conf"
DCONF

    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd dnsmasq
    sudo systemctl start hostapd dnsmasq
    echo "       PiSpot hotspot started."
else
    echo "       hostapd already active — skipping hotspot setup."
fi

# ── 5. Install systemd service ───────────────────────────────────────────────
echo "[5/6] Installing systemd service…"
SERVICE_SRC="$DISPLAY_DIR/pi-eco-display.service"
SERVICE_DST="/etc/systemd/system/$SERVICE_NAME.service"

# Patch the service file with the actual home directory
sed "s|/home/almed|$HOME|g" "$SERVICE_SRC" | sudo tee "$SERVICE_DST" > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
echo "       Service enabled."

# ── 6. Disable screen blanking ───────────────────────────────────────────────
echo "[6/6] Disabling screen blanking…"
AUTOSTART_DIR="$HOME/.config/lxsession/LXDE-pi"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"
mkdir -p "$AUTOSTART_DIR"

for entry in \
    "@xset s off" \
    "@xset -dpms" \
    "@xset s noblank"; do
    grep -qF "$entry" "$AUTOSTART_FILE" 2>/dev/null || echo "$entry" | tee -a "$AUTOSTART_FILE"
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Installation complete!"
echo ""
echo "  To start the display now:"
echo "    sudo systemctl start $SERVICE_NAME"
echo ""
echo "  To start it manually (useful for testing):"
echo "    cd $DISPLAY_DIR"
echo "    ./venv/bin/python3 main.py --window"
echo ""
echo "  Reboot to activate all changes:"
echo "    sudo reboot"
echo "═══════════════════════════════════════════════════"
