# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  mqtt_client.py
#
#  Mirrors the MQTT logic from eco_display.ino:
#    • Subscribes to almed/ahu/#
#    • Parses /status, /state, /telemetry topics
#    • Auto-discovers AHU devices from retained messages
#    • Prunes stale devices after DEVICE_STALE_S
#    • Publishes setpoint / humset / toggle commands
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import json
import time
import threading
import logging
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Callable
import paho.mqtt.client as mqtt

import config

log = logging.getLogger(__name__)


@dataclass
class AhuDevice:
    site:       str
    room:       str
    ahu:        str
    thing_name: str  = ""
    ip:         str  = ""
    run:        bool = False
    temp:       Optional[float] = None
    hum:        Optional[float] = None
    temp_set:   float = 22.0
    hum_set:    float = 55.0
    last_seen:  float = field(default_factory=time.monotonic)

    @property
    def display_name(self) -> str:
        return self.thing_name if self.thing_name else f"{self.ahu}"

    @property
    def sub_label(self) -> str:
        return f"{self.site} / {self.room} / {self.ahu}"

    @property
    def cmd_topic(self) -> str:
        return f"almed/ahu/{self.site}/{self.room}/{self.ahu}/cmd"

    @property
    def unique_key(self) -> str:
        return f"{self.site}|{self.room}|{self.ahu}"


