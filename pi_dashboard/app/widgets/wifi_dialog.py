"""
WiFi network manager dialog (Linux / Raspberry Pi).
"""
import threading
import customtkinter as ctk
from app.theme import T, SUCCESS, ERROR, font
from app.services.wifi_service import WiFiService, WiFiNetwork


_SIGNAL_ICONS = {3: "▂▄█", 2: "▂▄░", 1: "▂░░"}


class WiFiDialog(ctk.CTkToplevel):
    def __init__(self, parent):
        super().__init__(parent)
        self._svc = WiFiService.get()
        self._networks: list[WiFiNetwork] = []
        self._scanning = False

        self.title("")
        self.geometry("520x560")
        self.resizable(False, False)
        self.configure(fg_color=T("surface"))
        self.grab_set()
        self._center(parent)
        self._build()
        self._scan()

    def _center(self, parent):
        self.update_idletasks()
        pw = parent.winfo_rootx() + parent.winfo_width()  // 2
        ph = parent.winfo_rooty() + parent.winfo_height() // 2
        w, h = 520, 560
        self.geometry(f"{w}x{h}+{pw - w//2}+{ph - h//2}")

    def _build(self):
        header = ctk.CTkFrame(self, fg_color="#0F172A", corner_radius=0, height=56)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="📶  WiFi Networks",
                     font=font(17, "bold"), text_color="#FFFFFF").pack(
            side="left", padx=20)

        self._scan_btn = ctk.CTkButton(
            header, text="⟳", width=36, height=36,
            fg_color="transparent", text_color="#FFFFFF",
            hover_color="#1E3A5F", font=font(18, "bold"),
            command=self._scan)
        self._scan_btn.pack(side="right", padx=4)

        ctk.CTkButton(header, text="✕", width=36, height=36,
                      fg_color="transparent", text_color="#FFFFFF",
                      hover_color="#1E3A5F", font=font(16, "bold"),
                      command=self.destroy).pack(side="right", padx=4)

        self._status_lbl = ctk.CTkLabel(self, text="Scanning...",
                                        font=font(12), text_color=T("text_sec"))
        self._status_lbl.pack(pady=8)

        self._list_frame = ctk.CTkScrollableFrame(
            self, fg_color=T("bg"), corner_radius=0)
        self._list_frame.pack(fill="both", expand=True)

    def _scan(self):
        if self._scanning:
            return
        if not self._svc.is_available():
            self._status_lbl.configure(text="nmcli not available on this system")
            return
        self._scanning = True
        self._scan_btn.configure(state="disabled")
        self._status_lbl.configure(text="Scanning networks…")
        threading.Thread(target=self._do_scan, daemon=True).start()

    def _do_scan(self):
        nets = self._svc.scan_networks()
        self.after(0, lambda: self._show_networks(nets))

    def _show_networks(self, nets: list[WiFiNetwork]):
        self._networks = nets
        self._scanning = False
        self._scan_btn.configure(state="normal")

        for w in self._list_frame.winfo_children():
            w.destroy()

        if not nets:
            ctk.CTkLabel(self._list_frame, text="No networks found",
                         font=font(13), text_color=T("text_sec")).pack(pady=30)
            self._status_lbl.configure(text="No networks found")
            return

        connected = [n for n in nets if n.is_connected]
        ssid_text = f"Connected: {connected[0].ssid}" if connected else "Not connected"
        self._status_lbl.configure(text=ssid_text)

        for net in nets:
            self._build_network_row(net)

    def _build_network_row(self, net: WiFiNetwork):
        row = ctk.CTkFrame(
            self._list_frame, fg_color=T("card"),
            corner_radius=10,
            border_width=1,
            border_color=SUCCESS if net.is_connected else T("card_border"))
        row.pack(fill="x", padx=12, pady=4)

        inner = ctk.CTkFrame(row, fg_color="transparent")
        inner.pack(fill="x", padx=12, pady=10)

        # Signal icon
        bars = _SIGNAL_ICONS.get(net.signal_bars, "▂░░")
        sig_color = SUCCESS if net.signal >= 70 else ("#F59E0B" if net.signal >= 40 else ERROR)
        ctk.CTkLabel(inner, text=bars, font=font(14),
                     text_color=sig_color, width=36).pack(side="left")

        info = ctk.CTkFrame(inner, fg_color="transparent")
        info.pack(side="left", fill="x", expand=True, padx=8)

        ssid_color = SUCCESS if net.is_connected else T("text")
        ctk.CTkLabel(info, text=net.ssid, font=font(14, "bold"),
                     text_color=ssid_color, anchor="w").pack(fill="x")

        meta = ctk.CTkFrame(info, fg_color="transparent")
        meta.pack(fill="x")
        ctk.CTkLabel(meta, text=net.security, font=font(11),
                     text_color=T("text_sec"), anchor="w").pack(side="left")
        ctk.CTkLabel(meta, text=f"{net.signal}%", font=font(11),
                     text_color=T("text_sec")).pack(side="left", padx=8)
        if net.is_connected:
            ctk.CTkLabel(meta, text="● Connected", font=font(11),
                         text_color=SUCCESS).pack(side="left")

        ctk.CTkButton(inner, text="Connect", width=88, height=34,
                      font=font(12), fg_color="#3B82F6",
                      text_color="#FFFFFF", hover_color="#2563EB",
                      corner_radius=8,
                      command=lambda n=net: self._connect(n)).pack(side="right")

    def _connect(self, net: WiFiNetwork):
        if net.security.lower() in ("open", "--", ""):
            self._do_connect_open(net)
        else:
            self._show_password_dialog(net)

    def _do_connect_open(self, net: WiFiNetwork):
        self._status_lbl.configure(text=f"Connecting to {net.ssid}…")
        threading.Thread(
            target=lambda: self.after(0, lambda ok=self._svc.connect_open(net.ssid):
                self._status_lbl.configure(
                    text=f"Connected to {net.ssid}" if ok else "Connection failed")),
            daemon=True).start()

    def _show_password_dialog(self, net: WiFiNetwork):
        dlg = ctk.CTkToplevel(self)
        dlg.title("")
        dlg.geometry("400x260")
        dlg.resizable(False, False)
        dlg.configure(fg_color=T("surface"))
        dlg.grab_set()

        ctk.CTkLabel(dlg, text=f"Connect to  "{net.ssid}"",
                     font=font(15, "bold"), text_color=T("text")).pack(pady=(28, 8))
        ctk.CTkLabel(dlg, text="WiFi Password",
                     font=font(12), text_color=T("text_sec")).pack()

        entry = ctk.CTkEntry(dlg, width=320, height=42,
                             font=font(14), show="●",
                             fg_color=T("input_bg"),
                             border_color=T("border"),
                             text_color=T("text"),
                             placeholder_text="Enter password")
        entry.pack(pady=12)

        def toggle_vis():
            entry.configure(show="" if entry.cget("show") else "●")
        ctk.CTkButton(dlg, text="Show / Hide", width=120, height=32,
                      font=font(12), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      command=toggle_vis).pack()

        btns = ctk.CTkFrame(dlg, fg_color="transparent")
        btns.pack(pady=12)

        def do_connect():
            pwd = entry.get()
            dlg.destroy()
            self._status_lbl.configure(text=f"Connecting to {net.ssid}…")
            threading.Thread(
                target=lambda: self.after(0, lambda ok=self._svc.connect(net.ssid, pwd):
                    self._status_lbl.configure(
                        text=f"Connected to {net.ssid}" if ok else "Connection failed")),
                daemon=True).start()

        ctk.CTkButton(btns, text="Cancel", width=130, height=38,
                      font=font(13), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"), hover_color=T("surface2"),
                      command=dlg.destroy).pack(side="left", padx=6)
        ctk.CTkButton(btns, text="Connect", width=140, height=38,
                      font=font(13, "bold"), fg_color="#3B82F6",
                      text_color="#FFFFFF", hover_color="#2563EB",
                      command=do_connect).pack(side="left", padx=6)
