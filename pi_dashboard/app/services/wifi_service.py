"""
WiFi management via nmcli (Linux / Raspberry Pi only).
"""
import subprocess
import shutil
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class WiFiNetwork:
    ssid: str
    security: str
    signal: int         # 0-100
    is_connected: bool
    bssid: str = ""

    @property
    def signal_bars(self) -> int:
        if self.signal >= 70: return 3
        if self.signal >= 40: return 2
        return 1


class WiFiService:
    _instance: Optional["WiFiService"] = None

    @classmethod
    def get(cls) -> "WiFiService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def is_available(self) -> bool:
        return shutil.which("nmcli") is not None

    def scan_networks(self) -> List[WiFiNetwork]:
        if not self.is_available():
            return []
        try:
            subprocess.run(
                ["nmcli", "device", "wifi", "rescan"],
                capture_output=True, timeout=10,
            )
        except Exception:
            pass

        try:
            result = subprocess.run(
                ["nmcli", "-t", "-f",
                 "SSID,SIGNAL,SECURITY,BSSID,IN-USE",
                 "device", "wifi", "list"],
                capture_output=True, text=True, timeout=15,
            )
            lines = result.stdout.strip().splitlines()
        except Exception:
            return []

        seen: set = set()
        networks: List[WiFiNetwork] = []
        connected_ssid = self._connected_ssid()

        for line in lines:
            parts = line.split(":")
            if len(parts) < 4:
                continue
            ssid    = parts[0].strip()
            signal  = int(parts[1]) if parts[1].isdigit() else 0
            security = parts[2].strip() or "Open"
            bssid   = parts[3].strip() if len(parts) > 3 else ""
            in_use  = len(parts) > 4 and parts[4].strip() == "*"

            if not ssid or ssid in seen:
                continue
            seen.add(ssid)
            networks.append(WiFiNetwork(
                ssid=ssid,
                security=security,
                signal=signal,
                is_connected=in_use or (ssid == connected_ssid),
                bssid=bssid,
            ))

        networks.sort(key=lambda n: (not n.is_connected, -n.signal))
        return networks

    def _connected_ssid(self) -> str:
        try:
            r = subprocess.run(
                ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show", "--active"],
                capture_output=True, text=True, timeout=5,
            )
            for line in r.stdout.splitlines():
                parts = line.split(":")
                if len(parts) >= 3 and "wifi" in parts[1] and "activated" in parts[2]:
                    return parts[0]
        except Exception:
            pass
        return ""

    def connect(self, ssid: str, password: str) -> bool:
        if not self.is_available():
            return False
        try:
            subprocess.run(
                ["nmcli", "connection", "delete", ssid],
                capture_output=True, timeout=10,
            )
        except Exception:
            pass
        try:
            result = subprocess.run(
                ["nmcli", "device", "wifi", "connect", ssid, "password", password],
                capture_output=True, text=True, timeout=30,
            )
            return result.returncode == 0
        except Exception:
            return False

    def connect_open(self, ssid: str) -> bool:
        if not self.is_available():
            return False
        try:
            result = subprocess.run(
                ["nmcli", "device", "wifi", "connect", ssid],
                capture_output=True, text=True, timeout=30,
            )
            return result.returncode == 0
        except Exception:
            return False

    def disconnect(self) -> bool:
        if not self.is_available():
            return False
        try:
            result = subprocess.run(
                ["nmcli", "device", "disconnect", "wlan0"],
                capture_output=True, timeout=15,
            )
            return result.returncode == 0
        except Exception:
            return False
