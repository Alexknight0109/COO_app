"""
Dashboard screen – shows all discovered AHU units as live cards.
"""
import customtkinter as ctk
from app.theme import T, SUCCESS, ERROR, TEMP_COL, HUM_COL, font


class DashboardScreen(ctk.CTkFrame):
    def __init__(self, parent, app, role: str = "hospital", **kwargs):
        super().__init__(parent, fg_color=T("bg"), corner_radius=0, **kwargs)
        self._app    = app
        self._role   = role
        self._provider = app.provider
        self._card_frames: dict = {}
        self._build()
        self._subscribe()

    def on_theme_changed(self):
        for w in self.winfo_children():
            w.destroy()
        self._card_frames.clear()
        self.configure(fg_color=T("bg"))
        self._build()
        self._subscribe()

    def destroy(self):
        self._unsubscribe()
        super().destroy()

    # ── subscriptions ─────────────────────────────────────────────────────────

    def _subscribe(self):
        self._provider.subscribe("units",      self._refresh_cards)
        self._provider.subscribe("telemetry",  self._update_cards)
        self._provider.subscribe("state",      self._update_cards)
        self._provider.subscribe("online",     self._update_cards)
        self._provider.subscribe("connection", self._update_connection)

    def _unsubscribe(self):
        for ev in ("units", "telemetry", "state", "online", "connection"):
            self._provider.unsubscribe(ev, getattr(self, f"_{'refresh_cards' if ev == 'units' else ('update_connection' if ev == 'connection' else 'update_cards')}"))

    # ── layout ────────────────────────────────────────────────────────────────

    def _build(self):
        # ── top bar ──────────────────────────────────────────────────────────
        topbar = ctk.CTkFrame(self, fg_color=T("topbar"), corner_radius=0,
                              height=58, border_width=0)
        topbar.pack(fill="x")
        topbar.pack_propagate(False)

        left = ctk.CTkFrame(topbar, fg_color="transparent")
        left.pack(side="left", padx=16, fill="y")

        ctk.CTkLabel(left, text="ALMED",
                     font=("Helvetica", 22, "bold"), text_color="#3B82F6").pack(
            side="left", pady=12)
        ctk.CTkFrame(left, fg_color=T("border"), width=1).pack(
            side="left", fill="y", padx=12, pady=10)
        ctk.CTkLabel(left, text="Dashboard",
                     font=font(16, "bold"), text_color=T("text")).pack(side="left")

        right = ctk.CTkFrame(topbar, fg_color="transparent")
        right.pack(side="right", padx=12, fill="y")

        # connection dot
        self._conn_dot = ctk.CTkFrame(right, fg_color=ERROR,
                                      width=10, height=10, corner_radius=5)
        self._conn_dot.pack_propagate(False)
        self._conn_dot.pack(side="left", padx=(0, 8), pady=24)
        self._update_connection()

        # admin settings gear
        if self._role == "admin":
            ctk.CTkButton(right, text="⚙", width=40, height=40,
                          font=font(18), fg_color="transparent",
                          text_color=T("text_sec"), hover_color=T("surface2"),
                          corner_radius=20,
                          command=self._app.show_admin_settings).pack(
                side="left", padx=4)

        # theme toggle
        is_dark = ctk.get_appearance_mode() == "Dark"
        ctk.CTkButton(right, text="☀" if is_dark else "🌙",
                      width=40, height=40, corner_radius=20,
                      font=font(16), fg_color="transparent",
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      command=self._app.toggle_theme).pack(side="left", padx=4)

        # logout
        ctk.CTkButton(right, text="⏻", width=40, height=40,
                      corner_radius=20, font=font(16),
                      fg_color="transparent",
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      command=self._app.show_login).pack(side="left", padx=4)

        # divider
        ctk.CTkFrame(self, fg_color=T("border"), height=1).pack(fill="x")

        # ── scrollable card area ──────────────────────────────────────────────
        self._scroll = ctk.CTkScrollableFrame(self, fg_color=T("bg"))
        self._scroll.pack(fill="both", expand=True, padx=0, pady=0)
        self._refresh_cards()

    # ── card management ───────────────────────────────────────────────────────

    def _refresh_cards(self):
        units = self._provider.ahu_units
        existing_keys = set(self._card_frames.keys())
        current_keys  = set(units.keys())

        # remove cards for gone units
        for k in existing_keys - current_keys:
            self._card_frames[k].destroy()
            del self._card_frames[k]

        # add cards for new units
        for k in current_keys - existing_keys:
            card = _AhuCard(self._scroll, key=k, screen=self)
            card.pack(padx=20, pady=12, fill="x")
            self._card_frames[k] = card

        # empty state
        if not units:
            self._show_empty()
        else:
            self._hide_empty()

        self._update_cards()

    def _update_cards(self):
        for key, card in self._card_frames.items():
            card.update_data(
                telemetry=self._provider.telemetry.get(key),
                state=self._provider.state.get(key),
                online=self._provider.online.get(key, False),
                unit=self._provider.ahu_units.get(key),
            )

    def _update_connection(self):
        color = SUCCESS if self._provider.is_connected else ERROR
        self._conn_dot.configure(fg_color=color)

    def _show_empty(self):
        if hasattr(self, "_empty_lbl"):
            return
        self._empty_frame = ctk.CTkFrame(self._scroll, fg_color="transparent")
        self._empty_frame.pack(expand=True, fill="both", pady=80)
        ctk.CTkLabel(self._empty_frame, text="💨",
                     font=font(56), text_color=T("text_sec")).pack()
        ctk.CTkLabel(self._empty_frame, text="No AHU units detected",
                     font=font(18, "bold"), text_color=T("text_sec")).pack(pady=8)
        ctk.CTkLabel(self._empty_frame,
                     text="Waiting for AHU units to come online via MQTT…",
                     font=font(13), text_color=T("text_sec")).pack()
        self._empty_lbl = True

    def _hide_empty(self):
        if hasattr(self, "_empty_frame"):
            self._empty_frame.destroy()
            del self._empty_frame
            del self._empty_lbl

    # ── navigation ───────────────────────────────────────────────────────────

    def open_ahu(self, key: str):
        self._app.show_ahu_control(key)


