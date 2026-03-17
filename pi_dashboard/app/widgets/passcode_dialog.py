"""
Modal passcode entry dialogs.
- PasscodeDialog     : 4-digit admin passcode (hardcoded "1234")
- ScreenUnlockDialog : 6-digit screen-unlock passcode (from AppProvider)
- ChangePasscodeDialog: 3-step 6-digit numpad to change screen passcode
"""
import customtkinter as ctk
from app.theme import T, AMBER, ERROR, font


# ── shared numpad helpers ─────────────────────────────────────────────────────

def _build_numpad(parent, on_digit: callable, on_clear: callable,
                  btn_size: int = 72, color: str = "#3B82F6"):
    """
    3×4 grid numpad (1-9, *, 0, #).
    * = clear/backspace   # = confirm (handled by caller via on_digit('CONFIRM'))
    """
    digits = [
        ("1", "2", "3"),
        ("4", "5", "6"),
        ("7", "8", "9"),
        ("⌫", "0", "✓"),
    ]
    pad = ctk.CTkFrame(parent, fg_color="transparent")
    for r, row in enumerate(digits):
        for c, label in enumerate(row):
            if label == "⌫":
                cmd = on_clear
                fg  = T("surface2")
                tc  = T("text_sec")
                hov = T("border")
            elif label == "✓":
                cmd = lambda: on_digit("CONFIRM")
                fg  = color
                tc  = "#FFFFFF"
                hov = _darken(color)
            else:
                cmd = lambda l=label: on_digit(l)
                fg  = T("surface")
                tc  = T("text")
                hov = T("surface2")

            btn = ctk.CTkButton(
                pad, text=label, width=btn_size, height=btn_size,
                font=font(22, "bold"), corner_radius=14,
                fg_color=fg, text_color=tc, hover_color=hov,
                border_width=1, border_color=T("border"),
                command=cmd,
            )
            btn.grid(row=r, column=c, padx=4, pady=4)
    return pad


def _darken(hex_col: str, amount: int = 30) -> str:
    r = max(0, int(hex_col[1:3], 16) - amount)
    g = max(0, int(hex_col[3:5], 16) - amount)
    b = max(0, int(hex_col[5:7], 16) - amount)
    return f"#{r:02X}{g:02X}{b:02X}"


def _dot_row(parent, length: int, color: str):
    row = ctk.CTkFrame(parent, fg_color="transparent")
    labels = []
    for _ in range(length):
        lbl = ctk.CTkLabel(row, text="●", font=font(20), text_color=T("border"))
        lbl.pack(side="left", padx=6)
        labels.append(lbl)
    return row, labels


# ── PasscodeDialog ────────────────────────────────────────────────────────────

class PasscodeDialog(ctk.CTkToplevel):
    CORRECT = "1234"
    LENGTH  = 4

    def __init__(self, parent, on_success: callable, on_cancel: callable = None):
        super().__init__(parent)
        self.on_success = on_success
        self.on_cancel  = on_cancel
        self._code = ""

        self.title("")
        self.geometry("420x520")
        self.resizable(False, False)
        self.configure(fg_color=T("surface"))
        self.grab_set()
        self._center(parent)
        self._build()

    def _center(self, parent):
        self.update_idletasks()
        pw = parent.winfo_rootx() + parent.winfo_width()  // 2
        ph = parent.winfo_rooty() + parent.winfo_height() // 2
        w, h = 420, 520
        self.geometry(f"{w}x{h}+{pw - w//2}+{ph - h//2}")

    def _build(self):
        card = ctk.CTkFrame(self, fg_color=T("surface"),
                            corner_radius=24,
                            border_width=1, border_color=T("border"))
        card.pack(fill="both", expand=True, padx=2, pady=2)

        # icon
        icon_frame = ctk.CTkFrame(card, fg_color="#1D4ED8",
                                  width=72, height=72, corner_radius=18)
        icon_frame.pack_propagate(False)
        icon_frame.pack(pady=(32, 0))
        ctk.CTkLabel(icon_frame, text="🔐", font=font(30)).pack(
            expand=True, fill="both")

        ctk.CTkLabel(card, text="Admin Access",
                     font=font(20, "bold"), text_color=T("text")).pack(pady=(16, 2))
        ctk.CTkLabel(card, text="Enter 4-digit passcode",
                     font=font(13), text_color=T("text_sec")).pack()

        self._dots_frame = ctk.CTkFrame(card, fg_color="transparent")
        self._dots_frame.pack(pady=20)
        self._dot_row, self._dots = _dot_row(self._dots_frame, self.LENGTH, "#3B82F6")
        self._dot_row.pack()

        self._error_lbl = ctk.CTkLabel(card, text="", font=font(12),
                                       text_color=ERROR)
        self._error_lbl.pack()

        pad = _build_numpad(card, self._on_digit, self._on_clear,
                            btn_size=66, color="#3B82F6")
        pad.pack(pady=8)

        ctk.CTkButton(card, text="Cancel", width=200, height=40,
                      font=font(13), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"),
                      hover_color=T("surface2"),
                      command=self._cancel).pack(pady=(4, 16))

    def _on_digit(self, d: str):
        if d == "CONFIRM":
            self._verify()
            return
        if len(self._code) < self.LENGTH:
            self._code += d
            self._update_dots()

    def _on_clear(self):
        self._code = self._code[:-1]
        self._error_lbl.configure(text="")
        self._update_dots()

    def _update_dots(self):
        for i, dot in enumerate(self._dots):
            if i < len(self._code):
                dot.configure(text_color="#3B82F6")
            else:
                dot.configure(text_color=T("border"))

    def _verify(self):
        if self._code == self.CORRECT:
            self.destroy()
            self.on_success()
        else:
            self._error_lbl.configure(text="Incorrect passcode")
            self._code = ""
            self._update_dots()

    def _cancel(self):
        self.destroy()
        if self.on_cancel:
            self.on_cancel()


