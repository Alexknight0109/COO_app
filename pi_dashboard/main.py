import customtkinter as ctk
import os
import sys

# Ensure app package is importable
sys.path.insert(0, os.path.dirname(__file__))

from app.state.app_provider import AppProvider


def _is_raspberry_pi() -> bool:
    try:
        with open("/proc/cpuinfo") as f:
            content = f.read()
            return "Raspberry" in content or "BCM" in content
    except Exception:
        return False


class App:
    def __init__(self):
        ctk.set_appearance_mode("Dark")
        ctk.set_default_color_theme("blue")

        self.root = ctk.CTk()
        self.root.title("AHU Control Panel")
        self.root.geometry("1024x600")
        self.root.resizable(False, False)
        self.root.configure(fg_color="#0F172A")

        self._is_pi = _is_raspberry_pi()
        if self._is_pi:
            self.root.attributes("-fullscreen", True)
            # Cursor should be visible by default.
            # If you want kiosk-style hidden cursor, launch with:
            #   HIDE_CURSOR=1 ./venv/bin/python main.py
            if os.environ.get("HIDE_CURSOR", "").strip() in ("1", "true", "TRUE", "yes", "YES"):
                self.root.config(cursor="none")

        self.provider = AppProvider(self.root)
        self.user_role: str = "hospital"
        self.current_screen = None

        self._poll_id = None
        self._start_polling()
        self.show_login()

    def _start_polling(self):
        def poll():
            self.provider.poll()
            self._poll_id = self.root.after(100, poll)
        poll()

    def show_login(self):
        from app.screens.login_screen import LoginScreen
        self._switch_screen(LoginScreen)

    def show_dashboard(self, role: str):
        from app.screens.dashboard_screen import DashboardScreen
        self.user_role = role
        self._switch_screen(DashboardScreen, role=role)

    def show_ahu_control(self, ahu_id: str):
        from app.screens.ahu_control_screen import AhuControlScreen
        self._switch_screen(AhuControlScreen, ahu_id=ahu_id, role=self.user_role)

    def show_admin_settings(self):
        from app.screens.admin_screen import AdminScreen
        self._switch_screen(AdminScreen)

    def toggle_theme(self):
        current = ctk.get_appearance_mode()
        new_mode = "Light" if current == "Dark" else "Dark"
        ctk.set_appearance_mode(new_mode)
        self.provider.is_dark = (new_mode == "Dark")
        # Rebuild current screen to pick up new theme
        if self.current_screen:
            self.current_screen.on_theme_changed()

    def _switch_screen(self, screen_class, **kwargs):
        if self.current_screen is not None:
            self.current_screen.destroy()
            self.current_screen = None
        self.current_screen = screen_class(self.root, app=self, **kwargs)
        self.current_screen.pack(fill="both", expand=True)

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    app = App()
    app.run()