# ── AHU card widget ───────────────────────────────────────────────────────────

class _AhuCard(ctk.CTkFrame):
    def __init__(self, parent, key: str, screen: DashboardScreen, **kwargs):
        super().__init__(parent,
                         fg_color=T("card"),
                         corner_radius=20,
                         border_width=1,
                         border_color=T("card_border"),
                         **kwargs)
        self._key    = key
        self._screen = screen
        self._build()

        # entire card is clickable
        self.bind("<Button-1>", self._on_click)
        for child in self.winfo_children():
            child.bind("<Button-1>", self._on_click)

    def _on_click(self, _=None):
        self._screen.open_ahu(self._key)

    def _build(self):
        self._inner = ctk.CTkFrame(self, fg_color="transparent")
        self._inner.pack(fill="both", expand=True, padx=20, pady=16)

        # ── header row ────────────────────────────────────────────────────────
        header = ctk.CTkFrame(self._inner, fg_color="transparent")
        header.pack(fill="x")

        title_col = ctk.CTkFrame(header, fg_color="transparent")
        title_col.pack(side="left", fill="x", expand=True)
        self._name_lbl = ctk.CTkLabel(title_col, text="AHU Unit",
                                       font=font(17, "bold"), text_color=T("text"),
                                       anchor="w")
        self._name_lbl.pack(fill="x")
        self._meta_lbl = ctk.CTkLabel(title_col, text="",
                                       font=font(12), text_color=T("text_sec"),
                                       anchor="w")
        self._meta_lbl.pack(fill="x")

        # online pill
        self._pill = ctk.CTkFrame(header, fg_color="#064E3B",
                                  corner_radius=10, width=90, height=26)
        self._pill.pack_propagate(False)
        self._pill.pack(side="right", pady=4)
        self._pill_dot = ctk.CTkFrame(self._pill, fg_color=SUCCESS,
                                      width=8, height=8, corner_radius=4)
        self._pill_dot.pack_propagate(False)
        self._pill_lbl = ctk.CTkLabel(self._pill, text="OFFLINE",
                                      font=font(11, "bold"),
                                      text_color="#6B7280")
        self._pill_dot.pack(side="left", padx=(8, 4), pady=9)
        self._pill_lbl.pack(side="left")

        # ── divider ───────────────────────────────────────────────────────────
        ctk.CTkFrame(self._inner, fg_color=T("border"), height=1).pack(
            fill="x", pady=10)

        # ── sensor row ────────────────────────────────────────────────────────
        sensor_row = ctk.CTkFrame(self._inner, fg_color="transparent")
        sensor_row.pack(fill="x")
        sensor_row.columnconfigure(0, weight=1)
        sensor_row.columnconfigure(1, weight=1)

        self._temp_tile = _SensorTile(sensor_row, icon="🌡", label="TEMPERATURE",
                                      unit="°C", color=TEMP_COL)
        self._temp_tile.grid(row=0, column=0, padx=(0, 6), sticky="nsew")

        self._hum_tile = _SensorTile(sensor_row, icon="💧", label="HUMIDITY",
                                     unit="%RH", color=HUM_COL)
        self._hum_tile.grid(row=0, column=1, padx=(6, 0), sticky="nsew")

        # ── status chips ─────────────────────────────────────────────────────
        self._chips_row = ctk.CTkFrame(self._inner, fg_color="transparent")
        self._chips_row.pack(fill="x", pady=(10, 0))

    def update_data(self, telemetry, state, online: bool, unit):
        if unit:
            self._name_lbl.configure(text=unit.name)
            self._meta_lbl.configure(text=f"{unit.room.upper()} • {unit.site.upper()}")

        # online pill
        if online:
            self._pill.configure(fg_color="#064E3B")
            self._pill_dot.configure(fg_color=SUCCESS)
            self._pill_lbl.configure(text="ONLINE", text_color=SUCCESS)
        else:
            self._pill.configure(fg_color=T("surface2"))
            self._pill_dot.configure(fg_color="#6B7280")
            self._pill_lbl.configure(text="OFFLINE", text_color="#6B7280")

        # sensor values
        t = telemetry
        if t:
            self._temp_tile.set_value(f"{t.temp:.1f}", f"→ {t.temp_set:.1f}°C")
            self._hum_tile.set_value(f"{t.hum:.1f}", f"→ {t.hum_set:.1f}%")
        else:
            self._temp_tile.set_value("--.-", "")
            self._hum_tile.set_value("--.-", "")

        # status chips
        for w in self._chips_row.winfo_children():
            w.destroy()

        src = t or state
        if src:
            chips_data = [
                ("Running",  src.run,   SUCCESS),
                ("CP",       src.cp,    "#3B82F6"),
                ("Heater",   src.heater,"#F59E0B"),
            ]
            if t:
                fan_label = t.fan_speed_display
                chips_data.append((f"Fan {fan_label}", src.fan or src.fan_speed > 0, SUCCESS))

            for label, active, color in chips_data:
                _Chip(self._chips_row, label, active, color).pack(side="left", padx=3)

        # open arrow hint
        ctk.CTkLabel(self._chips_row, text="›",
                     font=font(22, "bold"), text_color=T("text_sec")).pack(
            side="right")


