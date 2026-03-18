"""
AHU Control Screen – the main operational panel.
Layout (1024×600 landscape):
  ┌─ Top Bar (58 px) ───────────────────────────────────────────┐
  ├─ Content (scrollable) ──────────────────────────────────────┤
  │  ┌── Sensor Controls ──┐  ┌── Component Status ────────────┐│
  │  │  Temp  │  Humidity  │  │  M1 · M2 · CP1 · CP2 · Fan    ││
  │  └────────────────────┘  └───────────────────────────────── ┘│
  │  ┌── Combo Sensor (optional) ──────────────────────────────┐ │
  │  └─────────────────────────────────────────────────────────┘ │
  │  ┌── Logs (admin, collapsible) ────────────────────────────┐ │
  └──┴─────────────────────────────────────────────────────────┴─┘
"""
import customtkinter as ctk
from app.theme import T, SUCCESS, ERROR, WARNING, AMBER, CYAN, TEAL, INDIGO
from app.theme import TEMP_COL, HUM_COL, ORANGE, PINK, font
from app.models.ahu_telemetry import AhuTelemetry
from app.models.ahu_state import AhuState


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


def _darken(hex_col: str, amount: int = 25) -> str:
    r = max(0, int(hex_col[1:3], 16) - amount)
    g = max(0, int(hex_col[3:5], 16) - amount)
    b = max(0, int(hex_col[5:7], 16) - amount)
    return f"#{r:02X}{g:02X}{b:02X}"


# ── Main Screen ───────────────────────────────────────────────────────────────

