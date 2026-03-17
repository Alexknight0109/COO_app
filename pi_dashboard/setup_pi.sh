#!/usr/bin/env bash
# =============================================================================
#  AHU Dashboard – Raspberry Pi Zero 2W Setup Script
#  Sets hostname to "almed-ahu" so the Pi is reachable as almed-ahu.local
#  on any local network without needing a direct IP address.
#  Compatible with the ESP32 firmware that connects to mqttHost = "almed-ahu.local"
# =============================================================================
set -e

HOSTNAME="almed-ahu"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   AHU Dashboard – Pi Setup                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Hostname ───────────────────────────────────────────────────────────────
# Update /etc/hosts FIRST so sudo can resolve the new hostname (avoids "unable to resolve host")
echo "→ Setting hostname to '$HOSTNAME' ..."
if grep -q "127\.0\.1\.1" /etc/hosts; then
    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1	$HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi
echo "$HOSTNAME" | sudo tee /etc/hostname > /dev/null
sudo hostnamectl set-hostname "$HOSTNAME"
echo "   Hostname set. Will take effect fully after reboot."
echo ""

# ── 2. avahi-daemon (mDNS – makes almed-ahu.local work) ──────────────────────
echo "→ Installing / enabling avahi-daemon ..."
sudo apt-get update -qq
sudo apt-get install -y -qq avahi-daemon libnss-mdns
sudo systemctl enable avahi-daemon
sudo systemctl start  avahi-daemon
echo "   avahi-daemon running. The Pi is now discoverable as $HOSTNAME.local"
echo ""

# ── 3. mosquitto MQTT broker ──────────────────────────────────────────────────
echo "→ Installing mosquitto ..."
sudo apt-get install -y -qq mosquitto mosquitto-clients

# Write config: allow all, enable password auth
MOSQ_CONF="/etc/mosquitto/conf.d/almed.conf"
sudo tee "$MOSQ_CONF" > /dev/null <<'CONF'
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
CONF

# Create / overwrite password file for user "almed"
echo "→ Setting mosquitto credentials (user: almed) ..."
sudo mosquitto_passwd -b -c /etc/mosquitto/passwd almed 'Almed1234$'
# mosquitto runs as user 'mosquitto' – must be able to read the password file
sudo chown root:mosquitto /etc/mosquitto/passwd
sudo chmod 640 /etc/mosquitto/passwd

sudo systemctl enable mosquitto
sudo systemctl restart mosquitto
echo "   Mosquitto running on port 1883."
echo ""

# ── 4. Python virtual environment (avoids externally-managed-environment) ───────
echo "→ Creating Python virtual environment ..."
sudo apt-get install -y -qq python3-venv python3-full
VENV_DIR="$SCRIPT_DIR/venv"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
"$VENV_DIR/bin/pip" install --quiet -r "$SCRIPT_DIR/requirements.txt"
echo "   Python packages installed in venv."
echo ""

# ── 5. Autostart (systemd user service) ──────────────────────────────────────
echo "→ Installing autostart service ..."
SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/ahu-dashboard.service" <<SERVICE
[Unit]
Description=AHU Dashboard
After=graphical-session.target

[Service]
Environment=DISPLAY=:0
WorkingDirectory=$SCRIPT_DIR
ExecStart=$VENV_DIR/bin/python $SCRIPT_DIR/main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable ahu-dashboard.service
echo "   Autostart service installed."
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Setup complete!                                             ║"
echo "║                                                              ║"
echo "║  mDNS hostname :  almed-ahu.local                           ║"
echo "║  MQTT broker   :  almed-ahu.local:1883                      ║"
echo "║  MQTT user     :  almed  /  Almed1234$                      ║"
echo "║                                                              ║"
echo "║  ESP32 firmware already uses:                               ║"
echo "║    mqttHost = \"almed-ahu.local\"  ← no IP needed!           ║"
echo "║                                                              ║"
echo "║  Please REBOOT now for hostname change to take effect:       ║"
echo "║    sudo reboot                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
