from dataclasses import dataclass, field


@dataclass
class AhuUnit:
    id: str
    name: str
    site: str
    room: str
    org: str = "almed"

    @property
    def base_topic(self) -> str:
        return f"{self.org}/ahu/{self.site}/{self.room}/{self.id}"

    @property
    def telemetry_topic(self) -> str:
        return f"{self.base_topic}/telemetry"

    @property
    def state_topic(self) -> str:
        return f"{self.base_topic}/state"

    @property
    def log_topic(self) -> str:
        return f"{self.base_topic}/log"

    @property
    def cmd_topic(self) -> str:
        return f"{self.base_topic}/cmd"

    @property
    def status_topic(self) -> str:
        return f"{self.base_topic}/status"

    @property
    def prov_wifi_topic(self) -> str:
        return f"{self.base_topic}/provision/wifi"

    @property
    def prov_broker_topic(self) -> str:
        return f"{self.base_topic}/provision/broker"

    @property
    def prov_motor_timings_topic(self) -> str:
        return f"{self.base_topic}/provision/motor_timings"

    @property
    def prov_ack_topic(self) -> str:
        return f"{self.base_topic}/provision/ack"
