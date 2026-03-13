# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_control.py
#  Screen 3 — AHU Control (temperature, humidity, run/stop, lock)
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import pygame
import config
from ui import (
    draw_rounded_rect, draw_text, draw_button, draw_pill,
    draw_topbar, draw_h_rule, FontCache,
)


class ControlScreen:
    def __init__(self) -> None:
        self.edit_focus = 0     # 0 = temp row, 1 = hum row

    # ── Draw ─────────────────────────────────────────────────────────────────

    def draw(
        self,
        surf: pygame.Surface,
        device,
        mqtt_ok: bool,
        is_locked: bool,
    ) -> None:
        W, H = config.SCREEN_W, config.SCREEN_H
        surf.fill(config.C_BG)

        # ── Top bar ──────────────────────────────────────────────────────────
        lock_label = "LOCK" if is_locked else "OPEN"
        lock_color = config.C_ORANGE if is_locked else config.C_GREEN
        dot_colors = [config.C_GREEN if mqtt_ok else config.C_RED]
        draw_topbar(
            surf,
            left_text="← Back",
            title=device.display_name if device else "—",
            right_text=lock_label,
            right_color=lock_color,
            dots=dot_colors,
        )

        # ── Sensor cards ─────────────────────────────────────────────────────
        btn_bg = config.C_CARD2 if is_locked else config.C_PRIMARY

        for i, params in enumerate([
            (
                "TEMPERATURE",
                f"{device.temp:.1f}" if device and device.temp is not None else "—",
                "°C",
                f"{device.temp_set:.1f}" if device else "22.0",
                config.CTRL_TEMP_Y,
            ),
            (
                "HUMIDITY",
                f"{device.hum:.1f}" if device and device.hum is not None else "—",
                "%",
                f"{device.hum_set:.1f}" if device else "55.0",
                config.CTRL_HUM_Y,
            ),
        ]):
            label, value, unit, setpoint, card_y = params
            self._draw_sensor_card(
                surf, i, label, value, unit, setpoint,
                card_y, W, btn_bg, is_locked,
            )

        # ── Run / Stop bar ────────────────────────────────────────────────────
        running  = device.run if device else False
        bar_y    = config.CTRL_HUM_Y + config.CTRL_CARD_H + 4
        bar_h    = H - bar_y
        bar_rect = pygame.Rect(0, bar_y, W, bar_h)
        bar_bg   = config.C_GREEN_DK if running else config.C_RED_DK
        draw_rounded_rect(surf, bar_bg, bar_rect, radius=0)

        # Left icon + label
        icon  = "▶" if running else "■"
        label = f" AHU: {'RUNNING' if running else 'STOPPED'}"
        run_f = FontCache.semibold(15)
        r = draw_text(surf, icon, run_f, config.C_GREEN if running else config.C_RED,
                      (12, bar_y + bar_h // 2), anchor="midleft")
        draw_text(surf, label, run_f, config.C_TEXT,
                  (r.right + 2, bar_y + bar_h // 2), anchor="midleft")

        # Right hint or lock badge
        if is_locked:
            draw_pill(surf, "LOCKED",
                      FontCache.bold(11),
                      config.C_RED_BG, config.C_ORANGE,
                      center=(W - 54, bar_y + bar_h // 2),
                      pad_x=8, pad_y=4)
        else:
            draw_text(surf, "Tap to toggle",
                      FontCache.get(12), config.C_DIM,
                      (W - 10, bar_y + bar_h // 2), anchor="midright")

    def _draw_sensor_card(
        self,
        surf: pygame.Surface,
        index: int,
        label: str,
        value: str,
        unit: str,
        setpoint: str,
        card_y: int,
        W: int,
        btn_bg: tuple,
        is_locked: bool,
    ) -> None:
        focused    = (self.edit_focus == index)
        card_rect  = pygame.Rect(6, card_y, W - 12, config.CTRL_CARD_H)
        border_col = config.C_PRIMARY if focused else config.C_BORDER
        draw_rounded_rect(surf, config.C_CARD, card_rect,
                          radius=config.CARD_RADIUS,
                          border_color=border_col, border_width=1)

        # Left accent bar when focused
        if focused:
            acc = pygame.Rect(6, card_y + 6, 3, config.CTRL_CARD_H - 12)
            pygame.draw.rect(surf, config.C_PRIMARY, acc, border_radius=2)

        inner_x = card_rect.x + 16

        # Label (small caps feel, muted)
        draw_text(surf, label,
                  FontCache.semibold(11), config.C_DIM,
                  (inner_x, card_y + 11), anchor="midleft")

        # Big value
        val_y = card_y + 28
        draw_text(surf, value,
                  FontCache.bold(44), config.C_TEXT,
                  (inner_x, val_y), anchor="topleft")

        # Unit (smaller, right of large number)
        val_w = FontCache.bold(44).size(value)[0]
        draw_text(surf, unit,
                  FontCache.semibold(18), config.C_DIM,
                  (inner_x + val_w + 5, val_y + 6), anchor="topleft")

        # Setpoint row + buttons
        sp_y    = card_y + config.CTRL_CARD_H - 22
        btn_y   = card_y + config.CTRL_BTN_Y_OFF

        draw_text(surf, "SET",
                  FontCache.get(11), config.C_DIM,
                  (inner_x, sp_y), anchor="midleft")
        sp_w = FontCache.get(11).size("SET ")[0]
        draw_text(surf, f"{setpoint} {unit}",
                  FontCache.semibold(12), config.C_YELLOW,
                  (inner_x + sp_w, sp_y), anchor="midleft")

        # − / + buttons
        gap       = 8
        bw, bh    = config.CTRL_BTN_W, config.CTRL_BTN_H
        plus_rect  = pygame.Rect(W - 12 - bw, btn_y, bw, bh)
        minus_rect = pygame.Rect(plus_rect.x - gap - bw, btn_y, bw, bh)

        btn_border = None if is_locked else config.C_PRIMARY_LT
        draw_button(surf, minus_rect, "−",
                    FontCache.bold(20), btn_bg, config.C_TEXT,
                    radius=8, border=btn_border)
        draw_button(surf, plus_rect, "+",
                    FontCache.bold(20), btn_bg, config.C_TEXT,
                    radius=8, border=btn_border)

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, device, is_locked: bool) -> dict:
        tx, ty = pos
        W, H   = config.SCREEN_W, config.SCREEN_H

        # Back (top-left of top bar)
        if pygame.Rect(0, 0, 68, config.TOPBAR_H).collidepoint(tx, ty):
            return {"action": "back"}

        # Lock / Open (top-right)
        if pygame.Rect(W - 72, 0, 72, config.TOPBAR_H).collidepoint(tx, ty):
            return {"action": "unlock_request" if is_locked else "lock"}

        # Sensor cards
        for i, card_y in enumerate([config.CTRL_TEMP_Y, config.CTRL_HUM_Y]):
            card_rect = pygame.Rect(6, card_y, W - 12, config.CTRL_CARD_H)
            if card_rect.collidepoint(tx, ty):
                self.edit_focus = i
                btn_y = card_y + config.CTRL_BTN_Y_OFF
                bw    = config.CTRL_BTN_W
                bh    = config.CTRL_BTN_H
                plus_rect  = pygame.Rect(W - 12 - bw, btn_y, bw, bh)
                minus_rect = pygame.Rect(plus_rect.x - 8 - bw, btn_y, bw, bh)

                if not is_locked and device:
                    if i == 0:   # temperature
                        if minus_rect.collidepoint(tx, ty):
                            return {"action": "temp_down",
                                    "value": max(16.0, device.temp_set - 0.5)}
                        if plus_rect.collidepoint(tx, ty):
                            return {"action": "temp_up",
                                    "value": min(35.0, device.temp_set + 0.5)}
                    else:        # humidity
                        if minus_rect.collidepoint(tx, ty):
                            return {"action": "hum_down",
                                    "value": max(30.0, device.hum_set - 5.0)}
                        if plus_rect.collidepoint(tx, ty):
                            return {"action": "hum_up",
                                    "value": min(90.0, device.hum_set + 5.0)}
                return {"action": f"focus_{'temp' if i == 0 else 'hum'}"}

        # Run/Stop bar
        bar_y = config.CTRL_HUM_Y + config.CTRL_CARD_H + 4
        if ty >= bar_y and not is_locked:
            return {"action": "toggle"}

        return {"action": "none"}