class AhuControlScreen(ctk.CTkFrame):
    def __init__(self, parent, app, ahu_id: str, role: str = "hospital", **kwargs):
        super().__init__(parent, fg_color=T("bg"), corner_radius=0, **kwargs)
        self._app      = app
        self._key      = ahu_id
        self._role     = role
        self._provider = app.provider
        self._logs_open = False
        self._build()
        self._subscribe()

    def on_theme_changed(self):
        for w in self.winfo_children():
            w.destroy()
        self.configure(fg_color=T("bg"))
        self._build()
        self._subscribe()

    def destroy(self):
        self._unsubscribe()
        super().destroy()

    # ── subscriptions ─────────────────────────────────────────────────────────

    def _subscribe(self):
        self._provider.subscribe("telemetry", self._on_update)
        self._provider.subscribe("state",     self._on_update)
        self._provider.subscribe("online",    self._on_update)
        self._provider.subscribe("lock",      self._on_lock_change)
        self._provider.subscribe("logs",      self._on_logs)

    def _unsubscribe(self):
        for ev, cb in [
            ("telemetry", self._on_update),
            ("state",     self._on_update),
            ("online",    self._on_update),
            ("lock",      self._on_lock_change),
            ("logs",      self._on_logs),
        ]:
            self._provider.unsubscribe(ev, cb)

    # ── layout ────────────────────────────────────────────────────────────────

    def _build(self):
        self._build_topbar()
        ctk.CTkFrame(self, fg_color=T("border"), height=1).pack(fill="x")
        # Fixed single-screen layout for 1024×600 (no scrolling).
        self._content = ctk.CTkFrame(self, fg_color=T("bg"), corner_radius=0)
        self._content.pack(fill="both", expand=True)
        self._build_content()
        self._on_update()

    def _build_topbar(self):
        # Slim top bar for 1024×600 so content gets maximum height.
        # Don't hardcode height; let it collapse to content with minimal padding.
        bar = ctk.CTkFrame(self, fg_color=T("topbar"), corner_radius=0)
        bar.pack(fill="x")

        # Use a 2-column layout so essential controls never overflow off-screen.
        bar.grid_columnconfigure(0, weight=1)
        bar.grid_columnconfigure(1, weight=0)

        left = ctk.CTkFrame(bar, fg_color="transparent")
        left.grid(row=0, column=0, sticky="w", padx=10, pady=2)

        ctk.CTkLabel(left, text="ALMED",
                     font=("Helvetica", 18, "bold"), text_color="#3B82F6").pack(
            side="left", pady=0)
        ctk.CTkFrame(left, fg_color=T("border"), width=1).pack(
            side="left", fill="y", padx=10, pady=2)

        # back button
        ctk.CTkButton(left, text="‹ Back", width=68, height=30,
                      font=font(12), fg_color="transparent",
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      corner_radius=8,
                      command=lambda: self._app.show_dashboard(self._role)).pack(
            side="left", padx=(0, 8), pady=0)

        # AHU info
        self._ahu_info = _AhuInfoBar(left, self._provider, self._key)
        self._ahu_info.pack(side="left")

        right = ctk.CTkFrame(bar, fg_color="transparent")
        right.grid(row=0, column=1, sticky="e", padx=10, pady=2)

        # screen lock button
        self._lock_btn = ctk.CTkButton(right, text="🔒 LOCKED",
                                       width=106, height=30,
                                       font=font(11, "bold"),
                                       fg_color=AMBER,
                                       text_color="#FFFFFF",
                                       hover_color=_darken(AMBER),
                                       corner_radius=9,
                                       command=self._toggle_lock)
        self._lock_btn.pack(side="left", padx=6, pady=0)
        self._lock_btn.bind("<Button-3>", self._change_passcode)  # right-click

        # CP mode
        self._cp_btn = ctk.CTkButton(right, text="DUAL",
                                     width=78, height=30,
                                     font=font(11, "bold"),
                                     fg_color=CYAN,
                                     text_color="#FFFFFF",
                                     hover_color=_darken(CYAN),
                                     corner_radius=9,
                                     command=self._toggle_cp_mode)
        self._cp_btn.pack(side="left", padx=6, pady=0)

        # start/stop
        self._start_stop_btn = ctk.CTkButton(right, text="▶ START",
                                             width=124, height=30,
                                             font=font(12, "bold"),
                                             fg_color=SUCCESS,
                                             text_color="#FFFFFF",
                                             hover_color=_darken(SUCCESS),
                                             corner_radius=9,
                                             command=self._toggle_start_stop)
        self._start_stop_btn.pack(side="left", padx=6, pady=0)

    def _build_content(self):
        content = self._content

        # ── row 1: sensor controls ────────────────────────────────────────────
        sr = ctk.CTkFrame(content, fg_color="transparent")
        # Pull content up; minimize wasted space under the top bar.
        sr.pack(fill="x", padx=12, pady=(6, 6))
        sr.columnconfigure(0, weight=1)
        sr.columnconfigure(1, weight=1)

        self._temp_ctrl = _SensorControl(
            sr, label="TEMPERATURE", unit="°C", color=TEMP_COL,
            icon="🌡", locked=False,
            on_change=lambda v: self._provider.set_temperature(self._key, v),
            min_val=15.0, max_val=30.0, step=0.5,
        )
        self._temp_ctrl.grid(row=0, column=0, padx=(0, 8), sticky="nsew")
        self._temp_ctrl.configure(height=210)
        self._temp_ctrl.pack_propagate(False)

        self._hum_ctrl = _SensorControl(
            sr, label="HUMIDITY", unit="%RH", color=HUM_COL,
            icon="💧", locked=self._provider.is_screen_locked,
            on_change=lambda v: self._provider.set_humidity(self._key, v),
            min_val=30.0, max_val=80.0, step=0.5,
        )
        self._hum_ctrl.grid(row=0, column=1, padx=(8, 0), sticky="nsew")
        self._hum_ctrl.configure(height=210)
        self._hum_ctrl.pack_propagate(False)

        # ── row 2: component status ───────────────────────────────────────────
        comp_outer = ctk.CTkFrame(content, fg_color=T("card"),
                                  corner_radius=16,
                                  border_width=1, border_color=T("card_border"))
        comp_outer.pack(fill="x", padx=12, pady=6)
        ctk.CTkLabel(comp_outer, text="COMPONENT STATUS",
                     font=font(11, "bold"), text_color=T("text_sec")).pack(
            anchor="w", padx=14, pady=(10, 2))

        self._comp_scroll = ctk.CTkScrollableFrame(comp_outer,
                                                    fg_color="transparent",
                                                    height=94,
                                                    orientation="horizontal")
        self._comp_scroll.pack(fill="x", padx=8, pady=(0, 10))
        self._comp_indicators: dict = {}
        self._build_component_indicators()

        # ── row 3: combo sensor (optional) ────────────────────────────────────
        # Keep it compact; only show if combo telemetry exists.
        self._combo_frame = ctk.CTkFrame(content, fg_color="transparent")
        self._combo_frame.pack(fill="x", padx=12, pady=(2, 0))

    def _build_component_indicators(self):
        for w in self._comp_scroll.winfo_children():
            w.destroy()
        self._comp_indicators.clear()

        state = self._provider.state.get(self._key)
        cp_mode = getattr(state, "cp_mode", "single") if state else "single"

        components = [
            ("m1",     "Motor 1\nFilter",  TEMP_COL, True),
            ("m2",     "Motor 2\nDrain",   HUM_COL,  True),
            ("cp1",    "CP 1",             CYAN,     False),
            ("cp2",    "CP 2",             TEAL,     cp_mode == "dual"),
            ("heater", "Heater",           "#1E40AF", False),
            ("fan",    "Fan",              SUCCESS,  True),
        ]
        for key, label, color, clickable in components:
            ind = _ComponentIndicator(
                self._comp_scroll, key=key, label=label, color=color,
                clickable=clickable and self._role == "admin",
                on_click=self._comp_click,
            )
            ind.pack(side="left", padx=6, pady=4)
            self._comp_indicators[key] = ind

    def _build_logs_section(self, parent):
        header = ctk.CTkFrame(parent, fg_color=T("card"),
                              corner_radius=12,
                              border_width=1, border_color=T("card_border"))
        header.pack(fill="x", padx=16, pady=8)

        toggle_row = ctk.CTkFrame(header, fg_color="transparent")
        toggle_row.pack(fill="x", padx=16, pady=10)

        ctk.CTkLabel(toggle_row, text="📋  System Logs",
                     font=font(14, "bold"), text_color=T("text")).pack(side="left")
        self._log_toggle_btn = ctk.CTkButton(
            toggle_row, text="▼ Show",
            width=80, height=30, font=font(12),
            fg_color="transparent", text_color=T("text_sec"),
            hover_color=T("surface2"), corner_radius=8,
            command=self._toggle_logs)
        self._log_toggle_btn.pack(side="right")
        self._log_outer = header

        self._log_box = ctk.CTkTextbox(
            header, height=180, font=("Courier", 11),
            fg_color=T("surface"), text_color=T("text"),
            border_width=1, border_color=T("border"),
            corner_radius=8)
        self._log_box.configure(state="disabled")

    def _toggle_logs(self):
        self._logs_open = not self._logs_open
        if self._logs_open:
            self._log_box.pack(fill="x", padx=12, pady=(0, 12))
            self._log_toggle_btn.configure(text="▲ Hide")
        else:
            self._log_box.pack_forget()
            self._log_toggle_btn.configure(text="▼ Show")

    # ── update callbacks ──────────────────────────────────────────────────────

    def _on_update(self):
        t     = self._provider.telemetry.get(self._key)
        s     = self._provider.state.get(self._key)
        online = self._provider.online.get(self._key, False)

        self._update_topbar(t, s, online)
        self._update_sensors(t, s)
        self._update_components(t, s)
        self._update_combo(t)

    def _on_lock_change(self):
        locked = self._provider.is_screen_locked
        if locked:
            self._lock_btn.configure(text="🔒 LOCKED", fg_color=AMBER,
                                     hover_color=_darken(AMBER))
        else:
            self._lock_btn.configure(text="🔓 UNLOCKED",
                                     fg_color=T("surface"),
                                     hover_color=T("surface2"),
                                     text_color=T("text"))
        self._hum_ctrl.set_locked(locked)

    def _on_logs(self):
        if not hasattr(self, "_log_box"):
            return
        logs = list(self._provider.logs.get(self._key, []))[:50]
        self._log_box.configure(state="normal")
        self._log_box.delete("1.0", "end")
        for log in logs:
            prefix = {"ERROR": "✖", "WARN": "⚠", "INFO": "ℹ"}.get(log.lvl, "•")
            self._log_box.insert("end", f"[{log.formatted_time}] {prefix} {log.msg}\n")
        self._log_box.configure(state="disabled")

    def _update_topbar(self, t, s, online):
        src = t or s
        if not src:
            return

        running = getattr(src, "run", False)
        if running:
            self._start_stop_btn.configure(text="■ STOP", fg_color=ERROR,
                                           hover_color=_darken(ERROR))
        else:
            self._start_stop_btn.configure(text="▶ START", fg_color=SUCCESS,
                                           hover_color=_darken(SUCCESS))

        if s:
            cp_mode = getattr(s, "cp_mode", "single")
            if cp_mode == "dual":
                self._cp_btn.configure(text="DUAL", fg_color=CYAN,
                                       hover_color=_darken(CYAN))
            else:
                self._cp_btn.configure(text="SNGL", fg_color=TEAL,
                                       hover_color=_darken(TEAL))

        self._ahu_info.update(s, online)

    def _update_sensors(self, t, s):
        src = t or s
        if not src:
            return
        self._temp_ctrl.update_value(
            actual=getattr(src, "temp", None) if t else None,
            setpoint=getattr(src, "temp_set", 24.0),
        )
        self._hum_ctrl.update_value(
            actual=getattr(src, "hum", None) if t else None,
            setpoint=getattr(src, "hum_set", 55.0),
        )

    def _update_components(self, t, s):
        src = t or s
        if not src:
            return
        mapping = {
            "m1":     getattr(src, "m1",     False),
            "m2":     getattr(src, "m2",     False),
            "cp1":    getattr(src, "cp",     False),
            "cp2":    getattr(src, "cp2",    False) or False,
            "heater": getattr(src, "heater", False),
            "fan":    getattr(src, "fan",    False),
        }
        speed = getattr(src, "fan_speed", 0) if t else getattr(s, "fan_speed", 0) if s else 0
        for k, active in mapping.items():
            if k in self._comp_indicators:
                label_suffix = ""
                if k == "fan" and t:
                    label_suffix = f"\n{t.fan_speed_display}"
                self._comp_indicators[k].set_active(active, label_suffix)

    def _update_combo(self, t: AhuTelemetry):
        for w in self._combo_frame.winfo_children():
            w.destroy()
        if not t or not t.is_combo_sensor:
            return

        if t.has_air_quality_data:
            _ComboAirQuality(self._combo_frame, t).pack(
                fill="x", pady=(0, 8))
        if t.has_hepa_data:
            _ComboHepa(self._combo_frame, t).pack(fill="x", pady=(0, 8))

    # ── actions ───────────────────────────────────────────────────────────────

    def _toggle_start_stop(self):
        s = self._provider.state.get(self._key)
        t = self._provider.telemetry.get(self._key)
        running = getattr(s or t, "run", False)
        if running:
            self._provider.stop_ahu(self._key)
        else:
            self._provider.start_ahu(self._key)

    def _toggle_cp_mode(self):
        if self._provider.is_screen_locked:
            return
        s = self._provider.state.get(self._key)
        current = getattr(s, "cp_mode", "single") if s else "single"
        new_mode = "single" if current == "dual" else "dual"
        self._provider.set_cp_mode(self._key, new_mode)

    def _toggle_mode(self):
        s = self._provider.state.get(self._key)
        current = getattr(s, "online_mode", True) if s else True
        self._provider.set_mode(self._key, not current)

    def _toggle_lock(self):
        if self._provider.is_screen_locked:
            from app.widgets.passcode_dialog import ScreenUnlockDialog
            ScreenUnlockDialog(self.winfo_toplevel(), self._provider,
                               on_success=lambda: None)
        else:
            self._provider.lock_screen()

    def _change_passcode(self, _=None):
        if not self._provider.is_screen_locked:
            from app.widgets.passcode_dialog import ChangePasscodeDialog
            ChangePasscodeDialog(self.winfo_toplevel(), self._provider)

    def _comp_click(self, key: str):
        if key in ("m1", "m2"):
            from app.widgets.motor_timing_dialog import MotorTimingDialog
            MotorTimingDialog(self.winfo_toplevel(), self._provider, self._key)
        elif key == "fan":
            self._provider.toggle_fan_speed(self._key)

    def _open_wifi(self):
        from app.widgets.wifi_dialog import WiFiDialog
        WiFiDialog(self.winfo_toplevel())

    def _reset_confirm(self):
        dlg = ctk.CTkToplevel(self.winfo_toplevel())
        dlg.title("")
        dlg.geometry("380x200")
        dlg.resizable(False, False)
        dlg.configure(fg_color=T("surface"))
        try:
            dlg.transient(self.winfo_toplevel())
        except Exception:
            pass
        try:
            dlg.lift()
            dlg.attributes("-topmost", True)
            dlg.after(350, lambda: dlg.attributes("-topmost", False))
            dlg.focus_force()
        except Exception:
            pass
        dlg.after(0, lambda: _safe_grab(dlg))
        ctk.CTkLabel(dlg, text="Reset ESP32?",
                     font=font(18, "bold"), text_color=T("text")).pack(pady=(32, 8))
        ctk.CTkLabel(dlg, text="This will restart the device firmware.",
                     font=font(13), text_color=T("text_sec")).pack()
        btns = ctk.CTkFrame(dlg, fg_color="transparent")
        btns.pack(pady=20)
        ctk.CTkButton(btns, text="Cancel", width=130, height=40,
                      fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"),
                      hover_color=T("surface2"),
                      command=dlg.destroy).pack(side="left", padx=8)
        ctk.CTkButton(btns, text="Reset", width=130, height=40,
                      fg_color=ERROR, text_color="#FFFFFF",
                      hover_color=_darken(ERROR),
                      command=lambda: [
                          self._provider.reset_esp32(self._key), dlg.destroy()
                      ]).pack(side="left", padx=8)


