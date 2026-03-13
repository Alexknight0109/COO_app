#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  main.py
#
#  Pygame touch-UI that mirrors the ESP32 eco_display.ino behaviour:
#    Screen 1 — Scanning   (5-second progress bar, device list as discovered)
#    Screen 2 — Select     (scrollable list of AHU units)
#    Screen 3 — Control    (live T/H readings, setpoint ±, start/stop toggle)
#    Screen 4 — Keypad     (6-digit passcode unlock)
#
#  Connects to the same Mosquitto broker (10.42.0.1) and uses the same
#  MQTT topics as the ESP32 version — no changes needed on the AHU side.
#
#  Usage:
#    python3 main.py          # runs in windowed mode (config.FULLSCREEN = False)
#    python3 main.py --fs     # force fullscreen
#    python3 main.py --window # force windowed
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import sys
import time
import logging
import argparse

import pygame

import config
from mqtt_client import MqttClient
from screen_scan    import ScanScreen
from screen_select  import SelectScreen
from screen_control import ControlScreen
from screen_keypad  import KeypadScreen

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-7s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ─── Persistence helpers ─────────────────────────────────────────────────────

def _load_passcode() -> str:
    try:
        with open(config.PASSCODE_FILE, "r") as fh:
            pc = fh.read().strip()
            if len(pc) == 6 and pc.isdigit():
                return pc
    except FileNotFoundError:
        pass
    return config.DEFAULT_PASSCODE


def _save_passcode(code: str) -> None:
    try:
        with open(config.PASSCODE_FILE, "w") as fh:
            fh.write(code)
    except Exception as exc:
        log.warning("Could not save passcode: %s", exc)


def _load_lock_state() -> bool:
    try:
        with open(config.LOCK_STATE_FILE, "r") as fh:
            return fh.read().strip().lower() == "true"
    except FileNotFoundError:
        return True   # default to locked


def _save_lock_state(locked: bool) -> None:
    try:
        with open(config.LOCK_STATE_FILE, "w") as fh:
            fh.write("true" if locked else "false")
    except Exception as exc:
        log.warning("Could not save lock state: %s", exc)


# ─── Main application ─────────────────────────────────────────────────────────

