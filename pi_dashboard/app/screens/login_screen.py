"""
Login screen  –  role selection (Hospital | Admin).
Admin requires passcode dialog.
"""
import customtkinter as ctk
from app.theme import T, font
from app.widgets.passcode_dialog import PasscodeDialog


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

        # logo
        logo_frame = ctk.CTkFrame(inner, fg_color="#2563EB",
                                  width=72, height=72, corner_radius=20)
        logo_frame.pack_propagate(False)
        logo_frame.pack(pady=(0, 16))
        ctk.CTkLabel(logo_frame, text="💨", font=font(32)).pack(
            expand=True, fill="both")

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

    def _build_role_card(self, parent, col, icon, title, subtitle,
                         bg_from, bg_to, command):
        card = ctk.CTkFrame(parent, fg_color=bg_from,
                            corner_radius=18,
                            border_width=1, border_color=bg_to)
        card.grid(row=0, column=col, padx=6, sticky="nsew")

        btn = ctk.CTkButton(
            card,
            text="",
            fg_color="transparent",
            hover_color=bg_to,
            height=170,
            corner_radius=18,
            command=command,
        )
        btn.place(x=0, y=0, relwidth=1, relheight=1)

        inner = ctk.CTkFrame(card, fg_color="transparent")
        inner.pack(expand=True, fill="both", padx=14, pady=18)

        icon_f = ctk.CTkFrame(inner, fg_color="rgba(255,255,255,0.15)",
                              width=56, height=56, corner_radius=14)
        icon_f.pack_propagate(False)
        icon_f.pack(pady=(0, 10))
        ctk.CTkLabel(icon_f, text=icon, font=font(26),
                     text_color="#FFFFFF").pack(expand=True)

        ctk.CTkLabel(inner, text=title, font=font(16, "bold"),
                     text_color="#FFFFFF").pack()
        ctk.CTkLabel(inner, text=subtitle, font=font(11),
                     text_color="rgba(255,255,255,0.8)",
                     justify="center").pack()

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
