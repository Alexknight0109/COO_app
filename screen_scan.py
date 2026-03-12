# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_scan.py
#
#  Screen 1 — Scanning
#    • Progress bar fills over DISCOVERY_WAIT_S seconds
#    • Lists discovered AHU devices as they arrive
#    • Any tap skips straight to device-select
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import time
import pygame
import config
from ui import draw_rounded_rect, draw_text, dot, FontCache


class ScanScreen:
    def __init__(self) -> None:
        self._start = time.monotonic()

    def reset(self) -> None:
        self._start = time.monotonic()

    def elapsed(self) -> float:
        return time.monotonic() - self._start

    # ── Draw ─────────────────────────────────────────────────────────────────

    def draw(
        self,
        surf: pygame.Surface,
        devices: list,
        mqtt_ok: bool,
        wifi_ok: bool,
    ) -> None:
        W, H = config.SCREEN_W, config.SCREEN_H
        surf.fill(config.C_BG)

        f_sm  = FontCache.get(13)
        f_med = FontCache.get(16)
        f_lg  = FontCache.get(36)

        # ── Top bar ──────────────────────────────────────────────────────────
        topbar = pygame.Rect(0, 0, W, config.TOPBAR_H)
        draw_rounded_rect(surf, config.C_TOPBAR, topbar, radius=0)
        draw_text(surf, "ALMED  Scanning…", f_med, config.C_TEXT,
                  (W // 2, config.TOPBAR_H // 2), anchor="center")

        dot(surf, config.C_GREEN if mqtt_ok else config.C_RED, (W - 22, config.TOPBAR_H // 2), 5)
        dot(surf, config.C_GREEN if wifi_ok  else config.C_RED, (W - 10, config.TOPBAR_H // 2), 5)

        # ── Progress bar ─────────────────────────────────────────────────────
        elapsed = min(self.elapsed(), config.DISCOVERY_WAIT_S)
        pct     = elapsed / config.DISCOVERY_WAIT_S
        bar_y   = config.TOPBAR_H + 6
        bar_h   = 6
        bar_w   = W - 24
        bg_rect  = pygame.Rect(12, bar_y, bar_w, bar_h)
        fill_rect = pygame.Rect(12, bar_y, int(bar_w * pct), bar_h)
        draw_rounded_rect(surf, config.C_TOPBAR, bg_rect, radius=3)
        if pct > 0:
            draw_rounded_rect(surf, config.C_PRIMARY, fill_rect, radius=3)

        # ── Discovered devices ────────────────────────────────────────────────
        draw_text(surf, "Found devices:", f_sm, config.C_DIM,
                  (12, config.TOPBAR_H + 18))

        y = config.TOPBAR_H + 36
        for dev in devices:
            rect = pygame.Rect(6, y, W - 12, 28)
            draw_rounded_rect(surf, config.C_CARD, rect, border_color=config.C_PRIMARY)
            dot(surf, config.C_GREEN, (20, y + 14), 5)
            label = f"{dev.site} / {dev.room} / {dev.ahu}"
            draw_text(surf, label, f_sm, config.C_TEXT, (32, y + 14), anchor="midleft")
            if dev.ip:
                draw_text(surf, dev.ip, f_sm, config.C_DIM, (W - 10, y + 14), anchor="midright")
            y += 34
            if y > H - 30:
                break

        if not devices:
            draw_text(surf, "Waiting for AHU devices…", f_sm, config.C_DIM,
                      (W // 2, H // 2), anchor="center")
            draw_text(surf, "Make sure ESP32 AHUs are powered on.", f_sm, config.C_DIM,
                      (W // 2, H // 2 + 18), anchor="center")

        # ── Hint ─────────────────────────────────────────────────────────────
        draw_text(surf, "Tap anywhere to skip", f_sm, config.C_DIM,
                  (W // 2, H - 8), anchor="midbottom")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple) -> str:
        """Any tap → go to select screen."""
        return "select"

    def auto_advance(self) -> bool:
        """Returns True when the discovery timer has expired."""
        return self.elapsed() >= config.DISCOVERY_WAIT_S