class App:
    SCR_SCANNING = "scanning"
    SCR_SELECT   = "select"
    SCR_CONTROL  = "control"
    SCR_KEYPAD   = "keypad"

    def __init__(self, fullscreen: bool) -> None:
        # ── Pygame init ──────────────────────────────────────────────────────
        os.environ.setdefault("SDL_VIDEODRIVER", "x11")   # change to "fbdev" for raw framebuffer
        os.environ.setdefault("SDL_FBDEV", "/dev/fb0")
        os.environ.setdefault("SDL_MOUSEDRV", "TSLIB")    # enable touchscreen via tslib
        os.environ.setdefault("SDL_MOUSEDEV", "/dev/input/touchscreen")

        pygame.init()
        # For Pi Zero 2W we keep the cursor visible in both
        # windowed and fullscreen modes to make debugging and
        # USB-mouse control easier.
        pygame.mouse.set_visible(True)

        if fullscreen:
            self._surf = pygame.display.set_mode(
                (config.SCREEN_W, config.SCREEN_H),
                pygame.FULLSCREEN | pygame.NOFRAME,
            )
        else:
            self._surf = pygame.display.set_mode(
                (config.SCREEN_W, config.SCREEN_H),
            )
        pygame.display.set_caption("ALMED Eco Display")

        self._clock = pygame.time.Clock()

        # ── State ────────────────────────────────────────────────────────────
        self._screen      = self.SCR_SCANNING
        self._pre_lock_screen = self.SCR_CONTROL  # where to return after unlock
        self._selected_key: str | None = None     # AhuDevice.unique_key
        self._is_locked    = _load_lock_state()
        self._passcode     = _load_passcode()
        self._last_touch_ms = 0
        self._need_redraw   = True

        # ── Screen objects ───────────────────────────────────────────────────
        self._scan_screen    = ScanScreen()
        self._select_screen  = SelectScreen()
        self._control_screen = ControlScreen()
        self._keypad_screen  = KeypadScreen()

        # ── MQTT ─────────────────────────────────────────────────────────────
        self._mqtt = MqttClient()
        self._mqtt.on_devices_changed = self._on_devices_changed
        self._mqtt.on_telemetry       = self._on_telemetry
        self._mqtt.connect()

        # Draw splash immediately before MQTT completes
        self._draw_splash()

    # ── Callbacks ─────────────────────────────────────────────────────────────

    def _on_devices_changed(self) -> None:
        self._need_redraw = True

    def _on_telemetry(self, dev) -> None:
        self._need_redraw = True

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _selected_device(self):
        if not self._selected_key:
            return None
        for d in self._mqtt.devices:
            if d.unique_key == self._selected_key:
                return d
        return None

    def _wifi_ok(self) -> bool:
        # On Pi we just check if the network interface is up
        try:
            import subprocess
            result = subprocess.run(
                ["ip", "route", "show", "default"],
                capture_output=True, text=True, timeout=1,
            )
            return bool(result.stdout.strip())
        except Exception:
            return False

    # ── Splash ────────────────────────────────────────────────────────────────

    def _draw_splash(self) -> None:
        from ui import draw_text, FontCache
        self._surf.fill(config.C_BG)
        W, H = config.SCREEN_W, config.SCREEN_H
        draw_text(self._surf, "ALMED", FontCache.bold(48), config.C_PRIMARY,
                  (W // 2, H // 2 - 28), anchor="center")
        draw_text(self._surf, "AHU Eco Display", FontCache.get(15), config.C_DIM,
                  (W // 2, H // 2 + 22), anchor="center")
        draw_text(self._surf, "Connecting…", FontCache.get(13), config.C_DIM,
                  (W // 2, H // 2 + 44), anchor="center")
        pygame.display.flip()

    # ── Main loop ─────────────────────────────────────────────────────────────

    def run(self) -> None:
        while True:
            dt_ms = self._clock.tick(config.TARGET_FPS)
            self._mqtt.tick()

            # ── Handle events ────────────────────────────────────────────────
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self._shutdown()
                    return

                if event.type == pygame.KEYDOWN:
                    # Escape or Q → quit (handy during development)
                    if event.key in (pygame.K_ESCAPE, pygame.K_q):
                        self._shutdown()
                        return

                if event.type in (pygame.MOUSEBUTTONDOWN, pygame.FINGERDOWN):
                    now_ms = pygame.time.get_ticks()
                    if now_ms - self._last_touch_ms < config.TOUCH_DEBOUNCE_MS:
                        continue
                    self._last_touch_ms = now_ms

                    if event.type == pygame.FINGERDOWN:
                        # Finger events are normalized 0-1, scale to pixels
                        pos = (
                            int(event.x * config.SCREEN_W),
                            int(event.y * config.SCREEN_H),
                        )
                    else:
                        pos = event.pos

                    self._handle_touch(pos)
                    self._need_redraw = True

            # ── Auto-advance from scanning ────────────────────────────────────
            if self._screen == self.SCR_SCANNING and self._scan_screen.auto_advance():
                self._screen = self.SCR_SELECT
                self._need_redraw = True

            # ── Periodic redraw ───────────────────────────────────────────────
            if self._need_redraw or (dt_ms > config.REFRESH_MS):
                self._need_redraw = False
                self._draw()
                pygame.display.flip()

    # ── Touch routing ─────────────────────────────────────────────────────────

    def _handle_touch(self, pos: tuple) -> None:
        devices = self._mqtt.devices

        if self._screen == self.SCR_SCANNING:
            next_screen = self._scan_screen.handle_touch(pos)
            self._screen = next_screen

        elif self._screen == self.SCR_SELECT:
            action, dev = self._select_screen.handle_touch(pos, devices)
            if action == "select_device" and dev:
                self._selected_key = dev.unique_key
                self._control_screen.edit_focus = 0
                self._screen = self.SCR_CONTROL

        elif self._screen == self.SCR_CONTROL:
            dev    = self._selected_device()
            result = self._control_screen.handle_touch(pos, dev, self._is_locked)
            action = result.get("action", "none")

            if action == "back":
                self._screen = self.SCR_SELECT

            elif action == "lock":
                self._is_locked = True
                _save_lock_state(True)

            elif action == "unlock_request":
                self._keypad_screen.reset()
                self._pre_lock_screen = self.SCR_CONTROL
                self._screen = self.SCR_KEYPAD

            elif action in ("temp_down", "temp_up") and dev:
                dev.temp_set = result["value"]
                self._mqtt.send_temp_set(dev, dev.temp_set)

            elif action in ("hum_down", "hum_up") and dev:
                dev.hum_set = result["value"]
                self._mqtt.send_hum_set(dev, dev.hum_set)

            elif action == "toggle" and dev:
                self._mqtt.send_toggle(dev)

        elif self._screen == self.SCR_KEYPAD:
            result = self._keypad_screen.handle_touch(pos, self._passcode)
            action = result.get("action", "none")

            if action == "unlocked":
                self._is_locked = False
                _save_lock_state(False)
                self._screen = self._pre_lock_screen

            elif action == "cancel":
                self._screen = self._pre_lock_screen

    # ── Draw routing ──────────────────────────────────────────────────────────

    def _draw(self) -> None:
        devices   = self._mqtt.devices
        mqtt_ok   = self._mqtt.is_connected
        wifi_ok   = True   # assume ok on Pi (no easy async check)

        if self._screen == self.SCR_SCANNING:
            self._scan_screen.draw(self._surf, devices, mqtt_ok, wifi_ok)

        elif self._screen == self.SCR_SELECT:
            self._select_screen.draw(
                self._surf, devices, self._selected_key, mqtt_ok, wifi_ok,
            )

        elif self._screen == self.SCR_CONTROL:
            dev = self._selected_device()
            if dev is None:
                # Selected device disappeared – go back to list
                self._screen = self.SCR_SELECT
                self._select_screen.draw(
                    self._surf, devices, self._selected_key, mqtt_ok, wifi_ok,
                )
            else:
                self._control_screen.draw(self._surf, dev, mqtt_ok, self._is_locked)

        elif self._screen == self.SCR_KEYPAD:
            self._keypad_screen.draw(self._surf)

    # ── Cleanup ───────────────────────────────────────────────────────────────

    def _shutdown(self) -> None:
        log.info("Shutting down…")
        self._mqtt.disconnect()
        pygame.quit()


# ─── Entry point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ALMED Pi Eco Display")
    group  = parser.add_mutually_exclusive_group()
    group.add_argument("--fs",     action="store_true", help="Force fullscreen")
    group.add_argument("--window", action="store_true", help="Force windowed")
    args = parser.parse_args()

    if args.fs:
        fullscreen = True
    elif args.window:
        fullscreen = False
    else:
        fullscreen = config.FULLSCREEN

    app = App(fullscreen=fullscreen)
    app.run()
