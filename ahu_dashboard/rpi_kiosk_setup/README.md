# ALMED AHU Dashboard - Kiosk Mode Setup

This guide explains how to configure your Raspberry Pi to run the AHU Dashboard in kiosk mode, with:
- **Auto-start on boot** - Dashboard launches automatically when Pi powers on
- **Custom boot splash** - ALMED logo replaces the Raspberry Pi boot logo
- **No distractions** - Taskbar hidden, mouse auto-hides, no screen blanking
- **Exit to desktop** - Button in Admin Settings to return to Raspbian when needed

---

## Quick Setup

### 1. Build the Flutter App

```bash
cd /home/almed/Documents/almed_ahu/ahu_dashboard
flutter build linux --release
```

### 2. Run the Kiosk Setup Script

```bash
cd /home/almed/Documents/almed_ahu/ahu_dashboard/rpi_kiosk_setup
sudo ./setup_kiosk.sh
```

### 3. Reboot

```bash
sudo reboot
```

That's it! The Pi will now boot directly into the AHU Dashboard.

---

## What the Setup Does

| Feature | Description |
|---------|-------------|
| **Boot Splash** | Custom Plymouth theme with ALMED logo |
| **Auto-start** | Dashboard launches via `~/.config/autostart/` |
| **No Boot Messages** | Kernel messages hidden, clean boot |
| **No RPi Logo** | Rainbow splash and boot logo disabled |
| **Screen Always On** | DPMS and screen blanking disabled |
| **Hidden Cursor** | Mouse hides after 3 seconds of inactivity |

---

## Exiting Kiosk Mode

### Method 1: From the App (Recommended)
1. Go to **Admin Settings** (requires admin passcode)
2. Click the **desktop icon** button (Exit to Desktop)
3. Confirm to exit

### Method 2: Keyboard Shortcut
1. Press `Ctrl + Alt + T` to open terminal
2. Run: `pkill ahu_dashboard`

### Method 3: SSH
```bash
ssh almed@<pi-ip-address>
pkill ahu_dashboard
```

---

## Files Overview

```
rpi_kiosk_setup/
├── setup_kiosk.sh        # Main setup script (run with sudo)
├── disable_kiosk.sh      # Undo kiosk mode (run with sudo)
├── launch_kiosk.sh       # App launcher (called on boot)
├── exit_to_desktop.sh    # Called by app's exit button
├── disable_desktop.sh    # Hides desktop icons
└── README.md             # This file
```

---

## Disabling Kiosk Mode

To return to normal Raspberry Pi desktop behavior:

```bash
cd /home/almed/Documents/almed_ahu/ahu_dashboard/rpi_kiosk_setup
sudo ./disable_kiosk.sh
sudo reboot
```

This will:
- Remove auto-start entry
- Restore default boot splash (Raspberry Pi logo)
- Restore original boot settings

---

## Troubleshooting

### Dashboard doesn't start on boot
- Check if the Flutter build exists:
  ```bash
  ls /home/almed/Documents/almed_ahu/ahu_dashboard/build/linux/arm64/release/bundle/
  ```
- Check the kiosk log:
  ```bash
  cat /tmp/almed_kiosk.log
  ```

### Boot splash not showing ALMED logo
- Rebuild initramfs:
  ```bash
  sudo update-initramfs -u
  ```
- Verify Plymouth theme:
  ```bash
  plymouth-set-default-theme -l
  ```

### Screen goes black after inactivity
- Check Xorg config:
  ```bash
  cat /etc/X11/xorg.conf.d/10-blanking.conf
  ```
- Manually disable:
  ```bash
  xset s off && xset -dpms && xset s noblank
  ```

### Can't exit to desktop
- Use SSH or physical keyboard to kill the app:
  ```bash
  pkill ahu_dashboard
  ```

---

## Customization

### Change Boot Splash Logo
Replace the logo file and rebuild:
```bash
sudo cp /path/to/your/logo.png /usr/share/plymouth/themes/almed/logo.png
sudo update-initramfs -u
```

### Delay Before App Starts
Edit `launch_kiosk.sh` and change `sleep 5` to a longer value.

### Keep Taskbar Visible
Comment out the `lxpanelctl` line in `launch_kiosk.sh`.

---

## Recovery Mode

If something goes wrong and you can't access the Pi:

1. **Boot with external keyboard** - Press `Ctrl+Alt+F2` for TTY console
2. **SSH in** - `ssh almed@raspberrypi.local`
3. **Disable kiosk**:
   ```bash
   rm ~/.config/autostart/almed-kiosk.desktop
   sudo reboot
   ```

---

## Requirements

- Raspberry Pi (tested on Pi 4/5)
- Raspberry Pi OS with Desktop
- Flutter SDK (for building)
- Internet connection (for initial package install)