def _safe_grab(win):
    try:
        win.update_idletasks()
        win.wait_visibility()
        win.grab_set()
    except Exception:
        pass


# ── AHU info bar (top-bar embed) ──────────────────────────────────────────────

class _AhuInfoBar(ctk.CTkFrame):
    def __init__(self, parent, provider, key, **kwargs):
        super().__init__(parent, fg_color="transparent", **kwargs)
        self._provider = provider
        self._key      = key
        unit = provider.ahu_units.get(key)
        name = unit.name if unit else "AHU Unit"

        self._name_lbl = ctk.CTkLabel(self, text=name,
                                      font=font(14, "bold"), text_color=T("text"))
        self._name_lbl.pack(side="left")

        self._online_dot = ctk.CTkFrame(self, fg_color="#6B7280",
                                        width=8, height=8, corner_radius=4)
        self._online_dot.pack_propagate(False)
        self._online_dot.pack(side="left", padx=(8, 4))

        self._run_badge = ctk.CTkLabel(self, text="STOPPED",
                                       font=font(9, "bold"),
                                       text_color="#6B7280",
                                       fg_color=T("surface2"),
                                       corner_radius=6, padx=6, pady=1)
        self._run_badge.pack(side="left", padx=2)

    def update(self, state: AhuState, online: bool):
        if state:
            running = getattr(state, "run", False)
            if running:
                self._run_badge.configure(text="RUNNING",
                                          text_color="#FFFFFF",
                                          fg_color=SUCCESS)
            else:
                self._run_badge.configure(text="STOPPED",
                                          text_color="#6B7280",
                                          fg_color=T("surface2"))

            om = getattr(state, "online_mode", True)
            self._run_badge.pack(side="left", padx=2)

        self._online_dot.configure(fg_color=SUCCESS if online else ERROR)