class MqttClient:
    """
    Thread-safe MQTT client for the Pi Eco Display.

    Callback hooks (set these before calling connect()):
      on_devices_changed  – called whenever device list changes
      on_telemetry        – called with AhuDevice when telemetry arrives
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._devices: Dict[str, AhuDevice] = {}   # key = unique_key
        self._client: Optional[mqtt.Client] = None
        self._connected = False
        self._last_retry = 0.0

        # Callbacks – set by the application layer
        self.on_devices_changed: Optional[Callable[[], None]] = None
        self.on_telemetry:        Optional[Callable[[AhuDevice], None]] = None

    # ── Public API ────────────────────────────────────────────────────────────

    @property
    def is_connected(self) -> bool:
        return self._connected

    def connect(self) -> None:
        """Start background MQTT connection (non-blocking)."""
        self._start_client()

    def tick(self) -> None:
        """Call from main loop – handles reconnect, prune stale devices."""
        now = time.monotonic()
        if not self._connected and (now - self._last_retry) > config.MQTT_RETRY_S:
            self._last_retry = now
            log.info("MQTT: Retrying connection …")
            self._start_client()
        self._prune_stale()

    @property
    def devices(self) -> List[AhuDevice]:
        with self._lock:
            return list(self._devices.values())

    def send_temp_set(self, device: AhuDevice, value: float) -> bool:
        return self._publish(device.cmd_topic, json.dumps({"setpoint": round(value, 1)}))

    def send_hum_set(self, device: AhuDevice, value: float) -> bool:
        return self._publish(device.cmd_topic, json.dumps({"humset": round(value, 1)}))

    def send_toggle(self, device: AhuDevice) -> bool:
        return self._publish(device.cmd_topic, json.dumps({"toggle": True}))

    def disconnect(self) -> None:
        if self._client:
            self._client.disconnect()

    # ── Internal ──────────────────────────────────────────────────────────────

    def _start_client(self) -> None:
        if self._client:
            try:
                self._client.disconnect()
            except Exception:
                pass

        client = mqtt.Client(
            client_id=config.MQTT_CLIENT,
            clean_session=True,
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        )
        client.username_pw_set(config.MQTT_USER, config.MQTT_PASS)
        client.will_set("almed/eco_display/status", "offline", retain=True)
        client.on_connect    = self._on_connect
        client.on_disconnect = self._on_disconnect
        client.on_message    = self._on_message

        try:
            client.connect_async(config.MQTT_BROKER, config.MQTT_PORT, keepalive=60)
            client.loop_start()
            self._client = client
        except Exception as exc:
            log.warning("MQTT connect error: %s", exc)

    def _on_connect(self, client, userdata, flags, reason_code, properties=None) -> None:
        if reason_code == 0:
            self._connected = True
            log.info("MQTT: Connected to %s:%d", config.MQTT_BROKER, config.MQTT_PORT)
            client.subscribe("almed/ahu/#", qos=1)
            client.publish("almed/eco_display/status", "online", retain=True)
        else:
            self._connected = False
            log.warning("MQTT: Connect refused rc=%s", reason_code)

    def _on_disconnect(self, client, userdata, disconnect_flags, reason_code, properties=None) -> None:
        self._connected = False
        log.info("MQTT: Disconnected rc=%s", reason_code)

    def _on_message(self, client, userdata, msg: mqtt.MQTTMessage) -> None:
        topic   = msg.topic
        payload = msg.payload.decode("utf-8", errors="replace").strip()

        parts = topic.split("/")
        # Expected: almed/ahu/{site}/{room}/{ahu}/{subtopic}
        if len(parts) < 6:
            return

        site, room, ahu_id, subtopic = parts[2], parts[3], parts[4], parts[5]

        if subtopic == "status":
            self._process_status(site, room, ahu_id)
        elif subtopic == "state":
            self._process_state(site, room, ahu_id, payload)
        elif subtopic == "telemetry":
            self._process_telemetry(site, room, ahu_id, payload)

    def _process_status(self, site: str, room: str, ahu_id: str) -> None:
        dev = self._find_or_add(site, room, ahu_id)
        if dev:
            dev.last_seen = time.monotonic()
            self._notify_devices_changed()

    def _process_state(self, site: str, room: str, ahu_id: str, payload: str) -> None:
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            return

        dev = self._find_or_add(site, room, ahu_id)
        if not dev:
            return

        if "thing"   in data: dev.thing_name = data["thing"]
        if "ip"      in data: dev.ip         = data["ip"]
        if "run"     in data: dev.run        = bool(data["run"])
        if "tempSet" in data: dev.temp_set   = float(data["tempSet"])
        if "humSet"  in data: dev.hum_set    = float(data["humSet"])
        dev.last_seen = time.monotonic()
        self._notify_devices_changed()

    def _process_telemetry(self, site: str, room: str, ahu_id: str, payload: str) -> None:
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            return

        dev = self._find_or_add(site, room, ahu_id)
        if not dev:
            return

        if "temp"    in data: dev.temp     = float(data["temp"])
        if "hum"     in data: dev.hum      = float(data["hum"])
        if "run"     in data: dev.run      = bool(data["run"])
        if "tempSet" in data: dev.temp_set = float(data["tempSet"])
        if "humSet"  in data: dev.hum_set  = float(data["humSet"])
        dev.last_seen = time.monotonic()

        if self.on_telemetry:
            self.on_telemetry(dev)

    def _find_or_add(self, site: str, room: str, ahu_id: str) -> Optional[AhuDevice]:
        if not site or not ahu_id:
            return None
        key = f"{site}|{room}|{ahu_id}"
        with self._lock:
            if key not in self._devices:
                self._devices[key] = AhuDevice(site=site, room=room, ahu=ahu_id)
                log.info("MQTT: Discovered %s", key)
            return self._devices[key]

    def _prune_stale(self) -> None:
        now = time.monotonic()
        with self._lock:
            stale = [k for k, d in self._devices.items()
                     if now - d.last_seen > config.DEVICE_STALE_S]
        if stale:
            with self._lock:
                for k in stale:
                    log.info("MQTT: Pruning stale device %s", k)
                    del self._devices[k]
            self._notify_devices_changed()

    def _publish(self, topic: str, payload: str) -> bool:
        if not self._connected or not self._client:
            log.warning("MQTT: Cannot publish – not connected")
            return False
        result = self._client.publish(topic, payload, qos=1)
        log.debug("MQTT publish → %s : %s", topic, payload)
        return result.rc == mqtt.MQTT_ERR_SUCCESS

    def _notify_devices_changed(self) -> None:
        if self.on_devices_changed:
            self.on_devices_changed()
