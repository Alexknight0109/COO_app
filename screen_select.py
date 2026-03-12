# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_select.py
#
#  Screen 2 — Device Select
#    • Scrollable list of discovered AHU units
#    • Tap a row to open its control screen
#    • Active device shown with green border + "ACTIVE" badge
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import pygame
import config
from ui import draw_rounded_rect, draw_text, dot, FontCache


class SelectScreen:
    """
    Dashboard-style device list, inspired by ahu_dashboard:
      • Left: ALMED wordmark
      • Center: 'Dashboard' title
      • Right: connection dots
      • Body: modern cards for each AHU with temp/hum + status chip
    """

    def __init__(self) -> None:
        self._scroll = 0          # first visible row index

    def reset_scroll(self) -> None:
        self._scroll = 0

    # ── Draw ─────────────────────────────────────────────────────────────────

    def draw(
        self,
        surf: pygame.Surface,
        devices: list,
        selected_key: str | None,
        mqtt_ok: bool,
        wifi_ok: bool,
    ) -> None:
        W, H = config.SCREEN_W, config.SCREEN_H
        surf.fill(config.C_BG)

        f_xs  = FontCache.get(11)
        f_sm  = FontCache.get(13)
        f_md  = FontCache.get(16)
        f_lg  = FontCache.get(20)

        # ── Top bar (ALMED + Dashboard + status dots) ────────────────────────
        topbar = pygame.Rect(0, 0, W, config.TOPBAR_H)
        draw_rounded_rect(surf, config.C_TOPBAR, topbar, radius=0)

        # ALMED wordmark on left
        draw_text(
            surf,
            "ALMED",
            f_lg,
            config.C_TEXT,
            (10, config.TOPBAR_H // 2),
            anchor="midleft",
        )

        # Dashboard title centre
        draw_text(
            surf,
            "Dashboard",
            f_md,
            config.C_TEXT,
            (W // 2, config.TOPBAR_H // 2),
            anchor="center",
        )

        # Connection dots on right (MQTT + WiFi)
        dot(surf, config.C_GREEN if mqtt_ok else config.C_RED, (W - 24, config.TOPBAR_H // 2), 5)
        dot(surf, config.C_GREEN if wifi_ok  else config.C_RED, (W - 10, config.TOPBAR_H // 2), 5)

        if not devices:
            draw_text(
                surf,
                "No AHU devices discovered yet.",
                f_sm,
                config.C_DIM,
                (W // 2, H // 2 - 10),
                anchor="center",
            )
            draw_text(
                surf,
                "Power on ESP32 AHUs and check WiFi.",
                f_sm,
                config.C_DIM,
                (W // 2, H // 2 + 10),
                anchor="center",
            )
            draw_text(
                surf,
                "Scanning…",
                f_md,
                config.C_PRIMARY,
                (W // 2, H // 2 + 36),
                anchor="center",
            )
            self._draw_bottom_bar(surf, W, H, f_sm)
            return

        # ── Device cards ─────────────────────────────────────────────────────
        visible_start = config.TOPBAR_H + 6
        for row in range(config.LIST_ROWS):
            idx = self._scroll + row
            if idx >= len(devices):
                break
            dev = devices[idx]
            ry = visible_start + row * config.LIST_ROW_H
            self._draw_card(surf, dev, ry, W, selected_key, f_xs, f_sm, f_md)

        # ── Scroll hint ──────────────────────────────────────────────────────
        if self._scroll + config.LIST_ROWS < len(devices):
            draw_text(
                surf,
                "▼",
                f_md,
                config.C_PRIMARY,
                (W // 2, H - config.BOTBAR_H - 6),
                anchor="midbottom",
            )

        self._draw_bottom_bar(surf, W, H, f_xs)

    def _draw_card(
        self,
        surf: pygame.Surface,
        dev,
        ry: int,
        W: int,
        selected_key: str | None,
        f_xs: pygame.font.Font,
        f_sm: pygame.font.Font,
        f_md: pygame.font.Font,
    ) -> None:
        """Visual style similar to ahu_dashboard AHU cards."""
        is_active = (dev.unique_key == selected_key)
        border = config.C_GREEN if is_active else config.C_BORDER
        rect = pygame.Rect(8, ry, W - 16, config.LIST_ROW_H - 8)
        draw_rounded_rect(surf, config.C_CARD, rect, border_color=border)

        # Online pill + location on top
        status_color = config.C_GREEN if dev.run else config.C_RED
        dot(surf, status_color, (rect.x + 14, rect.y + 16), 5)

        draw_text(
            surf,
            dev.display_name,
            f_md,
            config.C_TEXT,
            (rect.x + 26, rect.y + 12),
            anchor="topleft",
        )

        draw_text(
            surf,
            dev.sub_label,
            f_xs,
            config.C_DIM,
            (rect.x + 26, rect.y + 30),
            anchor="topleft",
        )

        # Right side: IP + ACTIVE chip
        if dev.ip:
            draw_text(
                surf,
                dev.ip,
                f_xs,
                config.C_DIM,
                (rect.right - 8, rect.y + 16),
                anchor="midright",
            )

        if is_active:
            draw_text(
                surf,
                "ACTIVE ›",
                f_xs,
                config.C_GREEN,
                (rect.right - 8, rect.y + 30),
                anchor="midright",
            )

        # Bottom metrics row: temp / hum quick glance (if available)
        metrics_y = rect.bottom - 14
        temp_txt = (
            f"{dev.temp:.1f}°C"
            if getattr(dev, "temp", None) is not None
            else "-- °C"
        )
        hum_txt = (
            f"{dev.hum:.1f}%"
            if getattr(dev, "hum", None) is not None
            else "-- %"
        )

        draw_text(
            surf,
            f"T: {temp_txt}",
            f_xs,
            config.C_TEXT,
            (rect.x + 12, metrics_y),
            anchor="midleft",
        )
        draw_text(
            surf,
            f"H: {hum_txt}",
            f_xs,
            config.C_TEXT,
            (rect.x + rect.width // 2, metrics_y),
            anchor="midleft",
        )

    def _draw_bottom_bar(
        self,
        surf: pygame.Surface,
        W: int,
        H: int,
        f_sm: pygame.font.Font,
    ) -> None:
        bar = pygame.Rect(0, H - config.BOTBAR_H, W, config.BOTBAR_H)
        draw_rounded_rect(surf, config.C_TOPBAR, bar, radius=0)
        draw_text(
            surf,
            "Tap a card to open AHU control",
            f_sm,
            config.C_DIM,
            (W // 2, H - config.BOTBAR_H // 2),
            anchor="center",
        )

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, devices: list) -> tuple[str, object | None]:
        """
        Returns (action, device)
          action: "select_device" | "scroll_up" | "scroll_down" | "none"
        """
        tx, ty = pos
        W, H = config.SCREEN_W, config.SCREEN_H

        if not devices:
            return ("none", None)

        # Card taps
        visible_start = config.TOPBAR_H + 6
        for row in range(config.LIST_ROWS):
            idx = self._scroll + row
            if idx >= len(devices):
                break
            ry = visible_start + row * config.LIST_ROW_H
            row_rect = pygame.Rect(8, ry, W - 16, config.LIST_ROW_H - 8)
            if row_rect.collidepoint(tx, ty):
                return ("select_device", devices[idx])

        # Scroll up (top-right corner strip)
        if pygame.Rect(W - 40, config.TOPBAR_H, 36, 24).collidepoint(tx, ty):
            if self._scroll > 0:
                self._scroll -= 1
            return ("scroll_up", None)

        # Scroll down (bottom-right strip above bottom bar)
        if pygame.Rect(W - 40, H - config.BOTBAR_H - 24, 36, 24).collidepoint(tx, ty):
            if self._scroll + config.LIST_ROWS < len(devices):
                self._scroll += 1
            return ("scroll_down", None)

        return ("none", None)
