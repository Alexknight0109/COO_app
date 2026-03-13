# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  ui.py
#  Drawing primitives shared across all screens.
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import os
import pygame
import config

_HERE      = os.path.dirname(os.path.abspath(__file__))
_FONTS_DIR = os.path.join(_HERE, "assets", "fonts")
_F_REGULAR  = os.path.join(_FONTS_DIR, "Inter-Regular.otf")
_F_SEMIBOLD = os.path.join(_FONTS_DIR, "Inter-SemiBold.otf")
_F_BOLD     = os.path.join(_FONTS_DIR, "Inter-Bold.otf")


class FontCache:
    """Inter-font cache (falls back to system DejaVu if files are missing)."""
    _reg:  dict[int, pygame.font.Font] = {}
    _semi: dict[int, pygame.font.Font] = {}
    _bold: dict[int, pygame.font.Font] = {}

    @classmethod
    def _load(cls, path: str, size: int) -> pygame.font.Font:
        if os.path.exists(path):
            return pygame.font.Font(path, size)
        return pygame.font.SysFont("dejavusans", size)

    @classmethod
    def get(cls, size: int) -> pygame.font.Font:
        if size not in cls._reg:
            cls._reg[size] = cls._load(_F_REGULAR, size)
        return cls._reg[size]

    @classmethod
    def semibold(cls, size: int) -> pygame.font.Font:
        if size not in cls._semi:
            cls._semi[size] = cls._load(_F_SEMIBOLD, size)
        return cls._semi[size]

    @classmethod
    def bold(cls, size: int) -> pygame.font.Font:
        if size not in cls._bold:
            cls._bold[size] = cls._load(_F_BOLD, size)
        return cls._bold[size]

    @classmethod
    def clear(cls) -> None:
        cls._reg.clear(); cls._semi.clear(); cls._bold.clear()


def draw_text(
    surf: pygame.Surface,
    text: str,
    font: pygame.font.Font,
    color: tuple,
    pos: tuple,
    anchor: str = "topleft",
) -> pygame.Rect:
    img = font.render(text, True, color)
    r   = img.get_rect()
    setattr(r, anchor, pos)
    surf.blit(img, r)
    return r


def draw_rounded_rect(
    surf: pygame.Surface,
    color: tuple,
    rect: pygame.Rect,
    radius: int = config.CARD_RADIUS,
    border_color: tuple | None = None,
    border_width: int = 1,
) -> None:
    pygame.draw.rect(surf, color, rect, border_radius=radius)
    if border_color:
        pygame.draw.rect(surf, border_color, rect, border_width, border_radius=radius)


def draw_pill(
    surf: pygame.Surface,
    text: str,
    font: pygame.font.Font,
    bg: tuple,
    fg: tuple,
    center: tuple,
    pad_x: int = 8,
    pad_y: int = 4,
) -> pygame.Rect:
    """Filled pill badge (fully rounded). Returns bounding Rect."""
    img = font.render(text, True, fg)
    tw, th = img.get_size()
    w  = tw + pad_x * 2
    h  = th + pad_y * 2
    r  = pygame.Rect(0, 0, w, h)
    r.center = center
    pygame.draw.rect(surf, bg, r, border_radius=h // 2)
    surf.blit(img, (r.x + pad_x, r.y + pad_y))
    return r


def draw_button(
    surf: pygame.Surface,
    rect: pygame.Rect,
    label: str,
    font: pygame.font.Font,
    bg: tuple,
    fg: tuple,
    radius: int = 8,
    border: tuple | None = None,
) -> None:
    pygame.draw.rect(surf, bg, rect, border_radius=radius)
    if border:
        pygame.draw.rect(surf, border, rect, 1, border_radius=radius)
    draw_text(surf, label, font, fg, rect.center, anchor="center")


def draw_topbar(
    surf: pygame.Surface,
    left_text: str | None  = None,
    title: str             = "",
    right_text: str | None = None,
    left_color: tuple      = None,
    right_color: tuple     = None,
    dots: list | None      = None,
) -> None:
    """Standard top-bar: optional left label, centre title, optional right label + dots."""
    W  = config.SCREEN_W
    H  = config.TOPBAR_H
    cx = W // 2
    cy = H // 2

    # subtle bottom separator
    pygame.draw.line(surf, config.C_BORDER, (0, H - 1), (W, H - 1))

    f_title = FontCache.semibold(15)
    f_side  = FontCache.semibold(13)

    if left_text:
        draw_text(surf, left_text, f_side, left_color or config.C_PRIMARY,
                  (12, cy), anchor="midleft")

    if title:
        draw_text(surf, title, f_title, config.C_TEXT, (cx, cy), anchor="center")

    # status dots (drawn right-to-left before right_text)
    dot_x = W - 10
    if dots:
        for color in reversed(dots):
            pygame.draw.circle(surf, color, (dot_x, cy), 5)
            dot_x -= 14

    if right_text:
        draw_text(surf, right_text, f_side, right_color or config.C_DIM,
                  (dot_x - 4, cy), anchor="midright")


def dot(surf: pygame.Surface, color: tuple, pos: tuple, radius: int = 5) -> None:
    pygame.draw.circle(surf, color, pos, radius)


def draw_h_rule(surf: pygame.Surface, y: int, color: tuple = None) -> None:
    """Thin horizontal separator line."""
    pygame.draw.line(surf, color or config.C_BORDER, (0, y), (config.SCREEN_W, y))
