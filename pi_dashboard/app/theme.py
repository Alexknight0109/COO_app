"""
Centralised colour/font constants.  Import `T` then call T.bg(), T.text(), etc.
to get the right value for the current appearance mode.
"""
import customtkinter as ctk

# ── Palette ──────────────────────────────────────────────────────────────────

_DARK = {
    "bg":            "#0F172A",
    "surface":       "#1E293B",
    "surface2":      "#263348",
    "primary":       "#3B82F6",
    "primary_hov":   "#2563EB",
    "secondary":     "#60A5FA",
    "text":          "#F1F5F9",
    "text_sec":      "#94A3B8",
    "border":        "#334155",
    "card":          "#1E293B",
    "card_border":   "#2D3F55",
    "input_bg":      "#1E293B",
    "topbar":        "#0F172A",
}

_LIGHT = {
    "bg":            "#F0F4F8",
    "surface":       "#FFFFFF",
    "surface2":      "#F8FAFC",
    "primary":       "#2563EB",
    "primary_hov":   "#1D4ED8",
    "secondary":     "#3B82F6",
    "text":          "#1F2937",
    "text_sec":      "#6B7280",
    "border":        "#E2E8F0",
    "card":          "#FFFFFF",
    "card_border":   "#D1D9E6",
    "input_bg":      "#F8FAFC",
    "topbar":        "#FFFFFF",
}

# Accent colours – same in both modes
SUCCESS    = "#10B981"
ERROR      = "#EF4444"
WARNING    = "#F59E0B"
INFO       = "#3B82F6"
TEMP_COL   = "#3B82F6"
HUM_COL    = "#60A5FA"
CYAN       = "#06B6D4"
TEAL       = "#14B8A6"
INDIGO     = "#6366F1"
PURPLE     = "#8B5CF6"
ORANGE     = "#F97316"
PINK       = "#EC4899"
RED        = "#EF4444"
AMBER      = "#F59E0B"

# Darker tinted surface versions of accent colours (10-15 % opacity emulation)
def _tint(hex_col: str, alpha: float, over_dark: bool) -> str:
    """Blend hex_col over dark/light surface at given alpha (0-1)."""
    r = int(hex_col[1:3], 16)
    g = int(hex_col[3:5], 16)
    b = int(hex_col[5:7], 16)
    bg = (15, 23, 42) if over_dark else (240, 244, 248)
    rr = int(bg[0] * (1 - alpha) + r * alpha)
    gg = int(bg[1] * (1 - alpha) + g * alpha)
    bb = int(bg[2] * (1 - alpha) + b * alpha)
    return f"#{rr:02X}{gg:02X}{bb:02X}"


def accent_bg(hex_col: str, alpha: float = 0.15) -> str:
    dark = ctk.get_appearance_mode() == "Dark"
    return _tint(hex_col, alpha, dark)


# ── Font helpers ──────────────────────────────────────────────────────────────

FONT_FAMILY = "Helvetica"
MONO_FAMILY = "Courier"

def font(size: int = 14, weight: str = "normal") -> tuple:
    return (FONT_FAMILY, size, weight)

def mono(size: int = 12) -> tuple:
    return (MONO_FAMILY, size, "normal")


# ── Theme accessor ────────────────────────────────────────────────────────────

class _T:
    def __call__(self, key: str) -> str:
        dark = ctk.get_appearance_mode() == "Dark"
        return _DARK[key] if dark else _LIGHT[key]

    # convenience shortcuts
    def bg(self):       return self("bg")
    def surface(self):  return self("surface")
    def surface2(self): return self("surface2")
    def primary(self):  return self("primary")
    def text(self):     return self("text")
    def text_sec(self): return self("text_sec")
    def border(self):   return self("border")
    def card(self):     return self("card")
    def card_b(self):   return self("card_border")
    def topbar(self):   return self("topbar")
    def input_bg(self): return self("input_bg")


T = _T()
