from dataclasses import dataclass
from typing import Optional


@dataclass
class AhuState:
    run: bool = False
    m1: bool = False
    m2: bool = False
    cp: bool = False
    cp2: Optional[bool] = None
    cp_mode: str = "single"        # "dual" | "single"
    cp_active: int = 1             # 1 | 2
    heater: bool = False
    fan: bool = False
    fan_speed: int = 0
    temp_set: float = 24.0
    hum_set: float = 55.0
    ip: str = ""
    online_mode: bool = True
    version: Optional[str] = None
    m1_start: int = 30
    m1_post: int = 10
    m2_interval: int = 3600
    m2_run: int = 30
    m2_delay: int = 5

    @property
    def m2_wait_time(self) -> int:
        return max(0, self.m2_interval - self.m2_run)

    @classmethod
    def from_dict(cls, d: dict) -> "AhuState":
        def g(key, alt=None):
            return d.get(key, alt)

        fan_speed = g("fanSpeed", g("fan_speed", 0))
        try:
            fan_speed = int(fan_speed)
        except (TypeError, ValueError):
            fan_speed = 0

        return cls(
            run=bool(g("run", False)),
            m1=bool(g("m1", False)),
            m2=bool(g("m2", False)),
            cp=bool(g("cp", False)),
            cp2=_optional_bool(g("cp2")),
            cp_mode=g("cpMode", g("cp_mode", "single")) or "single",
            cp_active=int(g("cpActive", g("cp_active", 1)) or 1),
            heater=bool(g("heater", False)),
            fan=bool(g("fan", False)),
            fan_speed=fan_speed,
            temp_set=float(g("tempSet", g("temp_set", 24.0))),
            hum_set=float(g("humSet", g("hum_set", 55.0))),
            ip=str(g("ip", "") or ""),
            online_mode=bool(g("onlineMode", g("online_mode", True))),
            version=g("version"),
            m1_start=int(g("m1Start", g("m1_start", 30)) or 30),
            m1_post=int(g("m1Post", g("m1_post", 10)) or 10),
            m2_interval=int(g("m2Interval", g("m2_interval", 3600)) or 3600),
            m2_run=int(g("m2Run", g("m2_run", 30)) or 30),
            m2_delay=int(g("m2Delay", g("m2_delay", 5)) or 5),
        )


def _optional_bool(v) -> Optional[bool]:
    if v is None:
        return None
    return bool(v)
