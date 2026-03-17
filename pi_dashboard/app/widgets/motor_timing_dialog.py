"""
Motor timing configuration dialog (admin only).
"""
import customtkinter as ctk
from app.theme import T, SUCCESS, ERROR, TEMP_COL, HUM_COL, font


_DEFAULTS = {
    "m1_start":   30,
    "m1_post":    10,
    "m2_interval": 3600,
    "m2_run":     30,
    "m2_delay":    5,
}

_FIELDS = [
    ("m1_start",    "M1 Start Run (s)",    "Motor 1 run time at AHU start",        TEMP_COL,   1, 300),
    ("m1_post",     "M1 Post Run (s)",     "Motor 1 run time after AHU stop",       TEMP_COL,   1, 300),
    ("m2_interval", "M2 Interval (s)",     "Drain pump cycle interval",             HUM_COL,  60, 86400),
    ("m2_run",      "M2 Run Time (s)",     "Drain pump active duration",            HUM_COL,   1, 600),
    ("m2_delay",    "M2 Delay (s)",        "Drain pump delay after start",          "#6366F1",  0, 120),
]


class MotorTimingDialog(ctk.CTkToplevel):
    def __init__(self, parent, provider, ahu_key: str):
        super().__init__(parent)
        self._provider = provider
        self._ahu_key  = ahu_key

        self.title("")
        self.geometry("560x620")
        self.resizable(False, False)
        self.configure(fg_color=T("surface"))
        try:
            self.transient(parent)
        except Exception:
            pass
        try:
            self.lift()
            self.attributes("-topmost", True)
            self.after(350, lambda: self.attributes("-topmost", False))
            self.focus_force()
        except Exception:
            pass
        self._center(parent)
        self.after(0, self._safe_grab)

        # Load initial values
        state = provider.state.get(ahu_key)
        self._values = {
            "m1_start":    getattr(state, "m1_start",    _DEFAULTS["m1_start"])    if state else _DEFAULTS["m1_start"],
            "m1_post":     getattr(state, "m1_post",     _DEFAULTS["m1_post"])     if state else _DEFAULTS["m1_post"],
            "m2_interval": getattr(state, "m2_interval", _DEFAULTS["m2_interval"]) if state else _DEFAULTS["m2_interval"],
            "m2_run":      getattr(state, "m2_run",      _DEFAULTS["m2_run"])      if state else _DEFAULTS["m2_run"],
            "m2_delay":    getattr(state, "m2_delay",    _DEFAULTS["m2_delay"])    if state else _DEFAULTS["m2_delay"],
        }
        self._var_labels: dict = {}
        self._build()

    def _safe_grab(self):
        try:
            self.update_idletasks()
            self.wait_visibility()
            self.grab_set()
        except Exception:
            pass

    def _center(self, parent):
        self.update_idletasks()
        pw = parent.winfo_rootx() + parent.winfo_width()  // 2
        ph = parent.winfo_rooty() + parent.winfo_height() // 2
        w, h = 560, 620
        self.geometry(f"{w}x{h}+{pw - w//2}+{ph - h//2}")

    def _build(self):
        # Header
        header = ctk.CTkFrame(self, fg_color=TEMP_COL, corner_radius=0,
                              height=56)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="⚙  Motor Timing Configuration",
                     font=font(17, "bold"), text_color="#FFFFFF").pack(
            side="left", padx=20)
        ctk.CTkButton(header, text="✕", width=36, height=36,
                      fg_color="transparent", text_color="#FFFFFF",
                      hover_color="#2563EB",
                      font=font(16, "bold"),
                      command=self.destroy).pack(side="right", padx=8)

        scroll = ctk.CTkScrollableFrame(self, fg_color=T("surface"))
        scroll.pack(fill="both", expand=True, padx=0, pady=0)

        for key, label, hint, color, vmin, vmax in _FIELDS:
            self._build_control(scroll, key, label, hint, color, vmin, vmax)

        # Footer buttons
        foot = ctk.CTkFrame(self, fg_color=T("surface"),
                            border_width=1, border_color=T("border"),
                            corner_radius=0, height=64)
        foot.pack(fill="x")
        foot.pack_propagate(False)

        ctk.CTkButton(foot, text="Reset Defaults", width=160, height=42,
                      font=font(13), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      command=self._reset).pack(side="left", padx=16, pady=11)

        ctk.CTkButton(foot, text="💾  Save Timings", width=180, height=42,
                      font=font(14, "bold"), fg_color=SUCCESS,
                      text_color="#FFFFFF", hover_color="#059669",
                      command=self._save).pack(side="right", padx=16, pady=11)

    def _build_control(self, parent, key, label, hint, color, vmin, vmax):
        card = ctk.CTkFrame(parent, fg_color=T("card"),
                            corner_radius=14,
                            border_width=1, border_color=T("card_border"))
        card.pack(fill="x", padx=16, pady=6)

        inner = ctk.CTkFrame(card, fg_color="transparent")
        inner.pack(fill="x", padx=16, pady=12)

        # Color indicator
        ind = ctk.CTkFrame(inner, fg_color=color,
                           width=4, corner_radius=2)
        ind.pack(side="left", fill="y", padx=(0, 10))

        info = ctk.CTkFrame(inner, fg_color="transparent")
        info.pack(side="left", fill="x", expand=True)
        ctk.CTkLabel(info, text=label, font=font(14, "bold"),
                     text_color=T("text"), anchor="w").pack(fill="x")
        ctk.CTkLabel(info, text=hint, font=font(11),
                     text_color=T("text_sec"), anchor="w").pack(fill="x")

        ctrl = ctk.CTkFrame(inner, fg_color="transparent")
        ctrl.pack(side="right")

        def dec(k=key, mn=vmin):
            v = max(mn, self._values[k] - 1)
            self._values[k] = v
            self._var_labels[k].configure(text=str(v))

        def inc(k=key, mx=vmax):
            v = min(mx, self._values[k] + 1)
            self._values[k] = v
            self._var_labels[k].configure(text=str(v))

        ctk.CTkButton(ctrl, text="−", width=40, height=40,
                      font=font(18, "bold"), fg_color=T("surface2"),
                      text_color=T("text"), hover_color=T("border"),
                      corner_radius=10, command=dec).pack(side="left", padx=4)

        val_lbl = ctk.CTkLabel(ctrl, text=str(self._values[key]),
                               font=font(22, "bold"), text_color=color,
                               width=70)
        val_lbl.pack(side="left")
        self._var_labels[key] = val_lbl

        ctk.CTkButton(ctrl, text="+", width=40, height=40,
                      font=font(18, "bold"), fg_color=color,
                      text_color="#FFFFFF", hover_color=_darken(color),
                      corner_radius=10, command=inc).pack(side="left", padx=4)

    def _reset(self):
        for k, v in _DEFAULTS.items():
            self._values[k] = v
            if k in self._var_labels:
                self._var_labels[k].configure(text=str(v))

    def _save(self):
        self._provider.provision_motor_timings(
            self._ahu_key,
            self._values["m1_start"],
            self._values["m1_post"],
            self._values["m2_interval"],
            self._values["m2_run"],
            self._values["m2_delay"],
        )
        self.destroy()


def _darken(hex_col: str, amount: int = 25) -> str:
    r = max(0, int(hex_col[1:3], 16) - amount)
    g = max(0, int(hex_col[3:5], 16) - amount)
    b = max(0, int(hex_col[5:7], 16) - amount)
    return f"#{r:02X}{g:02X}{b:02X}"
