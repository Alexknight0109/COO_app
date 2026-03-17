# Raspberry Pi OTA Updater for AHU Dashboard

Simple `git pull` based OTA updates for the Flutter dashboard running on Raspberry Pi. Commands are sent through ESP32 via local MQTT.

## Architecture

```
┌─────────────────┐    AWS IoT     ┌─────────────┐   Local MQTT   ┌─────────────┐
│  Web Dashboard  │ ────────────▶ │   ESP32     │ ─────────────▶ │ Raspberry   │
│  (Select ESP)   │               │  (Gateway)  │                │     Pi      │
└─────────────────┘               └─────────────┘                └─────────────┘
        ▲                                │                              │
        │                                │                              ▼
        └────────────────────────────────┘                      ┌─────────────────┐
              Status relay back                                 │   git pull      │
                                                                │   origin main   │
                                                                └─────────────────┘
```

## How It Works

1. User selects ESP32 in web dashboard OTA page
2. Web dashboard sends command to ESP32 via AWS IoT MQTT
3. ESP32 relays command to RPi via local MQTT
4. RPi runs `git pull origin main`
5. RPi restarts the Flutter dashboard service
6. RPi sends confirmation back via MQTT
7. ESP32 relays status to AWS IoT → Web dashboard

## Installation

### 1. Copy files to Raspberry Pi

```bash
# From your Mac/PC
scp -r rpi_ota_updater/ pi@<RPI_IP>:/home/pi/
```

### 2. SSH into RPi and install

```bash
ssh pi@<RPI_IP>
cd /home/pi/rpi_ota_updater
chmod +x install.sh
sudo ./install.sh
```

### 3. Verify the dashboard is a git repo

```bash
cd /home/pi/ahu_dashboard
git status  # Should show git repo info
git remote -v  # Should show origin URL
```

### 4. Start the service

```bash
sudo systemctl start ahu-ota-updater
sudo systemctl status ahu-ota-updater
```

## Configuration

Environment variables (set in `/etc/default/ahu-ota-updater`):

| Variable | Default | Description |
|----------|---------|-------------|
| `MQTT_BROKER` | 10.42.0.1 | Local MQTT broker IP (ESP32 hotspot) |
| `MQTT_PORT` | 1883 | MQTT broker port |
| `MQTT_USERNAME` | ahu_user | MQTT username |
| `MQTT_PASSWORD` | ahu_pass_2024 | MQTT password |
| `DASHBOARD_DIR` | /home/pi/ahu_dashboard | Flutter dashboard git directory |
| `FLUTTER_PI_SERVICE` | ahu-dashboard | Systemd service name |
| `GIT_BRANCH` | main | Git branch to pull from |

## MQTT Commands

Commands are sent to `almed/rpi/ota/command`:

### Update (git pull + restart)
```json
{"type": "ota_update", "from_esp": "KAVERI_BURNS_AHU1"}
```

### Check for Updates
```json
{"type": "check_update"}
```

### Restart Dashboard
```json
{"type": "restart"}
```

### Get Status
```json
{"type": "status"}
```

## Status Responses

Published to `almed/rpi/ota/status`:

```json
{
  "status": "complete",
  "message": "✅ Updated: abc123 → def456",
  "current_version": "def456",
  "progress": 100,
  "timestamp": "2024-01-01T12:00:00"
}
```

Status values:
- `online` - Service ready
- `checking` - Checking for updates
- `update_available` - New commits found
- `up_to_date` - Already on latest
- `starting` - Update starting
- `pulling` - Running git pull
- `pulled` - Code updated
- `restarting` - Restarting service
- `complete` - Update finished ✅
- `error` - Something went wrong

## Testing from Command Line

```bash
# On the RPi, test MQTT manually:

# Check status
mosquitto_pub -h 10.42.0.1 -u ahu_user -P ahu_pass_2024 \
  -t "almed/rpi/ota/command" -m '{"type": "status"}'

# Trigger update
mosquitto_pub -h 10.42.0.1 -u ahu_user -P ahu_pass_2024 \
  -t "almed/rpi/ota/command" -m '{"type": "ota_update"}'

# Watch status responses
mosquitto_sub -h 10.42.0.1 -u ahu_user -P ahu_pass_2024 \
  -t "almed/rpi/ota/status"
```

## Logs

```bash
# View service logs
sudo journalctl -u ahu-ota-updater -f

# View application log
tail -f /var/log/ahu_ota_updater.log
```

## Troubleshooting

### Service not starting
```bash
sudo systemctl status ahu-ota-updater
sudo journalctl -u ahu-ota-updater -n 50
```

### Git pull fails
```bash
cd /home/pi/ahu_dashboard
git status
git remote -v
git fetch origin main
```

### MQTT not connecting
```bash
# Check if mosquitto is running
systemctl status mosquitto

# Test connection
mosquitto_sub -h 10.42.0.1 -u ahu_user -P ahu_pass_2024 -t "test"
```
