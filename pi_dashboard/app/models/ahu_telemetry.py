from dataclasses import dataclass, field
from typing import Optional


# HEPA differential-pressure thresholds per fan speed (Pa)
_HEPA_NORMAL = {1: (40, 55), 2: (60, 90), 3: (90, 110)}
_HEPA_REPLACE = {1: 75, 2: 120, 3: 140}

_AQI_CATEGORIES = [
    (0,   50,  "Good",            "#10B981"),
    (51,  100, "Moderate",        "#F59E0B"),
    (101, 150, "Unhealthy (Sens)","#F97316"),
    (151, 200, "Unhealthy",       "#EF4444"),
    (201, 300, "Very Unhealthy",  "#8B5CF6"),
    (301, 500, "Hazardous",       "#7F1D1D"),
]


@dataclass
class AhuTelemetry:
    temp: float = 0.0
    hum: float = 0.0
    m1: bool = False
    m2: bool = False
    run: bool = False
    cp: bool = False
    heater: bool = False
    fan: bool = False
    fan_speed: int = 0          # 0-3
    temp_set: float = 24.0
    hum_set: float = 55.0
    ts: int = 0

    # Optional combo-sensor fields
    sensor_type: Optional[str] = None
    aqi: Optional[float] = None
    pm1p0: Optional[float] = None
    pm2p5: Optional[float] = None
    pm4p0: Optional[float] = None
    pm10p0: Optional[float] = None
    voc: Optional[float] = None
    nox: Optional[float] = None
    co2: Optional[float] = None
    diff_pressure: Optional[float] = None
    hepa_status: Optional[str] = None
    hepa_health: Optional[float] = None

    @property
    def is_combo_sensor(self) -> bool:
        return self.sensor_type is not None

    @property
    def has_air_quality_data(self) -> bool:
        return self.pm2p5 is not None or self.co2 is not None

    @property
    def has_hepa_data(self) -> bool:
        return self.diff_pressure is not None

    @property
    def fan_speed_display(self) -> str:
        return ["OFF", "LOW", "MED", "HIGH"][self.fan_speed] if 0 <= self.fan_speed <= 3 else "?"

    @property
    def calculated_hepa_health(self) -> float:
        if self.diff_pressure is None or self.fan_speed == 0:
            return 100.0
        normal_range = _HEPA_NORMAL.get(self.fan_speed, (60, 90))
        replace_thresh = _HEPA_REPLACE.get(self.fan_speed, 120)
        dp = self.diff_pressure
        mid = (normal_range[0] + normal_range[1]) / 2
        if dp <= mid:
            return 100.0
        elif dp >= replace_thresh:
            return 0.0
        else:
            health = 1.0 - (dp - mid) / (replace_thresh - mid)
            return max(0.0, min(100.0, health * 100))

    @property
    def calculated_hepa_status(self) -> str:
        if self.diff_pressure is None or self.fan_speed == 0:
            return "Fan Off"
        h = self.calculated_hepa_health
        if h > 70:
            return "Normal"
        elif h > 40:
            return "Clogging"
        elif h > 10:
            return "Replace Required"
        else:
            return "Weak Airflow/Leak"

    @property
    def aqi_category(self) -> tuple:
        if self.aqi is None:
            return ("Unknown", "#94A3B8")
        v = int(self.aqi)
        for lo, hi, label, color in _AQI_CATEGORIES:
            if lo <= v <= hi:
                return (label, color)
        return ("Hazardous", "#7F1D1D")

    @property
    def co2_level(self) -> str:
        if self.co2 is None:
            return "N/A"
        v = self.co2
        if v < 400:   return "Fresh"
        if v < 1000:  return "Good"
        if v < 2000:  return "Moderate"
        return "High"

    @classmethod
    def from_dict(cls, d: dict) -> "AhuTelemetry":
        def g(key, alt=None):
            return d.get(key, alt)

        fan_speed = g("fanSpeed", g("fan_speed", 0))
        try:
            fan_speed = int(fan_speed)
        except (TypeError, ValueError):
            fan_speed = 0

        return cls(
            temp=float(g("temp", 0)),
            hum=float(g("hum", 0)),
            m1=bool(g("m1", False)),
            m2=bool(g("m2", False)),
            run=bool(g("run", False)),
            cp=bool(g("cp", False)),
            heater=bool(g("heater", False)),
            fan=bool(g("fan", False)),
            fan_speed=fan_speed,
            temp_set=float(g("tempSet", g("temp_set", 24.0))),
            hum_set=float(g("humSet", g("hum_set", 55.0))),
            ts=int(g("ts", 0)),
            sensor_type=g("sensorType") or g("sensor_type"),
            aqi=_float(g("aqi")),
            pm1p0=_float(g("pm1p0")),
            pm2p5=_float(g("pm2p5")),
            pm4p0=_float(g("pm4p0")),
            pm10p0=_float(g("pm10p0")),
            voc=_float(g("voc")),
            nox=_float(g("nox")),
            co2=_float(g("co2")),
            diff_pressure=_float(g("diffPressure") or g("diff_pressure")),
            hepa_status=g("hepaStatus") or g("hepa_status"),
            hepa_health=_float(g("hepaHealth") or g("hepa_health")),
        )


def _float(v) -> Optional[float]:
    try:
        return float(v) if v is not None else None
    except (TypeError, ValueError):
        return None