# ── Sensor control card ───────────────────────────────────────────────────────

class _SensorControl(ctk.CTkFrame):
    def __init__(self, parent, label, unit, color, icon,
                 locked, on_change, min_val, max_val, step, **kwargs):
        super().__init__(parent,
                         fg_color=T("card"),
                         corner_radius=20,
                         border_width=1,
                         border_color=T("card_border"),
                         **kwargs)
        self._color     = color
        self._unit      = unit
        self._on_change = on_change
        self._min       = min_val
        self._max       = max_val
        self._step      = step
        self._locked    = locked
        self._setpoint  = (min_val + max_val) / 2

        inner = ctk.CTkFrame(self, fg_color="transparent")
        inner.pack(fill="both", expand=True, padx=16, pady=12)

        # header
        hrow = ctk.CTkFrame(inner, fg_color="transparent")
        hrow.pack(fill="x")
        hrow.grid_columnconfigure(0, weight=1)
        hrow.grid_columnconfigure(1, weight=0)

        title_wrap = ctk.CTkFrame(hrow, fg_color="transparent")
        title_wrap.grid(row=0, column=0, sticky="nsew")

        title = ctk.CTkFrame(title_wrap, fg_color="transparent")
        title.pack(expand=True)

        icon_f = ctk.CTkFrame(title, fg_color=_tint(color, 0.2),
                              width=44, height=44, corner_radius=12)
        icon_f.pack_propagate(False)
        icon_f.pack(side="left")
        ctk.CTkLabel(icon_f, text=icon, font=font(20),
                     text_color=color).pack(expand=True)
        ctk.CTkLabel(title, text=label, font=font(12, "bold"),
                     text_color=T("text_sec")).pack(side="left", padx=10)

        if locked:
            self._lock_lbl = ctk.CTkLabel(hrow, text="🔒",
                                          font=font(14), text_color=AMBER)
            self._lock_lbl.grid(row=0, column=1, sticky="e", padx=(0, 2))

        # actual value
        ctk.CTkFrame(inner, fg_color=T("border"), height=1).pack(
            fill="x", pady=8)
        ctk.CTkLabel(inner, text="ACTUAL",
                     font=font(10, "bold"), text_color=T("text_sec")).pack(pady=(0, 2))

        self._actual_lbl = ctk.CTkLabel(inner, text="--.-",
                                        font=font(40, "bold"),
                                        text_color=color)
        self._actual_lbl.pack()
        ctk.CTkLabel(inner, text=unit, font=font(14),
                     text_color=T("text_sec")).pack(pady=(0, 2))

        # setpoint row
        ctk.CTkFrame(inner, fg_color=T("border"), height=1).pack(
            fill="x", pady=8)

        set_row = ctk.CTkFrame(inner, fg_color="transparent")
        set_row.pack(fill="x")

        ctk.CTkLabel(set_row, text="SETPOINT",
                     font=font(10, "bold"), text_color=T("text_sec")).pack(
            pady=(0, 0))

        ctrl_row = ctk.CTkFrame(inner, fg_color="transparent")
        ctrl_row.pack(fill="x", pady=(6, 0))
        ctrl_row.grid_columnconfigure(0, weight=1)
        ctrl_row.grid_columnconfigure(1, weight=0)
        ctrl_row.grid_columnconfigure(2, weight=1)

        self._dec_btn = ctk.CTkButton(
            ctrl_row, text="−", width=54, height=54,
            font=font(24, "bold"), fg_color=_tint(color, 0.15),
            text_color=color, hover_color=_tint(color, 0.25),
            corner_radius=14,
            command=self._decrement)
        self._dec_btn.grid(row=0, column=0, sticky="e", padx=(0, 10))

        self._set_lbl = ctk.CTkLabel(ctrl_row, text="--.-",
                                     font=font(30, "bold"), text_color=color,
                                     width=90)
        self._set_lbl.grid(row=0, column=1)

        self._inc_btn = ctk.CTkButton(
            ctrl_row, text="+", width=54, height=54,
            font=font(24, "bold"), fg_color=color,
            text_color="#FFFFFF", hover_color=_darken(color),
            corner_radius=14,
            command=self._increment)
        self._inc_btn.grid(row=0, column=2, sticky="w", padx=(10, 0))

        self._update_lock_state()

    def set_locked(self, locked: bool):
        self._locked = locked
        self._update_lock_state()

    def _update_lock_state(self):
        state = "disabled" if self._locked else "normal"
        self._dec_btn.configure(state=state)
        self._inc_btn.configure(state=state)

    def update_value(self, actual, setpoint: float):
        if actual is not None:
            self._actual_lbl.configure(text=f"{actual:.1f}")
        self._setpoint = setpoint
        self._set_lbl.configure(text=f"{setpoint:.1f}")

    def _increment(self):
        new_val = round(min(self._max, self._setpoint + self._step), 1)
        self._setpoint = new_val
        self._set_lbl.configure(text=f"{new_val:.1f}")
        self._on_change(new_val)

    def _decrement(self):
        new_val = round(max(self._min, self._setpoint - self._step), 1)
        self._setpoint = new_val
        self._set_lbl.configure(text=f"{new_val:.1f}")
        self._on_change(new_val)


