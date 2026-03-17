from dataclasses import dataclass


@dataclass
class AhuLog:
    ts: int       # epoch millis or uptime millis
    lvl: str      # "INFO" | "WARN" | "ERROR"
    msg: str

    @property
    def formatted_time(self) -> str:
        secs = (self.ts // 1000) % 86400
        h = secs // 3600
        m = (secs % 3600) // 60
        s = secs % 60
        return f"{h:02d}:{m:02d}:{s:02d}"

    @classmethod
    def from_dict(cls, d: dict) -> "AhuLog":
        return cls(
            ts=int(d.get("ts", 0)),
            lvl=str(d.get("lvl", "INFO")).upper(),
            msg=str(d.get("msg", "")),
        )
