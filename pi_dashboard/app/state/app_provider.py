"""
Central application state.  Parses incoming MQTT messages and notifies
registered listeners.  All listener callbacks are invoked on the main
(tkinter) thread.
"""
import json
import time
from collections import defaultdict, deque
from typing import Callable, Dict, List, Optional, Deque

import customtkinter as ctk

from app.models.ahu_unit import AhuUnit
from app.models.ahu_telemetry import AhuTelemetry
from app.models.ahu_state import AhuState
from app.models.ahu_log import AhuLog
from app.services.mqtt_service import MqttService

_MAX_LOGS = 70
_DEBOUNCE_TELEMETRY_MS = 250
_DEBOUNCE_STATE_MS = 150
_THROTTLE_NOTIFY_MS = 300


class AppProvider:
    ADMIN_PASSCODE   = "1234"
    DEFAULT_PASSCODE = "123123"

    def __init__(self, root: ctk.CTk):
        self._root = root
        self.is_dark: bool = True

        # ── MQTT ──────────────────────────────────────────────────────────────
        self.mqtt = MqttService()
        self.mqtt.set_callbacks(
            on_message=self._on_mqtt_message,
            on_connect=self._on_connect,
            on_disconnect=self._on_disconnect,
        )
        self.mqtt.connect()

        # ── State ─────────────────────────────────────────────────────────────
        self.is_connected: bool = False
        self.ahu_units: Dict[str, AhuUnit] = {}
        self.telemetry: Dict[str, AhuTelemetry] = {}
        self.state:     Dict[str, AhuState]     = {}
        self.logs:      Dict[str, Deque[AhuLog]] = defaultdict(lambda: deque(maxlen=_MAX_LOGS))
        self.online:    Dict[str, bool]           = {}

        # ── Screen lock ───────────────────────────────────────────────────────
        self.is_screen_locked: bool = True
        self.screen_lock_passcode: str = self.DEFAULT_PASSCODE

        # ── Debounce/throttle bookkeeping ─────────────────────────────────────
        self._pending_telemetry: Dict[str, bool] = {}
        self._pending_state: Dict[str, bool]     = {}
        self._last_notify: float = 0.0

        # ── Listeners: event_name → list[callback] ───────────────────────────
        self._listeners: Dict[str, List[Callable]] = defaultdict(list)

    # ── subscription ──────────────────────────────────────────────────────────

    def subscribe(self, event: str, cb: Callable):
        self._listeners[event].append(cb)

    def unsubscribe(self, event: str, cb: Callable):
        try:
            self._listeners[event].remove(cb)
        except ValueError:
            pass

    def _notify(self, event: str):
        now = time.time() * 1000
        if now - self._last_notify < _THROTTLE_NOTIFY_MS:
            self._root.after(int(_THROTTLE_NOTIFY_MS), lambda: self._notify(event))
            return
        self._last_notify = now
        for cb in list(self._listeners.get(event, [])):
            try:
                cb()
            except Exception:
                pass

    # ── polling (called by App every 100 ms) ──────────────────────────────────

    def poll(self):
        self.mqtt.poll()

    # ── MQTT callbacks (already on main thread via queue+poll) ───────────────

    def _on_connect(self):
        self.is_connected = True
        self._notify("connection")

    def _on_disconnect(self):
        self.is_connected = False
        self._notify("connection")

    def _on_mqtt_message(self, topic: str, payload: str):
        parts = topic.split("/")
        # Expected format: org/ahu/site/room/id/subtopic[/...]
        if len(parts) < 6 or parts[1] != "ahu":
            return

        org   = parts[0]
        site  = parts[2]
        room  = parts[3]
        dev   = parts[4]
        sub   = "/".join(parts[5:])
        key   = f"{dev}|{site}|{room}"

        if sub == "status":
            if "online" in payload.lower():
                self._ensure_registered(org, dev, site, room, key)
                self.online[key] = True
                self._notify("online")
            elif "offline" in payload.lower():
                self.online[key] = False
                self._notify("online")

        elif sub == "telemetry":
            try:
                d = json.loads(payload)
                self._ensure_registered(org, dev, site, room, key)
                self.telemetry[key] = AhuTelemetry.from_dict(d)
                if not self._pending_telemetry.get(key):
                    self._pending_telemetry[key] = True
                    self._root.after(_DEBOUNCE_TELEMETRY_MS,
                                     lambda k=key: self._flush_telemetry(k))
            except Exception:
                pass

        elif sub == "state":
            try:
                d = json.loads(payload)
                self._ensure_registered(org, dev, site, room, key)
                self.state[key] = AhuState.from_dict(d)
                if not self._pending_state.get(key):
                    self._pending_state[key] = True
                    self._root.after(_DEBOUNCE_STATE_MS,
                                     lambda k=key: self._flush_state(k))
            except Exception:
                pass

        elif sub == "log":
            try:
                d = json.loads(payload)
                log = AhuLog.from_dict(d)
            except Exception:
                log = AhuLog(ts=int(time.time() * 1000), lvl="INFO", msg=payload)
            self.logs[key].appendleft(log)
            self._notify("logs")

        elif sub == "aws_status":
            try:
                d = json.loads(payload)
                if key in self.ahu_units:
                    s = self.state.get(key)
                    if s:
                        s.online_mode = bool(d.get("connected", False))
                        self._notify("state")
            except Exception:
                pass

    def _flush_telemetry(self, key: str):
        self._pending_telemetry[key] = False
        self._notify("telemetry")

    def _flush_state(self, key: str):
        self._pending_state[key] = False
        self._notify("state")

    def _ensure_registered(self, org, dev, site, room, key):
        if key not in self.ahu_units:
            # Single-AHU model: clear previous entries when a new device appears
            if self.ahu_units:
                old_keys = list(self.ahu_units.keys())
                for k in old_keys:
                    self.ahu_units.pop(k, None)
                    self.telemetry.pop(k, None)
                    self.state.pop(k, None)
                    self.online.pop(k, None)
                    self.logs.pop(k, None)

            friendly = f"{site.capitalize()} - {room.capitalize()}"
            self.ahu_units[key] = AhuUnit(
                id=dev, name=friendly, site=site, room=room, org=org
            )
            self._notify("units")

    # ── screen lock ───────────────────────────────────────────────────────────

    def unlock_screen(self, passcode: str) -> bool:
        if passcode == self.screen_lock_passcode:
            self.is_screen_locked = False
            self._notify("lock")
            return True
        return False

    def lock_screen(self):
        self.is_screen_locked = True
        self._notify("lock")

    def change_passcode(self, new_passcode: str):
        self.screen_lock_passcode = new_passcode

    # ── commands ──────────────────────────────────────────────────────────────

    def _unit_and_state(self, ahu_key: str):
        unit  = self.ahu_units.get(ahu_key)
        state = self.state.get(ahu_key)
        return unit, state

    def _cmd(self, ahu_key: str, payload: dict):
        unit = self.ahu_units.get(ahu_key)
        if unit:
            self.mqtt.publish(unit.cmd_topic, payload)

    def start_ahu(self, key: str):
        self._cmd(key, {"cmd": "start"})

    def stop_ahu(self, key: str):
        self._cmd(key, {"cmd": "stop"})

    def toggle_ahu(self, key: str):
        self._cmd(key, {"cmd": "toggle"})

    def set_temperature(self, key: str, value: float):
        self._cmd(key, {"cmd": "setpoint", "value": value})

    def set_humidity(self, key: str, value: float):
        self._cmd(key, {"cmd": "humset", "value": value})

    def toggle_fan_speed(self, key: str):
        self._cmd(key, {"cmd": "fanToggle"})

    def set_fan_speed(self, key: str, speed: int):
        self._cmd(key, {"cmd": "fan", "value": speed})

    def set_mode(self, key: str, online: bool):
        self._cmd(key, {"cmd": "mode", "value": "online" if online else "offline"})

    def set_cp_mode(self, key: str, mode: str):
        self._cmd(key, {"cmd": "cpMode", "value": mode})

    def set_cp_active(self, key: str, cp: int):
        self._cmd(key, {"cmd": "cpActive", "value": cp})

    def reset_esp32(self, key: str):
        self._cmd(key, {"cmd": "reset"})

    def provision_wifi(self, key: str, ssid1: str, pass1: str,
                       ssid2: str = "", pass2: str = ""):
        unit = self.ahu_units.get(key)
        if unit:
            payload = {"ssid": ssid1, "pass": pass1}
            if ssid2:
                payload["ssid2"] = ssid2
                payload["pass2"] = pass2
            self.mqtt.publish(unit.prov_wifi_topic, payload)

    def provision_broker(self, key: str, host: str, port: int):
        unit = self.ahu_units.get(key)
        if unit:
            self.mqtt.publish(unit.prov_broker_topic, {"host": host, "port": port})

    def provision_motor_timings(self, key: str, m1_start: int, m1_post: int,
                                m2_interval: int, m2_run: int, m2_delay: int):
        unit = self.ahu_units.get(key)
        if unit:
            payload = {
                "m1Start": m1_start, "m1Post": m1_post,
                "m2Interval": m2_interval, "m2Run": m2_run, "m2Delay": m2_delay,
            }
            self.mqtt.publish(unit.prov_motor_timings_topic, payload)

    # ── helpers ───────────────────────────────────────────────────────────────

    @property
    def first_ahu_key(self) -> Optional[str]:
        keys = list(self.ahu_units.keys())
        return keys[0] if keys else None