# ── Component indicator tile ──────────────────────────────────────────────────

class _ComponentIndicator(ctk.CTkFrame):
    def __init__(self, parent, key, label, color, clickable, on_click, **kwargs):
        super().__init__(parent,
                         fg_color=T("surface"),
                         corner_radius=14,
                         border_width=2,
                         border_color=T("border"),
                         width=110, height=100,
                         **kwargs)
        self.pack_propagate(False)
        self._key       = key
        self._color     = color
        self._clickable = clickable
        self._on_click  = on_click
        self._active    = False
        self._base_label = label

        inner = ctk.CTkFrame(self, fg_color="transparent")
        inner.pack(fill="both", expand=True, padx=8, pady=8)

        self._icon_f = ctk.CTkFrame(inner, fg_color=_tint(color, 0.1),
                                    width=40, height=40, corner_radius=10)
        self._icon_f.pack_propagate(False)
        self._icon_f.pack(pady=(0, 4))
        _ICONS = {
            "m1": "⚙", "m2": "💧", "cp1": "❄", "cp2": "❄",
            "heater": "🔥", "fan": "🌀",
        }
        ctk.CTkLabel(self._icon_f, text=_ICONS.get(key, "●"),
                     font=font(18), text_color=color).pack(expand=True)

        self._lbl = ctk.CTkLabel(inner, text=label.replace("\n", " "),
                                 font=font(10, "bold"),
                                 text_color=T("text_sec"),
                                 justify="center")
        self._lbl.pack()

        self._badge = ctk.CTkLabel(inner, text="OFF",
                                   font=font(9, "bold"),
                                   text_color="#6B7280",
                                   fg_color=T("surface2"),
                                   corner_radius=5, padx=4, pady=1)
        self._badge.pack()

        if clickable:
            self.configure(cursor="hand2")
            self.bind("<Button-1>", lambda _: on_click(key))
            for c in self.winfo_children():
                c.bind("<Button-1>", lambda _: on_click(key))

    def set_active(self, active: bool, label_suffix: str = ""):
        self._active = active
        if active:
            self.configure(fg_color=_tint(self._color, 0.15),
                           border_color=self._color)
            self._badge.configure(text="ON", text_color="#FFFFFF",
                                  fg_color=self._color)
        else:
            self.configure(fg_color=T("surface"), border_color=T("border"))
            self._badge.configure(text="OFF", text_color="#6B7280",
                                  fg_color=T("surface2"))
        if label_suffix:
            self._lbl.configure(text=(self._base_label + label_suffix).replace("\n", " "))


