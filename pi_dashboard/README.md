# AHU Dashboard – Pi Zero 2W Edition

A lightweight Python/CustomTkinter reimplementation of the Flutter AHU dashboard,
optimised for **Raspberry Pi Zero 2W (512 MB RAM)** with a **1024 × 600** 7-inch display.

## Why CustomTkinter?

| Criterion | CustomTkinter | Flutter | Dear PyGui |
|---|---|---|---|
| RAM (typical) | ~60–80 MB | ~200–300 MB | ~40 MB* |
| GPU required | No (CPU/X11) | Yes (Skia) | Yes (OpenGL 3.3+)* |
| Pi Zero 2W | ✅ Works out of the box | ⚠️ Heavy | ❌ OpenGL 3.3 unavailable |
| Modern UI | ✅ Rounded, dark/light | ✅ | ✅ |
| MQTT/Python libs | ✅ Native | ❌ Needs bridges | ✅ |

*Dear PyGui requires OpenGL 3.3+ — Pi Zero 2W only has VideoCore IV / OpenGL ES 2.0.

## Features

- **Login screen** with Hospital / Admin role selection (gradient background)
- **Admin passcode** dialog (4-digit, "1234")
- **Dashboard** – live AHU cards with temperature, humidity, status chips
- **AHU Control screen** – full control panel:
  - Start / Stop button
  - Temperature & humidity setpoints (+/− controls)
  - CP mode toggle (DUAL / SINGLE)
  - Component status indicators (Motor 1/2, CP1/2, Heater, Fan)
  - Fan speed toggle
  - Screen lock (6-digit, default "123123")
  - Combo sensor display (PM, AQI, CO₂, HEPA health)
  - System logs (admin)
- **Admin settings screen** – WiFi, MQTT broker, motor timing provisioning
- **Motor timing dialog** with ± controls
- **WiFi manager dialog** (nmcli-based, Linux/RPi only)
- **Dark / Light theme** toggle (persists per session)

## Installation

### Raspberry Pi Zero 2W (one-time setup)

```bash
cd pi_dashboard
bash setup_pi.sh   # sets hostname, installs avahi + mosquitto, configures autostart
sudo reboot
```

After reboot the Pi is reachable as **`almed-ahu.local`** on any local network —
no router config, no static IP, no DHCP reservation needed.

### Development machine

```bash
cd pi_dashboard
pip install -r requirements.txt
python main.py
```

## Screen Sizes

Fixed 1024 × 600 window. On Raspberry Pi the app enters full-screen automatically.
On a development machine it runs as a regular 1024 × 600 window.

## mDNS / Hostname

The ESP32 firmware uses:
```cpp
String mqttHost = "almed-ahu.local";   // no direct IP needed
```

`setup_pi.sh` configures the Pi to match exactly:

| What | Value |
|---|---|
| Pi hostname | `almed-ahu` |
| mDNS name | `almed-ahu.local` |
| MQTT broker | `almed-ahu.local:1883` |
| avahi-daemon | enabled + autostart |

This means the **ESP32 connects to the broker without ever needing the Pi's IP address**.
If the Pi gets a new IP (DHCP lease renewal, different router, etc.) everything keeps
working because mDNS always resolves to the current IP.

## MQTT

Default broker: `almed-ahu.local:1883`  
Credentials: `almed / Almed1234$`  
Wildcard subscription: `almed/ahu/#`

Matches the same topic structure used by the ESP32 firmware.

## Default Passcodes

| Dialog | Passcode |
|---|---|
| Admin login | `1234` |
| Screen unlock | `123123` |
