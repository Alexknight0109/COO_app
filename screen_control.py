# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_control.py
#
#  Screen 3 — Control
#    • Temperature card  (big reading + SET + − / + buttons)
#    • Humidity card     (big reading + SET + − / + buttons)
#    • Run/Stop bar at bottom  (tap to toggle)
#    • Back button  (top-left)
#    • Lock / Open button  (top-right)
#    • MQTT-connected dot
#
#  Mirrors the ESP32 eco_display.ino control screen exactly.
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import pygame
import config
from ui import draw_rounded_rect, draw_text, draw_button, dot, FontCache


class ControlScreen:
    def __init__(self) -> None:
        self.edit_focus = 0     # 0 = temp, 1 = hum

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

        f_sm   = FontCache.get(12)
        f_med  = FontCache.get(15)
        f_lg   = FontCache.get(26)
        f_huge = FontCache.get(38)

        # ── Top bar ──────────────────────────────────────────────────────────
        topbar = pygame.Rect(0, 0, W, config.TOPBAR_H)
        draw_rounded_rect(surf, config.C_TOPBAR, topbar, radius=0)

        draw_text(surf, "< Back", f_med, config.C_PRIMARY,
                  (8, config.TOPBAR_H // 2), anchor="midleft")

        title = device.display_name if device else "—"
        draw_text(surf, title, f_med, config.C_TEXT,
                  (W // 2, config.TOPBAR_H // 2), anchor="center")

        lock_label = "LOCK" if is_locked else "OPEN"
        lock_color = config.C_ORANGE if is_locked else config.C_DIM
        draw_text(surf, lock_label, f_med, lock_color,
                  (W - 8, config.TOPBAR_H // 2), anchor="midright")

        dot(surf, config.C_GREEN if mqtt_ok else config.C_RED,
            (W - 60, config.TOPBAR_H // 2), 4)

        # ── Sensor cards ─────────────────────────────────────────────────────
        btn_bg = config.C_BORDER if is_locked else config.C_PRIMARY

        for i, (label, value, unit, setpoint, card_y) in enumerate([
            ("TEMPERATURE",
             f"{device.temp:.1f}" if device and device.temp is not None else "---",
             "°C",
             f"{device.temp_set:.1f}" if device else "22.0",
             config.CTRL_TEMP_Y),
            ("HUMIDITY",
             f"{device.hum:.1f}" if device and device.hum is not None else "---",
             "%",
             f"{device.hum_set:.1f}" if device else "55.0",
             config.CTRL_HUM_Y),
        ]):
            focused   = (self.edit_focus == i)
            border_c  = config.C_PRIMARY if focused else config.C_BORDER
            card_rect = pygame.Rect(4, card_y, W - 8, config.CTRL_CARD_H)
            draw_rounded_rect(surf, config.C_CARD, card_rect, border_color=border_c)

            if focused:
                # Blue focus bar on left edge
                pygame.draw.rect(surf, config.C_PRIMARY,
                                 pygame.Rect(4, card_y, 3, config.CTRL_CARD_H))

            # Label
            draw_text(surf, label, f_sm, config.C_DIM, (16, card_y + 8))

            # Big reading
            draw_text(surf, value, f_huge, config.C_TEXT, (16, card_y + 18))
            # Unit beside reading (small)
            value_w = FontCache.get(38).size(value)[0]
            draw_text(surf, unit, f_lg, config.C_DIM,
                      (16 + value_w + 4, card_y + 26))

            # Setpoint row
            sp_y = card_y + config.CTRL_CARD_H - 18
            draw_text(surf, "SET:", f_sm, config.C_DIM, (16, sp_y))
            set_x = 16 + FontCache.get(12).size("SET: ")[0]
            draw_text(surf, setpoint, f_sm, config.C_YELLOW, (set_x, sp_y))
            sp_w = FontCache.get(12).size(setpoint)[0]
            draw_text(surf, unit, f_sm, config.C_DIM, (set_x + sp_w + 2, sp_y))

            # − / + buttons
            btn_y = card_y + config.CTRL_BTN_Y_OFF
            minus_rect = pygame.Rect(
                W - 2 * config.CTRL_BTN_W - 14, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            plus_rect = pygame.Rect(
                W - config.CTRL_BTN_W - 8, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            draw_button(surf, minus_rect, "−", f_lg, btn_bg, config.C_TEXT)
            draw_button(surf, plus_rect,  "+", f_lg, btn_bg, config.C_TEXT)

        # ── Run / Stop bar ────────────────────────────────────────────────────
        running     = device.run if device else False
        bar_y       = H - config.BOTBAR_H - 10
        bar_h       = config.BOTBAR_H + 10
        bar_rect    = pygame.Rect(0, bar_y, W, bar_h)
        bar_bg      = config.C_GREEN_DK if running else config.C_RED_DK
        draw_rounded_rect(surf, bar_bg, bar_rect, radius=0)

        run_label = "  AHU: RUNNING" if running else "  AHU: STOPPED"
        draw_text(surf, run_label, f_med, config.C_TEXT,
                  (8, bar_y + bar_h // 2), anchor="midleft")

        if is_locked:
            draw_text(surf, "LOCKED", f_med, config.C_ORANGE,
                      (W - 8, bar_y + bar_h // 2), anchor="midright")
        else:
            draw_text(surf, "Tap to toggle", f_sm, config.C_DIM,
                      (W - 8, bar_y + bar_h // 2), anchor="midright")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, device, is_locked: bool) -> dict:
        """
        Returns a dict describing the action.
        Keys: 'action', optionally 'value'
        Actions: 'back' | 'lock' | 'unlock_request' | 'temp_down' | 'temp_up'
                 | 'hum_down' | 'hum_up' | 'focus_temp' | 'focus_hum' | 'toggle' | 'none'
        """
        tx, ty = pos
        W, H   = config.SCREEN_W, config.SCREEN_H

        # Back (top-left of top bar)
        if pygame.Rect(0, 0, 60, config.TOPBAR_H).collidepoint(tx, ty):
            return {"action": "back"}

        # Lock icon (top-right of top bar)
        if pygame.Rect(W - 70, 0, 70, config.TOPBAR_H).collidepoint(tx, ty):
            if is_locked:
                return {"action": "unlock_request"}
            else:
                return {"action": "lock"}

        # Temperature card
        temp_rect = pygame.Rect(4, config.CTRL_TEMP_Y, W - 8, config.CTRL_CARD_H)
        if temp_rect.collidepoint(tx, ty):
            self.edit_focus = 0
            btn_y = config.CTRL_TEMP_Y + config.CTRL_BTN_Y_OFF
            minus_rect = pygame.Rect(
                W - 2 * config.CTRL_BTN_W - 14, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            plus_rect = pygame.Rect(
                W - config.CTRL_BTN_W - 8, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            if not is_locked and device:
                if minus_rect.collidepoint(tx, ty):
                    new_val = max(16.0, device.temp_set - 0.5)
                    return {"action": "temp_down", "value": new_val}
                if plus_rect.collidepoint(tx, ty):
                    new_val = min(35.0, device.temp_set + 0.5)
                    return {"action": "temp_up", "value": new_val}
            return {"action": "focus_temp"}

        # Humidity card
        hum_rect = pygame.Rect(4, config.CTRL_HUM_Y, W - 8, config.CTRL_CARD_H)
        if hum_rect.collidepoint(tx, ty):
            self.edit_focus = 1
            btn_y = config.CTRL_HUM_Y + config.CTRL_BTN_Y_OFF
            minus_rect = pygame.Rect(
                W - 2 * config.CTRL_BTN_W - 14, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            plus_rect = pygame.Rect(
                W - config.CTRL_BTN_W - 8, btn_y,
                config.CTRL_BTN_W, config.CTRL_BTN_H,
            )
            if not is_locked and device:
                if minus_rect.collidepoint(tx, ty):
                    new_val = max(30.0, device.hum_set - 5.0)
                    return {"action": "hum_down", "value": new_val}
                if plus_rect.collidepoint(tx, ty):
                    new_val = min(90.0, device.hum_set + 5.0)
                    return {"action": "hum_up", "value": new_val}
            return {"action": "focus_hum"}

        # Run/Stop bar (bottom area)
        bar_y = H - config.BOTBAR_H - 10
        if ty >= bar_y:
            if not is_locked:
                return {"action": "toggle"}

        return {"action": "none"}