class _SensorTile(ctk.CTkFrame):
    def __init__(self, parent, icon, label, unit, color, **kwargs):
        super().__init__(parent,
                         fg_color=_tint(color, 0.12),
                         corner_radius=14,
                         border_width=1,
                         border_color=_tint(color, 0.25),
                         **kwargs)
        self._color = color
        self._unit  = unit

        inner = ctk.CTkFrame(self, fg_color="transparent")
        inner.pack(fill="both", expand=True, padx=12, pady=10)

        top = ctk.CTkFrame(inner, fg_color="transparent")
        top.pack(fill="x")
        ctk.CTkLabel(top, text=icon, font=font(20), text_color=color).pack(side="left")
        ctk.CTkLabel(top, text=label, font=font(10, "bold"),
                     text_color=color).pack(side="left", padx=4)

        self._val_lbl = ctk.CTkLabel(inner, text="--.-",
                                     font=font(26, "bold"), text_color=color)
        self._val_lbl.pack(anchor="w")
        self._unit_lbl = ctk.CTkLabel(inner, text=unit,
                                      font=font(11), text_color=color)
        self._unit_lbl.pack(anchor="w")
        self._set_lbl = ctk.CTkLabel(inner, text="",
                                     font=font(11), text_color=T("text_sec"))
        self._set_lbl.pack(anchor="w")

    def set_value(self, value: str, setpoint: str):
        self._val_lbl.configure(text=value)
        self._set_lbl.configure(text=setpoint)


class _Chip(ctk.CTkFrame):
    def __init__(self, parent, label: str, active: bool, color: str, **kwargs):
        bg = _tint(color, 0.15) if active else "transparent"
        border = color if active else T("border")
        super().__init__(parent, fg_color=bg, corner_radius=8,
                         border_width=1, border_color=border,
                         height=24, **kwargs)
        tc = color if active else T("text_sec")
        ctk.CTkLabel(self, text=label, font=font(11, "bold"),
                     text_color=tc).pack(padx=8, pady=2)


def _tint(hex_col: str, alpha: float) -> str:
    is_dark = ctk.get_appearance_mode() == "Dark"
    r = int(hex_col[1:3], 16)
    g = int(hex_col[3:5], 16)
    b = int(hex_col[5:7], 16)
    bg = (15, 23, 42) if is_dark else (240, 244, 248)
    rr = int(bg[0] * (1 - alpha) + r * alpha)
    gg = int(bg[1] * (1 - alpha) + g * alpha)
    bb = int(bg[2] * (1 - alpha) + b * alpha)
    return f"#{rr:02X}{gg:02X}{bb:02X}"
