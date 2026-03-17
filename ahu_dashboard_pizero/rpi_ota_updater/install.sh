#!/bin/bash
# RPi OTA Updater Installation Script

set -e

echo "======================================"
echo "  RPi OTA Updater Installation"
echo "  Simple Git Pull Based Updates"
echo "======================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./install.sh)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "1. Installing Python dependencies..."
pip3 install paho-mqtt --break-system-packages 2>/dev/null || pip3 install paho-mqtt

echo ""
echo "2. Creating environment config..."
cat > /etc/default/ahu-ota-updater << 'EOF'
# RPi OTA Updater Configuration
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=ahu_user
MQTT_PASSWORD=ahu_pass_2024
DASHBOARD_DIR=/home/almed/Documents/almed_ahu
FLUTTER_PI_SERVICE=ahu-dashboard
GIT_BRANCH=main
EOF

echo ""
echo "3. Copying service file..."
cat > /etc/systemd/system/ahu-ota-updater.service << EOF
[Unit]
Description=AHU Dashboard OTA Updater (Git Pull)
After=network.target mosquitto.service

[Service]
Type=simple
User=almed
EnvironmentFile=/etc/default/ahu-ota-updater
ExecStart=/usr/bin/python3 ${SCRIPT_DIR}/rpi_ota_updater.py
WorkingDirectory=${SCRIPT_DIR}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "4. Setting up sudoers for service control..."
cat > /etc/sudoers.d/ahu-ota-updater << 'EOF'
# Allow almed user to restart dashboard service without password
almed ALL=(ALL) NOPASSWD: /bin/systemctl restart ahu-dashboard
almed ALL=(ALL) NOPASSWD: /bin/systemctl start ahu-dashboard
almed ALL=(ALL) NOPASSWD: /bin/systemctl stop ahu-dashboard
EOF
chmod 440 /etc/sudoers.d/ahu-ota-updater

echo ""
echo "5. Creating log file..."
touch /var/log/ahu_ota_updater.log
chown almed:almed /var/log/ahu_ota_updater.log

echo ""
echo "6. Reloading systemd..."
systemctl daemon-reload

echo ""
echo "7. Enabling service..."
systemctl enable ahu-ota-updater

echo ""
echo "8. Starting service..."
systemctl start ahu-ota-updater

echo ""
echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "Service Status:"
systemctl status ahu-ota-updater --no-pager || true
echo ""
echo "Commands:"
echo "  sudo systemctl status ahu-ota-updater  - Check status"
echo "  sudo journalctl -u ahu-ota-updater -f  - View logs"
echo ""
echo "The service will:"
echo "  1. Listen for commands from ESP32 via local MQTT"
echo "  2. Run 'git pull origin main' when update requested"
echo "  3. Restart the dashboard service"
echo "  4. Send confirmation back"
echo ""
