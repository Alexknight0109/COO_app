# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_scan.py
#  Screen 1 — Splash + Scanning
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import time
import pygame
import config
from ui import draw_rounded_rect, draw_text, draw_pill, FontCache


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

        elapsed = min(self.elapsed(), config.DISCOVERY_WAIT_S)
        pct     = elapsed / config.DISCOVERY_WAIT_S

        f_xs    = FontCache.get(11)
        f_sm    = FontCache.semibold(13)
        f_brand = FontCache.bold(42)
        f_sub   = FontCache.get(14)

        # ── Center logo block ────────────────────────────────────────────────
        logo_cy = H // 2 - 26
        draw_text(surf, "ALMED", f_brand, config.C_PRIMARY,
                  (W // 2, logo_cy), anchor="center")
        draw_text(surf, "AHU Eco Display", f_sub, config.C_DIM,
                  (W // 2, logo_cy + 36), anchor="center")

        # ── Progress bar ─────────────────────────────────────────────────────
        bar_y  = logo_cy + 64
        bar_w  = 260
        bar_h  = 5
        bx     = (W - bar_w) // 2
        bg_r   = pygame.Rect(bx, bar_y, bar_w, bar_h)
        fill_r = pygame.Rect(bx, bar_y, int(bar_w * pct), bar_h)
        draw_rounded_rect(surf, config.C_CARD2, bg_r, radius=3)
        if pct > 0:
            draw_rounded_rect(surf, config.C_PRIMARY, fill_r, radius=3)

        # ── Status below bar ─────────────────────────────────────────────────
        if not devices:
            status = "Connecting to MQTT broker…" if not mqtt_ok else "Scanning for AHU devices…"
            draw_text(surf, status, f_xs, config.C_DIM,
                      (W // 2, bar_y + 14), anchor="center")
        else:
            count = len(devices)
            label = f"Found {count} device{'s' if count != 1 else ''}"
            draw_text(surf, label, f_sm, config.C_GREEN,
                      (W // 2, bar_y + 14), anchor="center")

        # ── Discovered device pills (up to 3) ────────────────────────────────
        pill_y = bar_y + 36
        for i, dev in enumerate(devices[:3]):
            name  = dev.display_name or f"{dev.site}/{dev.ahu}"
            draw_pill(
                surf, name,
                FontCache.get(12),
                config.C_CARD2, config.C_TEXT,
                center=(W // 2, pill_y + i * 26),
                pad_x=14, pad_y=5,
            )

        # ── Connection status dots (bottom-right) ────────────────────────────
        dot_y = H - 12
        pygame.draw.circle(surf, config.C_GREEN if mqtt_ok else config.C_RED,
                           (W - 22, dot_y), 5)
        pygame.draw.circle(surf, config.C_GREEN if wifi_ok  else config.C_RED,
                           (W - 10, dot_y), 5)
        draw_text(surf, "MQTT  WiFi", FontCache.get(10), config.C_DIM,
                  (W - 32, dot_y), anchor="midright")

        # ── Skip hint ────────────────────────────────────────────────────────
        draw_text(surf, "Tap to skip", f_xs, config.C_DIM,
                  (W // 2, H - 8), anchor="midbottom")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple) -> str:
        return "select"

    def auto_advance(self) -> bool:
        return self.elapsed() >= config.DISCOVERY_WAIT_S