# ── ScreenUnlockDialog ────────────────────────────────────────────────────────

class ScreenUnlockDialog(ctk.CTkToplevel):
    LENGTH = 6

    def __init__(self, parent, provider, on_success: callable,
                 on_cancel: callable = None):
        super().__init__(parent)
        self._provider  = provider
        self.on_success = on_success
        self.on_cancel  = on_cancel
        self._code = ""

        self.title("")
        self.geometry("420x540")
        self.resizable(False, False)
        self.configure(fg_color=T("surface"))
        self.grab_set()
        self._center(parent)
        self._build()

    def _center(self, parent):
        self.update_idletasks()
        pw = parent.winfo_rootx() + parent.winfo_width()  // 2
        ph = parent.winfo_rooty() + parent.winfo_height() // 2
        w, h = 420, 540
        self.geometry(f"{w}x{h}+{pw - w//2}+{ph - h//2}")

    def _build(self):
        card = ctk.CTkFrame(self, fg_color=T("surface"),
                            corner_radius=24,
                            border_width=1, border_color=T("border"))
        card.pack(fill="both", expand=True, padx=2, pady=2)

        icon_frame = ctk.CTkFrame(card, fg_color="#92400E",
                                  width=72, height=72, corner_radius=18)
        icon_frame.pack_propagate(False)
        icon_frame.pack(pady=(32, 0))
        ctk.CTkLabel(icon_frame, text="🔒", font=font(30)).pack(
            expand=True, fill="both")

        ctk.CTkLabel(card, text="Screen Locked",
                     font=font(20, "bold"), text_color=T("text")).pack(pady=(16, 2))
        ctk.CTkLabel(card, text="Enter 6-digit unlock code",
                     font=font(13), text_color=T("text_sec")).pack()

        self._dots_frame = ctk.CTkFrame(card, fg_color="transparent")
        self._dots_frame.pack(pady=20)
        self._dot_row, self._dots = _dot_row(self._dots_frame, self.LENGTH, AMBER)
        self._dot_row.pack()

        self._error_lbl = ctk.CTkLabel(card, text="", font=font(12),
                                       text_color=ERROR)
        self._error_lbl.pack()

        pad = _build_numpad(card, self._on_digit, self._on_clear,
                            btn_size=64, color=AMBER)
        pad.pack(pady=4)

        ctk.CTkButton(card, text="Cancel", width=200, height=40,
                      font=font(13), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"),
                      hover_color=T("surface2"),
                      command=self._cancel).pack(pady=(4, 16))

    def _on_digit(self, d: str):
        if d == "CONFIRM":
            self._verify()
            return
        if len(self._code) < self.LENGTH:
            self._code += d
            self._update_dots()
            if len(self._code) == self.LENGTH:
                self.after(200, self._verify)

    def _on_clear(self):
        self._code = self._code[:-1]
        self._error_lbl.configure(text="")
        self._update_dots()

    def _update_dots(self):
        for i, dot in enumerate(self._dots):
            dot.configure(text_color=AMBER if i < len(self._code) else T("border"))

    def _verify(self):
        if self._provider.unlock_screen(self._code):
            self.destroy()
            self.on_success()
        else:
            self._error_lbl.configure(text="Incorrect passcode")
            self._code = ""
            self._update_dots()

    def _cancel(self):
        self.destroy()
        if self.on_cancel:
            self.on_cancel()


