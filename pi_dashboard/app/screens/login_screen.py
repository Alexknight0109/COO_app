"""
Login screen  –  role selection (Hospital | Admin).
Admin requires passcode dialog.
"""
import customtkinter as ctk
import os
from app.theme import T, font
from app.widgets.passcode_dialog import PasscodeDialog


def _mix(hex_a: str, hex_b: str, t: float) -> str:
    """Blend two #RRGGBB colours. t=0 → a, t=1 → b."""
    t = max(0.0, min(1.0, float(t)))
    ar, ag, ab = int(hex_a[1:3], 16), int(hex_a[3:5], 16), int(hex_a[5:7], 16)
    br, bg, bb = int(hex_b[1:3], 16), int(hex_b[3:5], 16), int(hex_b[5:7], 16)
    r = int(ar * (1 - t) + br * t)
    g = int(ag * (1 - t) + bg * t)
    b = int(ab * (1 - t) + bb * t)
    return f"#{r:02X}{g:02X}{b:02X}"


def _asset_path(*parts: str) -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(here, "..", "..", "assets", *parts))


class LoginScreen(ctk.CTkFrame):
    def __init__(self, parent, app, **kwargs):
        super().__init__(parent, fg_color=T("bg"), corner_radius=0, **kwargs)
        self._app = app
        self._build()

    # ── IScreen protocol ──────────────────────────────────────────────────────

    def on_theme_changed(self):
        self.configure(fg_color=T("bg"))
        for w in self.winfo_children():
            w.destroy()
        self._build()

    # ── layout ────────────────────────────────────────────────────────────────

    def _build(self):
        is_dark = ctk.get_appearance_mode() == "Dark"

        # gradient background via canvas
        canvas = ctk.CTkCanvas(self, highlightthickness=0)
        canvas.place(x=0, y=0, relwidth=1, relheight=1)
        # Ensure the background doesn't intercept clicks/hover events.
        # Note: CTkCanvas.lower() is the *canvas item* API (needs tagOrId),
        # so lowering the widget must use the Tk window stacking command.
        try:
            canvas.tk.call("lower", canvas._w)
        except Exception:
            pass
        self.bind("<Configure>", lambda e: self._draw_gradient(canvas, is_dark))
        self._draw_gradient(canvas, is_dark)

        # theme toggle – top right
        theme_btn = ctk.CTkButton(
            self, text="☀" if is_dark else "🌙",
            width=44, height=44, corner_radius=22,
            font=font(18), fg_color=T("surface"),
            text_color=T("text"), hover_color=T("surface2"),
            border_width=1, border_color=T("border"),
            command=self._app.toggle_theme)
        theme_btn.place(x=972, y=12)

        # centred card
        card = ctk.CTkFrame(self, fg_color=T("surface"),
                            corner_radius=24,
                            border_width=1, border_color=T("card_border"),
                            width=460, height=540)
        card.place(relx=0.5, rely=0.5, anchor="center")
        card.pack_propagate(False)

        inner = ctk.CTkFrame(card, fg_color="transparent")
        inner.pack(expand=True, fill="both", padx=32, pady=24)

        # logo (loads real PNGs if present)
        is_dark = ctk.get_appearance_mode() == "Dark"
        logo_path = _asset_path("images", "logo_dark.png" if is_dark else "logo_light.png")
        if os.path.exists(logo_path):
            try:
                img = ctk.CTkImage(light_image=None, dark_image=None, size=(120, 120))
                # CTkImage needs a PIL image object; CustomTkinter accepts path via PIL internally
                # so we use a label with image loaded by CTkImage from file.
                from PIL import Image  # Pillow dependency
                pil = Image.open(logo_path)
                img = ctk.CTkImage(light_image=pil, dark_image=pil, size=(120, 120))
                ctk.CTkLabel(inner, text="", image=img).pack(pady=(0, 8))
                self._logo_img_ref = img  # keep alive
            except Exception:
                self._logo_img_ref = None
                self._fallback_logo(inner)
        else:
            self._fallback_logo(inner)

        ctk.CTkLabel(inner, text="AHU Control",
                     font=font(30, "bold"), text_color=T("text")).pack()
        ctk.CTkLabel(inner, text="Hospital Air Handling System",
                     font=font(14), text_color=T("text_sec")).pack(pady=(4, 28))

        # role cards row
        roles_row = ctk.CTkFrame(inner, fg_color="transparent")
        roles_row.pack(fill="x")
        roles_row.columnconfigure(0, weight=1)
        roles_row.columnconfigure(1, weight=1)

        self._build_role_card(
            roles_row,
            col=0,
            icon="🏥",
            title="Hospital",
            subtitle="Monitor & control\nAHU units",
            bg_from="#2563EB",
            bg_to="#1D4ED8",
            command=lambda: self._app.show_dashboard("hospital"),
        )
        self._build_role_card(
            roles_row,
            col=1,
            icon="🛡",
            title="Admin",
            subtitle="Full system access\n& configuration",
            bg_from="#4F46E5",
            bg_to="#3730A3",
            command=self._admin_login,
        )

        ctk.CTkLabel(inner, text="v1.0.0",
                     font=font(11), text_color=T("text_sec")).pack(pady=(24, 0))

    def _fallback_logo(self, parent):
        logo_frame = ctk.CTkFrame(parent, fg_color="#2563EB",
                                  width=72, height=72, corner_radius=20)
        logo_frame.pack_propagate(False)
        logo_frame.pack(pady=(0, 16))
        ctk.CTkLabel(logo_frame, text="ALMED", font=font(16, "bold"),
                     text_color="#FFFFFF").pack(expand=True, fill="both")

    def _build_role_card(self, parent, col, icon, title, subtitle,
                         bg_from, bg_to, command):
        card = ctk.CTkFrame(parent, fg_color=bg_from,
                            corner_radius=18,
                            border_width=1, border_color=bg_to)
        card.grid(row=0, column=col, padx=6, sticky="nsew")

        inner = ctk.CTkFrame(card, fg_color="transparent")
        inner.pack(expand=True, fill="both", padx=14, pady=18)

        # Tk (and therefore CustomTkinter) doesn't support rgba() colours.
        # Approximate a translucent white by blending with the card gradient colour.
        icon_f = ctk.CTkFrame(inner, fg_color=_mix(bg_from, "#FFFFFF", 0.18),
                              width=56, height=56, corner_radius=14)
        icon_f.pack_propagate(False)
        icon_f.pack(pady=(0, 10))
        ctk.CTkLabel(icon_f, text=icon, font=font(26),
                     text_color="#FFFFFF").pack(expand=True)

        ctk.CTkLabel(inner, text=title, font=font(16, "bold"),
                     text_color="#FFFFFF").pack()
        ctk.CTkLabel(inner, text=subtitle, font=font(11),
                     text_color="#E5E7EB",
                     justify="center").pack()

        # Make entire card reliably clickable (and hoverable) on Pi:
        # some window managers + background canvas can interfere with CTkButton overlays.
        def on_enter(_=None):
            card.configure(fg_color=bg_to)

        def on_leave(_=None):
            card.configure(fg_color=bg_from)

        def on_click(_=None):
            command()

        self._bind_recursive(card, "<Enter>", on_enter)
        self._bind_recursive(card, "<Leave>", on_leave)
        self._bind_recursive(card, "<Button-1>", on_click)

    def _bind_recursive(self, widget, sequence: str, func):
        try:
            widget.bind(sequence, func)
        except Exception:
            pass
        for child in widget.winfo_children():
            self._bind_recursive(child, sequence, func)

    def _admin_login(self):
        PasscodeDialog(
            self.winfo_toplevel(),
            on_success=lambda: self._app.show_dashboard("admin"),
        )

    def _draw_gradient(self, canvas, is_dark: bool):
        canvas.delete("all")
        w = self.winfo_width()
        h = self.winfo_height()
        if w <= 1:
            return
        steps = 60
        if is_dark:
            c1 = (15, 23, 42)
            c2 = (30, 41, 59)
        else:
            c1 = (240, 244, 248)
            c2 = (219, 234, 254)
        for i in range(steps):
            ratio = i / steps
            r = int(c1[0] + (c2[0] - c1[0]) * ratio)
            g = int(c1[1] + (c2[1] - c1[1]) * ratio)
            b = int(c1[2] + (c2[2] - c1[2]) * ratio)
            color = f"#{r:02X}{g:02X}{b:02X}"
            y0 = int(h * i / steps)
            y1 = int(h * (i + 1) / steps) + 1
            canvas.create_rectangle(0, y0, w, y1, fill=color, outline="")
