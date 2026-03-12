# ALMED AHU — Pi Zero 2W Eco Display

A Python/Pygame touch UI for the **Raspberry Pi Zero 2W** that exactly mirrors the ESP32
`eco_display.ino` behaviour.  It connects to the same local MQTT broker (`10.42.0.1`),
auto-discovers every AHU device, and lets you monitor and control Temperature / Humidity
with the same four-screen flow.

> **No changes required on the ESP32 AHU firmware.**

---

## Hardware

| Part | Notes |
|------|-------|
| Raspberry Pi Zero 2W | Any OS with Python 3.10+ |
| HDMI display (3.5" – 7") | 480×320 or larger recommended |
| USB / GPIO touchscreen | tslib or evdev supported |
| microSD 8 GB+ | Class 10 |
| 5 V / 2.5 A USB supply | Pi Zero needs clean power |

The Pi Zero 2W acts as:
- **WiFi hotspot** (`PiSpot`, 10.42.0.1)
- **MQTT broker** (Mosquitto)
- **Display controller** (this app)

---

## File Structure

```
pi_eco_display/
├── main.py              ← App entry point (run this)
├── config.py            ← All credentials and tunable constants
├── mqtt_client.py       ← Thread-safe MQTT service
├── ui.py                ← Pygame drawing helpers
├── screen_scan.py       ← Screen 1 – Scanning
├── screen_select.py     ← Screen 2 – Device Select
├── screen_control.py    ← Screen 3 – Control
├── screen_keypad.py     ← Screen 4 – Passcode Keypad
├── requirements.txt
├── pi-eco-display.service  ← systemd unit
└── install.sh           ← One-shot installer
```

---

## Quick Start

### 1. Clone the repo on the Pi

```bash
mkdir -p ~/Documents && cd ~/Documents
git clone https://github.com/<your-repo>/almed_ahu.git
```

### 2. Run the installer

```bash
cd ~/Documents/almed_ahu/pi_eco_display
chmod +x install.sh
./install.sh
```

The installer will:
1. Install system packages (Pygame SDL2, Mosquitto)
2. Create a Python virtual environment and install dependencies
3. Configure Mosquitto with MQTT user `almed` / `Almed1234$`
4. Set up the `PiSpot` WiFi hotspot (SSID: `PiSpot`, pass: `12345678`)
5. Install and enable the `pi-eco-display` systemd service
6. Disable screen blanking

### 3. Reboot

```bash
sudo reboot
```

The display app starts automatically on boot.

---

## Configuration (`config.py`)

| Setting | Default | Description |
|---------|---------|-------------|
| `MQTT_BROKER` | `10.42.0.1` | Mosquitto IP (Pi hotspot gateway) |
| `MQTT_USER` | `almed` | MQTT username |
| `MQTT_PASS` | `Almed1234$` | MQTT password |
| `SCREEN_W` / `SCREEN_H` | `480` / `320` | Display resolution |
| `FULLSCREEN` | `True` | Set `False` for desktop testing |
| `DEFAULT_PASSCODE` | `123123` | Initial 6-digit lock code |

---

## Screens

### 1 — Scanning
Shown for 5 s at startup. A progress bar fills while retained messages arrive.  
Any tap skips straight to the device list.

### 2 — Device Select
Lists every discovered AHU unit. Tap a row to open its control screen.  
The previously active device is marked `ACTIVE`. Scroll arrows appear when > 4 devices exist.

### 3 — Control
```
┌─ < Back          AHU_ESP2           OPEN ─┐
│  TEMPERATURE                              │
│   24.3 °C                                 │
│   SET: 22.0 °C              [−]  [+]      │
├───────────────────────────────────────────┤
│  HUMIDITY                                 │
│   61.5 %                                  │
│   SET: 55.0 %               [−]  [+]      │
├───────────────────────────────────────────┤
│  AHU: RUNNING                Tap to toggle│
└───────────────────────────────────────────┘
```
- Tap **−** / **+** to adjust setpoint (MQTT command sent immediately)
- Tap the bottom bar to toggle start / stop
- Tap **LOCK / OPEN** (top-right) to lock or open the passcode keypad
- Tap **< Back** to return to device list

### 4 — Passcode Keypad
6-dot indicator shows progress. Tap digits, **←** to backspace, **✓** to confirm.  
Wrong passcode flashes red. Tap outside the pad to cancel.

---

## Lock Behaviour

| State | What is blocked |
|-------|----------------|
| Locked | All setpoint changes and toggle; viewing always allowed |
| Unlocked | Full control |

Lock state is saved to `.lockstate` and survives reboots.  
Passcode is saved to `.passcode`. Default: `123123`.

---

## Manual / Development Run

```bash
cd ~/Documents/almed_ahu/pi_eco_display

# Windowed (for desktop testing)
./venv/bin/python3 main.py --window

# Fullscreen
./venv/bin/python3 main.py --fs
```

---

## MQTT Topics Used

| Direction | Topic | Payload |
|-----------|-------|---------|
| Subscribe | `almed/ahu/#` | Wildcard – catches status, state, telemetry |
| Publish | `almed/ahu/{site}/{room}/{ahu}/cmd` | `{"setpoint": 22.5}` |
| Publish | `almed/ahu/{site}/{room}/{ahu}/cmd` | `{"humset": 55.0}` |
| Publish | `almed/ahu/{site}/{room}/{ahu}/cmd` | `{"toggle": true}` |
| Publish (LWT) | `almed/eco_display/status` | `online` / `offline` |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Black screen | Check `DISPLAY=:0` in the service file; verify Pygame SDL2 is installed |
| Touch not working | Set `SDL_MOUSEDRV=TSLIB` and `SDL_MOUSEDEV=/dev/input/touchscreen` in the service |
| No devices found | Confirm ESP32 AHU is connected to `PiSpot` and Mosquitto is running: `sudo systemctl status mosquitto` |
| Wrong colours | Swap `C_BG` / `C_TEXT` in `config.py` |
| Service not starting | Check: `journalctl -u pi-eco-display -f` |