# ── ChangePasscodeDialog ──────────────────────────────────────────────────────

class ChangePasscodeDialog(ctk.CTkToplevel):
    LENGTH = 6

    def __init__(self, parent, provider, on_done: callable = None):
        super().__init__(parent)
        self._provider = provider
        self.on_done   = on_done
        self._step     = 0    # 0=old, 1=new, 2=confirm
        self._old_code = ""
        self._new_code = ""
        self._code     = ""

        self.title("")
        self.geometry("420x580")
        self.resizable(False, False)
        self.configure(fg_color=T("surface"))
        self.grab_set()
        self._center(parent)
        self._build()

    def _center(self, parent):
        self.update_idletasks()
        pw = parent.winfo_rootx() + parent.winfo_width()  // 2
        ph = parent.winfo_rooty() + parent.winfo_height() // 2
        w, h = 420, 580
        self.geometry(f"{w}x{h}+{pw - w//2}+{ph - h//2}")

    def _build(self):
        self._card = ctk.CTkFrame(self, fg_color=T("surface"),
                                  corner_radius=24,
                                  border_width=1, border_color=T("border"))
        self._card.pack(fill="both", expand=True, padx=2, pady=2)
        self._render_step()

    def _render_step(self):
        for w in self._card.winfo_children():
            w.destroy()

        titles  = ["Current Code", "New Code", "Confirm New Code"]
        subtitles = [
            "Enter your current 6-digit passcode",
            "Enter a new 6-digit passcode",
            "Re-enter your new passcode",
        ]

        # Step indicator
        ind = ctk.CTkFrame(self._card, fg_color="transparent")
        ind.pack(pady=(28, 0))
        for i in range(3):
            active = i == self._step
            dot = ctk.CTkFrame(ind, fg_color=AMBER if active else T("border"),
                               width=10, height=10, corner_radius=5)
            dot.pack_propagate(False)
            dot.pack(side="left", padx=4)

        ctk.CTkLabel(self._card, text=titles[self._step],
                     font=font(20, "bold"), text_color=T("text")).pack(pady=(20, 2))
        ctk.CTkLabel(self._card, text=subtitles[self._step],
                     font=font(13), text_color=T("text_sec")).pack()

        self._dot_row, self._dots = _dot_row(
            ctk.CTkFrame(self._card, fg_color="transparent"), self.LENGTH, AMBER)
        self._dot_row.master.pack(pady=20)
        self._dot_row.pack()

        self._error_lbl = ctk.CTkLabel(self._card, text="",
                                       font=font(12), text_color=ERROR)
        self._error_lbl.pack()

        pad = _build_numpad(self._card, self._on_digit, self._on_clear,
                            btn_size=62, color=AMBER)
        pad.pack(pady=4)

        ctk.CTkButton(self._card, text="Cancel", width=200, height=38,
                      font=font(13), fg_color="transparent",
                      border_width=1, border_color=T("border"),
                      text_color=T("text_sec"),
                      hover_color=T("surface2"),
                      command=self.destroy).pack(pady=(4, 16))

    def _on_digit(self, d: str):
        if d == "CONFIRM":
            self._advance()
            return
        if len(self._code) < self.LENGTH:
            self._code += d
            self._update_dots()
            if len(self._code) == self.LENGTH:
                self.after(300, self._advance)

    def _on_clear(self):
        self._code = self._code[:-1]
        self._error_lbl.configure(text="")
        self._update_dots()

    def _update_dots(self):
        for i, dot in enumerate(self._dots):
            dot.configure(text_color=AMBER if i < len(self._code) else T("border"))

    def _advance(self):
        if len(self._code) < self.LENGTH:
            self._error_lbl.configure(text="Please enter all 6 digits")
            return
        if self._step == 0:
            if self._code != self._provider.screen_lock_passcode:
                self._error_lbl.configure(text="Incorrect current passcode")
                self._code = ""
                self._update_dots()
                return
            self._old_code = self._code
            self._code = ""
            self._step = 1
            self._render_step()
        elif self._step == 1:
            self._new_code = self._code
            self._code = ""
            self._step = 2
            self._render_step()
        else:
            if self._code != self._new_code:
                self._error_lbl.configure(text="Codes don't match")
                self._code = ""
                self._update_dots()
                return
            self._provider.change_passcode(self._new_code)
            self.destroy()
            if self.on_done:
                self.on_done()