# ── Combo sensor widgets ──────────────────────────────────────────────────────

class _ComboAirQuality(ctk.CTkFrame):
    _PM_FIELDS = [
        ("pm1p0",  "PM1.0",  SUCCESS),
        ("pm2p5",  "PM2.5",  ORANGE),
        ("pm4p0",  "PM4.0",  "#3B82F6"),
        ("pm10p0", "PM10",   "#8B5CF6"),
        ("voc",    "VOC",    CYAN),
        ("nox",    "NOx",    PINK),
        ("co2",    "CO₂",    "#64748B"),
    ]

    def __init__(self, parent, t: AhuTelemetry, **kwargs):
        super().__init__(parent,
                         fg_color=T("card"),
                         corner_radius=16,
                         border_width=1,
                         border_color=T("card_border"),
                         **kwargs)
        inner = ctk.CTkFrame(self, fg_color="transparent")
        inner.pack(fill="both", expand=True, padx=16, pady=12)

        header = ctk.CTkFrame(inner, fg_color="transparent")
        header.pack(fill="x", pady=(0, 10))
        ctk.CTkLabel(header, text="🌬  Air Quality",
                     font=font(14, "bold"), text_color=T("text")).pack(side="left")

        if t.aqi is not None:
            cat, color = t.aqi_category
            ctk.CTkLabel(header, text=f"AQI {int(t.aqi):,}  {cat}",
                         font=font(12, "bold"), text_color="#FFFFFF",
                         fg_color=color, corner_radius=8,
                         padx=8, pady=3).pack(side="right")

        row = ctk.CTkFrame(inner, fg_color="transparent")
        row.pack(fill="x")

        for attr, label, color in self._PM_FIELDS:
            val = getattr(t, attr, None)
            if val is None:
                continue
            tile = ctk.CTkFrame(row, fg_color=_tint(color, 0.1),
                                corner_radius=10,
                                border_width=1,
                                border_color=_tint(color, 0.2),
                                width=90)
            tile.pack(side="left", padx=4)
            ctk.CTkLabel(tile, text=label, font=font(10),
                         text_color=color).pack(pady=(6, 0))
            ctk.CTkLabel(tile, text=f"{val:.0f}",
                         font=font(16, "bold"), text_color=color).pack()
            if attr == "co2":
                ctk.CTkLabel(tile, text=t.co2_level, font=font(9),
                             text_color=T("text_sec")).pack(pady=(0, 6))
            else:
                ctk.CTkLabel(tile, text="μg/m³" if attr.startswith("pm") else "",
                             font=font(9), text_color=T("text_sec")).pack(pady=(0, 6))


