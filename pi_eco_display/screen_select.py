# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_select.py
#  Screen 2 — Device Dashboard (list of AHU cards)
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import pygame
import config
from ui import draw_rounded_rect, draw_text, draw_pill, draw_topbar, FontCache


class SelectScreen:
    def __init__(self) -> None:
        self._scroll = 0

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

        dot_colors = [
            config.C_GREEN if mqtt_ok else config.C_RED,
            config.C_GREEN if wifi_ok  else config.C_RED,
        ]
        draw_topbar(surf,
                    left_text="ALMED",
                    left_color=config.C_PRIMARY,
                    title="Dashboard",
                    dots=dot_colors)

        if not devices:
            self._draw_empty(surf, W, H)
            return

        # ── Cards ────────────────────────────────────────────────────────────
        card_top = config.TOPBAR_H + 4
        for row in range(config.LIST_ROWS):
            idx = self._scroll + row
            if idx >= len(devices):
                break
            dev = devices[idx]
            cy  = card_top + row * config.LIST_ROW_H
            self._draw_card(surf, dev, cy, W, selected_key)

        # ── Scroll arrows ────────────────────────────────────────────────────
        f_arrow = FontCache.semibold(14)
        if self._scroll > 0:
            draw_text(surf, "▲", f_arrow, config.C_PRIMARY,
                      (W - 16, config.TOPBAR_H + 10), anchor="center")
        if self._scroll + config.LIST_ROWS < len(devices):
            draw_text(surf, "▼", f_arrow, config.C_PRIMARY,
                      (W - 16, H - 12), anchor="center")

        # ── Bottom hint ──────────────────────────────────────────────────────
        draw_text(surf, "Tap a card to control",
                  FontCache.get(11), config.C_DIM,
                  (W // 2, H - 6), anchor="midbottom")

    def _draw_card(
        self,
        surf: pygame.Surface,
        dev,
        cy: int,
        W: int,
        selected_key: str | None,
    ) -> None:
        CARD_H   = config.LIST_ROW_H - 4    # 82
        PAD      = 10
        is_sel   = (dev.unique_key == selected_key)
        running  = getattr(dev, "run", False)

        card_rect = pygame.Rect(8, cy, W - 16, CARD_H)

        # Card fill + border
        border_c = config.C_PRIMARY if is_sel else config.C_BORDER
        draw_rounded_rect(surf, config.C_CARD, card_rect,
                          radius=config.CARD_RADIUS,
                          border_color=border_c, border_width=1)

        # Left accent bar for selected device
        if is_sel:
            acc = pygame.Rect(card_rect.x, card_rect.y + 6,
                              3, CARD_H - 12)
            pygame.draw.rect(surf, config.C_PRIMARY, acc, border_radius=2)

        inner_x = card_rect.x + PAD + (6 if is_sel else 0)

        # ── Line 1: name (bold) + status pill ────────────────────────────────
        line1_y = cy + 14
        draw_text(surf, dev.display_name,
                  FontCache.bold(15), config.C_TEXT,
                  (inner_x, line1_y), anchor="midleft")

        pill_bg  = config.C_GREEN_BG if running else config.C_RED_BG
        pill_fg  = config.C_GREEN    if running else config.C_RED
        pill_lbl = "RUNNING" if running else "STOPPED"
        draw_pill(surf, pill_lbl,
                  FontCache.bold(10), pill_bg, pill_fg,
                  center=(card_rect.right - 46, line1_y),
                  pad_x=7, pad_y=3)

        # ── Line 2: site · room (dim) ────────────────────────────────────────
        line2_y  = cy + 31
        sub_text = dev.sub_label if hasattr(dev, "sub_label") else ""
        draw_text(surf, sub_text,
                  FontCache.get(11), config.C_DIM,
                  (inner_x, line2_y), anchor="midleft")

        # IP on right
        if dev.ip:
            draw_text(surf, dev.ip,
                      FontCache.get(10), config.C_DIM,
                      (card_rect.right - PAD, line2_y), anchor="midright")

        # ── Thin divider ─────────────────────────────────────────────────────
        div_y = cy + 44
        pygame.draw.line(surf, config.C_BORDER,
                         (card_rect.x + PAD, div_y),
                         (card_rect.right - PAD, div_y))

        # ── Line 3: big T / H readings ───────────────────────────────────────
        reading_y = cy + 64

        temp_val = (f"{dev.temp:.1f}" if getattr(dev, "temp", None) is not None
                    else "—")
        hum_val  = (f"{dev.hum:.1f}" if getattr(dev, "hum", None) is not None
                    else "—")

        # Temperature block (left half)
        tx_num = inner_x + 4
        draw_text(surf, temp_val,
                  FontCache.bold(22), config.C_TEXT,
                  (tx_num, reading_y), anchor="midleft")
        num_w = FontCache.bold(22).size(temp_val)[0]
        draw_text(surf, "°C",
                  FontCache.get(12), config.C_DIM,
                  (tx_num + num_w + 2, reading_y - 6), anchor="midleft")

        # Humidity block (right half)
        hx_num = card_rect.x + card_rect.width // 2 + 10
        draw_text(surf, hum_val,
                  FontCache.bold(22), config.C_TEXT,
                  (hx_num, reading_y), anchor="midleft")
        hnum_w = FontCache.bold(22).size(hum_val)[0]
        draw_text(surf, "%RH",
                  FontCache.get(12), config.C_DIM,
                  (hx_num + hnum_w + 2, reading_y - 6), anchor="midleft")

        # Small labels below numbers
        lbl_y = cy + 76
        draw_text(surf, "TEMP",
                  FontCache.get(9), config.C_DIM,
                  (tx_num + 4, lbl_y), anchor="midleft")
        draw_text(surf, "HUMIDITY",
                  FontCache.get(9), config.C_DIM,
                  (hx_num + 4, lbl_y), anchor="midleft")

    def _draw_empty(self, surf: pygame.Surface, W: int, H: int) -> None:
        f_sm = FontCache.get(13)
        f_md = FontCache.semibold(15)
        cy   = H // 2
        draw_text(surf, "No AHU devices found", f_md, config.C_DIM,
                  (W // 2, cy - 14), anchor="center")
        draw_text(surf, "Power on ESP32 AHUs and check WiFi",
                  f_sm, config.C_DIM,
                  (W // 2, cy + 8), anchor="center")
        draw_text(surf, "Scanning…", FontCache.semibold(15), config.C_PRIMARY,
                  (W // 2, cy + 34), anchor="center")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, devices: list) -> tuple[str, object | None]:
        tx, ty = pos
        W, H   = config.SCREEN_W, config.SCREEN_H

        if not devices:
            return ("none", None)

        card_top = config.TOPBAR_H + 4
        for row in range(config.LIST_ROWS):
            idx = self._scroll + row
            if idx >= len(devices):
                break
            cy = card_top + row * config.LIST_ROW_H
            hit = pygame.Rect(8, cy, W - 16, config.LIST_ROW_H - 4)
            if hit.collidepoint(tx, ty):
                return ("select_device", devices[idx])

        # Scroll up strip (top-right)
        if pygame.Rect(W - 36, config.TOPBAR_H, 32, 26).collidepoint(tx, ty):
            if self._scroll > 0:
                self._scroll -= 1
            return ("scroll_up", None)

        # Scroll down strip (bottom-right)
        if pygame.Rect(W - 36, H - 30, 32, 26).collidepoint(tx, ty):
            if self._scroll + config.LIST_ROWS < len(devices):
                self._scroll += 1
            return ("scroll_down", None)

        return ("none", None)
