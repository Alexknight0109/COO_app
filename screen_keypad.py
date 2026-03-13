# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_keypad.py
#  Screen 4 — Passcode Keypad (6-digit unlock)
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import time
import pygame
import config
from ui import draw_rounded_rect, draw_text, draw_topbar, FontCache

_KP_LABELS = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["←", "0", "✓"],
]


class KeypadScreen:
    def __init__(self) -> None:
        self._entered    = ""
        self._flash_red  = False
        self._flash_until = 0.0

    def reset(self) -> None:
        self._entered   = ""
        self._flash_red = False

    def _grid_x(self) -> int:
        return (config.SCREEN_W
                - config.KP_COLS * config.KP_BTN_W
                - (config.KP_COLS - 1) * config.KP_GAP) // 2

    # ── Draw ─────────────────────────────────────────────────────────────────

    def draw(self, surf: pygame.Surface) -> None:
        W, H = config.SCREEN_W, config.SCREEN_H

        # Wrong-code flash
        if self._flash_red and time.monotonic() < self._flash_until:
            surf.fill(config.C_RED_DK)
            draw_text(surf, "Incorrect passcode",
                      FontCache.semibold(16), config.C_RED,
                      (W // 2, H // 2), anchor="center")
            return
        self._flash_red = False

        surf.fill(config.C_BG)

        # ── Top bar ──────────────────────────────────────────────────────────
        draw_topbar(surf, title="Enter Passcode")

        # ── 6 progress dots ──────────────────────────────────────────────────
        DOT_R    = 8
        DOT_SP   = 26
        dot_row_y = config.TOPBAR_H + 24
        start_x  = (W - 6 * DOT_SP) // 2 + DOT_SP // 2

        for i in range(6):
            cx     = start_x + i * DOT_SP
            filled = i < len(self._entered)
            # outer ring
            pygame.draw.circle(surf, config.C_BORDER, (cx, dot_row_y), DOT_R)
            if filled:
                pygame.draw.circle(surf, config.C_PRIMARY, (cx, dot_row_y), DOT_R)
            else:
                pygame.draw.circle(surf, config.C_CARD2, (cx, dot_row_y), DOT_R - 2)

        # ── Keypad grid ───────────────────────────────────────────────────────
        gx = self._grid_x()
        f_key = FontCache.semibold(20)

        for row in range(config.KP_ROWS):
            for col in range(config.KP_COLS):
                bx  = gx + col * (config.KP_BTN_W + config.KP_GAP)
                by  = config.KP_PAD_Y + row * (config.KP_BTN_H + config.KP_GAP)
                lbl = _KP_LABELS[row][col]
                btn = pygame.Rect(bx, by, config.KP_BTN_W, config.KP_BTN_H)

                if lbl == "✓":
                    bg  = config.C_GREEN_DK
                    fg  = config.C_GREEN
                    bdr = config.C_GREEN
                elif lbl == "←":
                    bg  = config.C_CARD2
                    fg  = config.C_ORANGE
                    bdr = config.C_BORDER
                else:
                    bg  = config.C_CARD
                    fg  = config.C_TEXT
                    bdr = config.C_BORDER

                draw_rounded_rect(surf, bg, btn,
                                  radius=10,
                                  border_color=bdr, border_width=1)
                draw_text(surf, lbl, f_key, fg, btn.center, anchor="center")

        # ── Cancel hint ───────────────────────────────────────────────────────
        draw_text(surf, "Tap outside keys to cancel",
                  FontCache.get(11), config.C_DIM,
                  (W // 2, H - 6), anchor="midbottom")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, passcode: str) -> dict:
        tx, ty = pos
        gx     = self._grid_x()

        for row in range(config.KP_ROWS):
            for col in range(config.KP_COLS):
                bx  = gx + col * (config.KP_BTN_W + config.KP_GAP)
                by  = config.KP_PAD_Y + row * (config.KP_BTN_H + config.KP_GAP)
                btn = pygame.Rect(bx, by, config.KP_BTN_W, config.KP_BTN_H)
                if not btn.collidepoint(tx, ty):
                    continue

                lbl = _KP_LABELS[row][col]

                if lbl == "←":
                    self._entered = self._entered[:-1]
                    return {"action": "backspace"}

                if lbl == "✓":
                    if len(self._entered) == 6:
                        if self._entered == passcode:
                            self._entered = ""
                            return {"action": "unlocked"}
                        self._entered    = ""
                        self._flash_red  = True
                        self._flash_until = time.monotonic() + 0.4
                        return {"action": "wrong"}
                    return {"action": "none"}

                if len(self._entered) < 6:
                    self._entered += lbl
                return {"action": "digit"}

        # Tap outside grid → cancel
        grid_rect = pygame.Rect(
            gx - 10,
            config.KP_PAD_Y - 10,
            config.KP_COLS * (config.KP_BTN_W + config.KP_GAP) + 10,
            config.KP_ROWS * (config.KP_BTN_H + config.KP_GAP) + 10,
        )
        if not grid_rect.collidepoint(tx, ty):
            self._entered = ""
            return {"action": "cancel"}

        return {"action": "none"}