class _ComboHepa(ctk.CTkFrame):
    def __init__(self, parent, t: AhuTelemetry, **kwargs):
        super().__init__(parent,
                         fg_color=T("card"),
                         corner_radius=16,
                         border_width=1,
                         border_color=T("card_border"),
                         **kwargs)
        inner = ctk.CTkFrame(self, fg_color="transparent")
        inner.pack(fill="both", expand=True, padx=16, pady=12)

        health = t.calculated_hepa_health
        status = t.calculated_hepa_status
        dp     = t.diff_pressure

        if health > 70:
            color = SUCCESS
        elif health > 40:
            color = WARNING
        else:
            color = ERROR

        header = ctk.CTkFrame(inner, fg_color="transparent")
        header.pack(fill="x")
        ctk.CTkLabel(header, text="🔲  HEPA Filter",
                     font=font(14, "bold"), text_color=T("text")).pack(side="left")

        ctk.CTkLabel(header, text=status,
                     font=font(12, "bold"), text_color="#FFFFFF",
                     fg_color=color, corner_radius=8,
                     padx=8, pady=3).pack(side="right")

        # health bar
        bar_outer = ctk.CTkFrame(inner, fg_color=T("surface2"),
                                 corner_radius=6, height=14)
        bar_outer.pack(fill="x", pady=(10, 4))
        bar_outer.pack_propagate(False)
        width_ratio = max(0.02, health / 100)
        bar_inner = ctk.CTkFrame(bar_outer, fg_color=color,
                                 corner_radius=6, height=14)
        bar_inner.place(relx=0, rely=0, relwidth=width_ratio, relheight=1)

        info_row = ctk.CTkFrame(inner, fg_color="transparent")
        info_row.pack(fill="x")
        ctk.CTkLabel(info_row, text=f"Health: {health:.0f}%",
                     font=font(12), text_color=color).pack(side="left")
        if dp is not None:
            ctk.CTkLabel(info_row, text=f"ΔP: {dp:.1f} Pa",
                         font=font(12), text_color=T("text_sec")).pack(side="right")
