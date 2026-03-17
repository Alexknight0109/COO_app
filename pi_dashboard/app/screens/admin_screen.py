"""
Admin settings screen – WiFi provisioning, MQTT broker config, motor timings.
"""
import os
import subprocess
import customtkinter as ctk
from app.theme import T, SUCCESS, ERROR, TEMP_COL, font


class AdminScreen(ctk.CTkFrame):
    def __init__(self, parent, app, **kwargs):
        super().__init__(parent, fg_color=T("bg"), corner_radius=0, **kwargs)
        self._app      = app
        self._provider = app.provider
        self._ahu_key: str = ""
        self._build()

    def on_theme_changed(self):
        for w in self.winfo_children():
            w.destroy()
        self.configure(fg_color=T("bg"))
        self._build()

    # ── layout ────────────────────────────────────────────────────────────────

    def _build(self):
        # ── top bar ──────────────────────────────────────────────────────────
        bar = ctk.CTkFrame(self, fg_color=T("topbar"), corner_radius=0, height=58)
        bar.pack(fill="x")
        bar.pack_propagate(False)

        left = ctk.CTkFrame(bar, fg_color="transparent")
        left.pack(side="left", padx=14, fill="y")
        ctk.CTkLabel(left, text="ALMED",
                     font=("Helvetica", 22, "bold"), text_color="#3B82F6").pack(
            side="left", pady=12)
        ctk.CTkFrame(left, fg_color=T("border"), width=1).pack(
            side="left", fill="y", padx=10, pady=10)
        ctk.CTkLabel(left, text="Admin Settings",
                     font=font(16, "bold"), text_color=T("text")).pack(side="left")

        right = ctk.CTkFrame(bar, fg_color="transparent")
        right.pack(side="right", padx=12, fill="y")

        ctk.CTkButton(right, text="⏻  Exit Desktop", width=120, height=36,
                      font=font(12), fg_color=ERROR,
                      text_color="#FFFFFF", hover_color="#DC2626",
                      corner_radius=10, command=self._exit_desktop).pack(
            side="right", padx=4)

        ctk.CTkButton(right, text="⬅  Logout", width=100, height=36,
                      font=font(12), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      corner_radius=10,
                      command=self._app.show_login).pack(side="right", padx=4)

        ctk.CTkButton(right, text="◀ Back", width=80, height=36,
                      font=font(12), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      corner_radius=10,
                      command=lambda: self._app.show_dashboard("admin")).pack(
            side="right", padx=4)

        ctk.CTkFrame(self, fg_color=T("border"), height=1).pack(fill="x")

        # ── scrollable content ────────────────────────────────────────────────
        self._scroll = ctk.CTkScrollableFrame(self, fg_color=T("bg"))
        self._scroll.pack(fill="both", expand=True)

        # AHU selector
        units = self._provider.ahu_units
        unit_keys = list(units.keys())
        self._ahu_key = unit_keys[0] if unit_keys else ""

        sel_card = self._section_card("🔗  AHU Selection")
        if unit_keys:
            unit_names = [units[k].name for k in unit_keys]
            self._ahu_combo = ctk.CTkComboBox(
                sel_card, values=unit_names, width=400, height=40,
                font=font(14), fg_color=T("input_bg"),
                border_color=T("border"), text_color=T("text"),
                button_color=T("primary"), dropdown_fg_color=T("surface"),
                command=lambda v: self._on_ahu_select(v, unit_keys, units))
            self._ahu_combo.set(unit_names[0] if unit_names else "No AHU detected")
            self._ahu_combo.pack(padx=16, pady=12)
        else:
            ctk.CTkLabel(sel_card,
                         text="No AHU units detected yet. Connect an ESP32 first.",
                         font=font(13), text_color=T("text_sec")).pack(
                padx=16, pady=12)

        # WiFi provisioning
        wifi_card = self._section_card("📶  WiFi Provisioning")
        self._wifi_ssid1  = self._labeled_entry(wifi_card, "Primary SSID")
        self._wifi_pass1  = self._labeled_entry(wifi_card, "Primary Password", show="●")
        self._wifi_ssid2  = self._labeled_entry(wifi_card, "Secondary SSID (optional)")
        self._wifi_pass2  = self._labeled_entry(wifi_card, "Secondary Password", show="●")
        ctk.CTkButton(wifi_card, text="📡  Provision WiFi",
                      width=200, height=42,
                      font=font(14, "bold"),
                      fg_color=T("primary"), text_color="#FFFFFF",
                      hover_color=T("primary_hov"),
                      corner_radius=10,
                      command=self._provision_wifi).pack(
            anchor="e", padx=16, pady=12)

        # MQTT broker
        broker_card = self._section_card("🖧  MQTT Broker Settings")
        self._broker_host = self._labeled_entry(broker_card, "Broker Host",
                                                default="almed-ahu.local")
        self._broker_port = self._labeled_entry(broker_card, "Port",
                                                default="1883")
        ctk.CTkButton(broker_card, text="🔗  Provision Broker",
                      width=200, height=42,
                      font=font(14, "bold"),
                      fg_color=SUCCESS, text_color="#FFFFFF",
                      hover_color="#059669",
                      corner_radius=10,
                      command=self._provision_broker).pack(
            anchor="e", padx=16, pady=12)

        # Motor timings
        motor_card = self._section_card("⚙  Motor Timing Configuration")
        self._m1_start    = self._labeled_entry(motor_card, "M1 Start Run (s)", default="30")
        self._m1_post     = self._labeled_entry(motor_card, "M1 Post Run (s)",  default="10")
        self._m2_interval = self._labeled_entry(motor_card, "M2 Interval (s)",  default="3600")
        self._m2_run      = self._labeled_entry(motor_card, "M2 Run Time (s)",  default="30")
        self._m2_delay    = self._labeled_entry(motor_card, "M2 Delay (s)",     default="5")

        btns = ctk.CTkFrame(motor_card, fg_color="transparent")
        btns.pack(anchor="e", padx=16, pady=12)
        ctk.CTkButton(btns, text="↺ Reset Defaults",
                      width=160, height=42,
                      font=font(13),
                      fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"),
                      hover_color=T("surface2"),
                      corner_radius=10,
                      command=self._reset_timings).pack(side="left", padx=6)
        ctk.CTkButton(btns, text="💾  Save Timings",
                      width=160, height=42,
                      font=font(14, "bold"),
                      fg_color=TEMP_COL, text_color="#FFFFFF",
                      hover_color="#2563EB",
                      corner_radius=10,
                      command=self._save_timings).pack(side="left", padx=6)

    # ── helpers ───────────────────────────────────────────────────────────────

    def _section_card(self, title: str) -> ctk.CTkFrame:
        card = ctk.CTkFrame(self._scroll, fg_color=T("card"),
                            corner_radius=16,
                            border_width=1, border_color=T("card_border"))
        card.pack(fill="x", padx=20, pady=8)
        ctk.CTkLabel(card, text=title, font=font(15, "bold"),
                     text_color=T("text")).pack(anchor="w", padx=16, pady=(14, 4))
        ctk.CTkFrame(card, fg_color=T("border"), height=1).pack(fill="x", padx=16)
        return card

    def _labeled_entry(self, parent, label: str,
                       default: str = "", show: str = "") -> ctk.CTkEntry:
        row = ctk.CTkFrame(parent, fg_color="transparent")
        row.pack(fill="x", padx=16, pady=4)
        ctk.CTkLabel(row, text=label, font=font(13),
                     text_color=T("text_sec"), width=240, anchor="w").pack(side="left")
        entry = ctk.CTkEntry(row, width=360, height=40,
                             font=font(13),
                             fg_color=T("input_bg"),
                             border_color=T("border"),
                             text_color=T("text"),
                             placeholder_text=label,
                             show=show)
        if default:
            entry.insert(0, default)
        entry.pack(side="left", padx=8)
        return entry

    def _on_ahu_select(self, name: str, keys: list, units: dict):
        for k in keys:
            if units[k].name == name:
                self._ahu_key = k
                break

    # ── actions ───────────────────────────────────────────────────────────────

    def _provision_wifi(self):
        if not self._ahu_key:
            self._toast("Select an AHU first"); return
        s1 = self._wifi_ssid1.get().strip()
        p1 = self._wifi_pass1.get()
        if not s1:
            self._toast("Primary SSID is required"); return
        self._provider.provision_wifi(
            self._ahu_key, s1, p1,
            self._wifi_ssid2.get().strip(),
            self._wifi_pass2.get(),
        )
        self._toast("WiFi provisioning sent ✓")

    def _provision_broker(self):
        if not self._ahu_key:
            self._toast("Select an AHU first"); return
        host = self._broker_host.get().strip() or "localhost"
        try:
            port = int(self._broker_port.get().strip())
        except ValueError:
            self._toast("Invalid port number"); return
        self._provider.provision_broker(self._ahu_key, host, port)
        self._toast("Broker settings sent ✓")

    def _reset_timings(self):
        for entry, val in [
            (self._m1_start, "30"), (self._m1_post, "10"),
            (self._m2_interval, "3600"), (self._m2_run, "30"),
            (self._m2_delay, "5"),
        ]:
            entry.delete(0, "end")
            entry.insert(0, val)

    def _save_timings(self):
        if not self._ahu_key:
            self._toast("Select an AHU first"); return
        try:
            self._provider.provision_motor_timings(
                self._ahu_key,
                int(self._m1_start.get()),
                int(self._m1_post.get()),
                int(self._m2_interval.get()),
                int(self._m2_run.get()),
                int(self._m2_delay.get()),
            )
            self._toast("Motor timings saved ✓")
        except ValueError:
            self._toast("All timing values must be integers")

    def _toast(self, message: str):
        dlg = ctk.CTkToplevel(self.winfo_toplevel())
        dlg.title("")
        dlg.geometry("380x90")
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
        except Exception:
            pass
        dlg.after(0, lambda: _safe_grab(dlg))
        root = self.winfo_toplevel()
        px = root.winfo_rootx() + root.winfo_width()  // 2 - 190
        py = root.winfo_rooty() + root.winfo_height() - 120
        dlg.geometry(f"380x90+{px}+{py}")
        ctk.CTkLabel(dlg, text=message, font=font(14),
                     text_color=T("text")).pack(expand=True)
        dlg.after(2500, dlg.destroy)

    def _exit_desktop(self):
        script = os.path.join(
            os.path.dirname(__file__), "..", "..", "..",
            "rpi_kiosk_setup", "exit_to_desktop.sh")
        try:
            subprocess.Popen(["bash", os.path.abspath(script)])
        except Exception:
            import sys
            sys.exit(0)


def _safe_grab(win):
    try:
        win.update_idletasks()
        win.wait_visibility()
        win.grab_set()
    except Exception:
        pass
