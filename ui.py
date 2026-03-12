# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  ui.py
#  Low-level Pygame drawing helpers shared by all screens.
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import math
import pygame
import config


def draw_rounded_rect(
    surf: pygame.Surface,
    color: tuple,
    rect: pygame.Rect,
    radius: int = config.CARD_RADIUS,
    border_color: tuple | None = None,
    border_width: int = 1,
) -> None:
    """Fill a rounded-corner rectangle, then optionally draw a border."""
    pygame.draw.rect(surf, color, rect, border_radius=radius)
    if border_color:
        pygame.draw.rect(surf, border_color, rect, border_width, border_radius=radius)


def draw_text(
    surf: pygame.Surface,
    text: str,
    font: pygame.font.Font,
    color: tuple,
    pos: tuple,
    anchor: str = "topleft",
) -> pygame.Rect:
    """
    Render text at *pos* with the given anchor.
    anchor: 'topleft' | 'midleft' | 'center' | 'midright' | 'topright' | 'bottomleft' | 'midbottom'
    Returns the bounding Rect.
    """
    surf_text = font.render(text, True, color)
    r = surf_text.get_rect()
    setattr(r, anchor, pos)
    surf.blit(surf_text, r)
    return r


def draw_button(
    surf: pygame.Surface,
    rect: pygame.Rect,
    label: str,
    font: pygame.font.Font,
    bg: tuple,
    fg: tuple,
    radius: int = 6,
) -> None:
    draw_rounded_rect(surf, bg, rect, radius=radius)
    draw_text(surf, label, font, fg, rect.center, anchor="center")


def dot(
    surf: pygame.Surface,
    color: tuple,
    pos: tuple,
    radius: int = 5,
) -> None:
    pygame.draw.circle(surf, color, pos, radius)


class FontCache:
    """Lazy singleton that caches pygame fonts by size."""
    _cache: dict[int, pygame.font.Font] = {}

    @classmethod
    def get(cls, size: int) -> pygame.font.Font:
        if size not in cls._cache:
            cls._cache[size] = pygame.font.SysFont("dejavusans", size)
        return cls._cache[size]

    @classmethod
    def clear(cls) -> None:
        cls._cache.clear()
