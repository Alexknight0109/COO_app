"""
Thread-safe MQTT service.
Runs the paho-mqtt network loop in a background thread.
Messages are queued and retrieved via poll() on the main thread.
"""
import json
import queue
import threading
import time
from typing import Optional, Callable

import paho.mqtt.client as mqtt


class MqttService:
    # Matches the mDNS hostname the ESP32 uses: mqttHost = "almed-ahu.local"
    # The Pi just needs hostname=almed-ahu + avahi-daemon running.
    DEFAULT_HOST = "almed-ahu.local"
    DEFAULT_PORT = 1883
    DEFAULT_USER = "almed"
    DEFAULT_PASS = "Almed1234$"
    WILDCARD_TOPIC = "almed/ahu/#"

    # Connection fallbacks (important on Pi if mDNS isn't ready yet).
    # ESP32 uses almed-ahu.local; the dashboard should still work locally via localhost.
    DEFAULT_HOST_FALLBACKS = ("almed-ahu.local", "localhost", "127.0.0.1")

    def __init__(self):
        self._queue: queue.Queue = queue.Queue()
        self._client: Optional[mqtt.Client] = None
        self._thread: Optional[threading.Thread] = None
        self._connected = False
        self._host = self.DEFAULT_HOST
        self._port = self.DEFAULT_PORT
        self._stop_event = threading.Event()

        # Callbacks invoked on main thread via poll()
        self._on_message_cb: Optional[Callable] = None
        self._on_connect_cb: Optional[Callable] = None
        self._on_disconnect_cb: Optional[Callable] = None

    # ── public API ────────────────────────────────────────────────────────────

    def set_callbacks(self, on_message=None, on_connect=None, on_disconnect=None):
        self._on_message_cb = on_message
        self._on_connect_cb = on_connect
        self._on_disconnect_cb = on_disconnect

    def connect(self, host: str = DEFAULT_HOST, port: int = DEFAULT_PORT,
                user: str = DEFAULT_USER, password: str = DEFAULT_PASS):
        self.disconnect()
        self._host = host
        self._port = port
        # If caller passes default host, try a small ordered fallback list.
        # If caller passes a specific host (e.g., from Admin screen), use only that.
        hosts = [host] if host and host != self.DEFAULT_HOST else list(self.DEFAULT_HOST_FALLBACKS)
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run_loop,
            args=(hosts, port, user, password),
            daemon=True,
            name="mqtt-loop",
        )
        self._thread.start()

    def disconnect(self):
        self._stop_event.set()
        if self._client:
            try:
                self._client.disconnect()
                self._client.loop_stop()
            except Exception:
                pass
            self._client = None
        self._connected = False

    @property
    def is_connected(self) -> bool:
        return self._connected

    def poll(self):
        """Call from the main (tkinter) thread to dispatch queued events."""
        while True:
            try:
                event_type, data = self._queue.get_nowait()
            except queue.Empty:
                break
            if event_type == "connect" and self._on_connect_cb:
                self._on_connect_cb()
            elif event_type == "disconnect" and self._on_disconnect_cb:
                self._on_disconnect_cb()
            elif event_type == "message" and self._on_message_cb:
                self._on_message_cb(data["topic"], data["payload"])

    def publish(self, topic: str, payload, retain: bool = False):
        if not self._client or not self._connected:
            return
        msg = json.dumps(payload) if isinstance(payload, dict) else str(payload)
        try:
            self._client.publish(topic, msg, retain=retain)
        except Exception:
            pass

    # ── internal ──────────────────────────────────────────────────────────────

    def _run_loop(self, hosts, port, user, password):
        # Support paho-mqtt 1.x and 2.x
        if hasattr(mqtt, "CallbackAPIVersion"):
            client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        else:
            client = mqtt.Client()

        client.username_pw_set(user, password)
        client.on_connect    = self._cb_connect
        client.on_disconnect = self._cb_disconnect
        client.on_message    = self._cb_message

        backoff = 1.0
        while not self._stop_event.is_set():
            for host in hosts:
                if self._stop_event.is_set():
                    break
                try:
                    client.connect(host, port, keepalive=60)
                    self._client = client
                    client.loop_start()
                    return
                except Exception:
                    continue
            # No host worked; wait and retry.
            time.sleep(backoff)
            backoff = min(5.0, backoff + 1.0)

        # stop requested
        try:
            client.loop_stop()
            client.disconnect()
        except Exception:
            pass

    def _cb_connect(self, client, userdata, flags, reason_code, *args):
        # paho-mqtt 1.x passes an int rc.
        # paho-mqtt 2.x may pass a ReasonCode object (has `.value`).
        try:
            if isinstance(reason_code, int):
                rc = reason_code
            elif hasattr(reason_code, "value"):
                rc = int(reason_code.value)
            else:
                rc = int(reason_code)
        except Exception:
            rc = 1

        if rc == 0:
            self._connected = True
            client.subscribe(self.WILDCARD_TOPIC, qos=1)
            self._queue.put(("connect", {}))
        else:
            self._connected = False

    def _cb_disconnect(self, client, userdata, *args):
        self._connected = False
        self._queue.put(("disconnect", {}))

    def _cb_message(self, client, userdata, msg):
        try:
            payload_raw = msg.payload.decode("utf-8", errors="replace")
        except Exception:
            payload_raw = ""
        self._queue.put(("message", {"topic": msg.topic, "payload": payload_raw}))
