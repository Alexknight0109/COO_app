# AHU Dashboard – Pi Zero 2W Edition

A performance-tuned version of the `ahu_dashboard` Flutter app targeting the
**Raspberry Pi Zero 2W** running a 7-inch 1024×600 touch display in kiosk mode.

The UI is intentionally identical to the standard `ahu_dashboard`; only the
internal performance parameters and hardware setup scripts differ.

---

## ESP32 mDNS Compatibility (No Direct IP Needed)

The Pi Zero 2W setup is compatible with the ESP32 firmware in `esp32_main_v2_active_high.ino`, which connects to:

```cpp
String mqttHost = "almed-ahu.local";  // RPi mDNS hostname - works on ANY network!
```

The kiosk setup script (`rpi_kiosk_setup/setup_kiosk.sh`) configures:

- **Hostname** `almed-ahu` → Pi is reachable as `almed-ahu.local`
- **Avahi (mDNS)** → advertises the Pi on the local network
- **Mosquitto MQTT** → broker on port 1883 (user: `almed` / `Almed1234$`)

Both the Pi and ESP32 must be on the **same WiFi network**. The ESP32 discovers the Pi by hostname; no static IP or direct IP configuration is required.

---

## What Changed vs `ahu_dashboard`

| Area | Standard (`ahu_dashboard`) | Pi Zero 2W (`ahu_dashboard_pizero`) |
|------|---------------------------|--------------------------------------|
| Package name | `ahu_dashboard` | `ahu_dashboard_pizero` |
| Telemetry debounce | 250 ms | 500 ms |
| State debounce | 150 ms | 300 ms |
| Throttle minimum | 300 ms | 600 ms |
| Log buffer | 70 entries | 30 entries |
| Image cache | Default | Capped at 50 images / 20 MB |
| RepaintBoundary | Cards only | Top bar + each control section |
| GPU memory | Not set | Raised to 128 MB in `config.txt` |
| Swap | Not configured | 512 MB via `dphys-swapfile` |
| Launch boot delay | 5 s | 8 s (Zero 2W boots slower) |

### Why these specific numbers?

The Pi Zero 2W has a single-die **Cortex-A53 quad-core @ 1 GHz** with
**512 MB RAM** shared between the OS, the GPU, and every running process.
Flutter's raster pipeline competes with the MQTT client and the OS scheduler
on these limited resources.

- **Longer debounce** – sensor telemetry arrives every few seconds.
  A 500 ms batch window means at most ~2 UI redraws per second from MQTT,
  which is comfortable for the VideoCore IV GPU.
- **Smaller log buffer** – each `AhuLog` object sits in the Dart heap.
  30 entries ≈ 30 KB; 70 entries ≈ 70 KB.  Trivial on a Pi 4 but worth
  keeping trim on a 512 MB device.
- **128 MB GPU memory** – Flutter's Skia raster cache needs headroom.
  The default 64 MB can cause frame drops on a 1024×600 display.
- **RepaintBoundary** – Flutter's compositor promotes a `RepaintBoundary`
  widget to its own GPU layer.  When a child changes (e.g. temperature
  reading updates), only that layer is re-composited; the rest of the screen
  is served from the GPU's layer cache without touching the CPU.

---

## Hardware Requirements

| Component | Spec |
|-----------|------|
| SBC | Raspberry Pi Zero 2W |
| Display | 7-inch DSI or HDMI panel, 1024×600 |
| OS | Raspberry Pi OS (64-bit) – Bookworm or later |
| Storage | 8 GB+ microSD |
| RAM | 512 MB (fixed) |

> **64-bit OS is required.**  Flutter Linux only ships ARM64 binaries.
> Use the *Raspberry Pi OS (64-bit)* image from raspberrypi.com.

---

## ESP32 mDNS Compatibility

The Pi Zero 2W setup is compatible with the ESP32 firmware in
`esp32_main_v2_active_high.ino`, which connects using:

```cpp
String mqttHost = "almed-ahu.local";  // RPi mDNS hostname - works on ANY network!
```

**No direct IP configuration needed.** The `setup_kiosk.sh` script configures:

- **Hostname** `almed-ahu` → Pi is reachable as `almed-ahu.local` on your LAN
- **Avahi (mDNS)** → Advertises the Pi so ESP32 can discover it
- **Mosquitto MQTT broker** → Port 1883, credentials `almed` / `Almed1234$`

Both the Pi and ESP32 must be on the **same WiFi network**. The ESP32 connects to
`almed-ahu.local:1883` automatically, regardless of the Pi’s IP address.

---

## First-Time Setup on the Pi

### 1  Copy the project to the Pi

Ensure the full `ahu_dashboard_pizero` directory (including `rpi_kiosk_setup/`)
is on the Pi, for example:

```bash
rsync -avz ahu_dashboard_pizero/ almed@192.168.1.101:~/Documents/almed_ahu/ahu_dashboard_pizero/
```

Or clone the repo on the Pi.

### 2  Run kiosk setup (installs MQTT, mDNS, hostname, and kiosk)

```bash
ssh almed@192.168.1.101
cd ~/Documents/almed_ahu/ahu_dashboard_pizero
sudo ./rpi_kiosk_setup/setup_kiosk.sh
```

This configures hostname `almed-ahu`, Avahi mDNS, Mosquitto, and kiosk mode.
No separate MQTT or network setup is required.

### 3  Build the app (on your dev Mac / Linux machine)

```bash
cd ahu_dashboard_pizero
flutter build linux --release
```

### 4  Deploy to the Pi

```bash
PI_IP=192.168.1.101 PI_USER=almed ./deploy.sh
```

### 5  Reboot the Pi

```bash
ssh almed@192.168.1.101 sudo reboot
```

After reboot, the dashboard starts automatically. The ESP32 connects to
`almed-ahu.local` with no IP configuration.

---

## Building Locally on the Pi Zero 2W

Building Flutter on the Zero 2W itself is possible but takes ~15–25 minutes
per build.  Cross-compiling on a development machine and deploying with
`deploy.sh` is strongly recommended.

If you must build on the Pi:

```bash
# Install Flutter (ARM64 snap or manual install)
sudo snap install flutter --classic
flutter config --enable-linux-desktop
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build linux --release
```

---

## Kiosk Operation

| Action | How |
|--------|-----|
| Exit kiosk | Admin screen → Exit button |
| Restart app | `pkill ahu_dashboard_pizero` (auto-relaunches via systemd or next boot) |
| View logs | `cat /tmp/almed_kiosk.log` |
| SSH in | `ssh almed@<pi-ip>` |
| Update app | Run `deploy.sh` from dev machine, then `sudo reboot` on Pi |

---

## Troubleshooting

### App lags / drops frames
- Check GPU memory: `vcgencmd get_mem gpu` → should show `128M`
- Check free RAM: `free -m` → available should be > 100 MB
- Check CPU temperature: `vcgencmd measure_temp` → if > 80°C add a heatsink

### App won't start (black screen)
- Check kiosk log: `cat /tmp/almed_kiosk.log`
- Verify the bundle exists: `ls ~/Documents/almed_ahu/ahu_dashboard_pizero/build/linux/arm64/release/bundle/`
- Make sure the binary is executable: `chmod +x .../bundle/ahu_dashboard_pizero`

### MQTT not connecting
- Verify broker: `mosquitto_sub -h localhost -t '#' -u almed -P 'Almed1234$'`
- Check service: `sudo systemctl status mosquitto`

### Touch not working
- Check display driver; for DSI panels add `dtoverlay=vc4-kms-dsi-7inch` (or your specific overlay) to `/boot/firmware/config.txt`
