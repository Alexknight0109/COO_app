# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  screen_keypad.py
#
#  Screen 4 — Passcode Keypad
#    • 3×4 grid: 1-9, then 0, ← (backspace), ✓ (confirm)
#    • 6 dot indicators at top show entry progress
#    • Wrong code flashes screen red then resets
#    • Tap outside the pad to cancel
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations
import pygame
import config
from ui import draw_rounded_rect, draw_text, FontCache

_KP_LABELS = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["<", "0", "✓"],
]


class KeypadScreen:
    def __init__(self) -> None:
        self._entered = ""
        self._flash_red = False
        self._flash_until = 0.0
        self._pad_rect: pygame.Rect | None = None   # bounding box of keypad grid

    def reset(self) -> None:
        self._entered = ""
        self._flash_red = False

    def _pad_x(self) -> int:
        return (config.SCREEN_W - config.KP_COLS * config.KP_BTN_W
                - (config.KP_COLS - 1) * 6) // 2

    # ── Draw ─────────────────────────────────────────────────────────────────

    def draw(self, surf: pygame.Surface) -> None:
        import time
        W, H = config.SCREEN_W, config.SCREEN_H

        # Flash-red feedback on wrong code
        if self._flash_red and time.monotonic() < self._flash_until:
            surf.fill(config.C_RED_DK)
            return
        else:
            self._flash_red = False

        surf.fill(config.C_BG)

        f_sm   = FontCache.get(13)
        f_med  = FontCache.get(16)
        f_key  = FontCache.get(20)

        # ── Header bar ───────────────────────────────────────────────────────
        topbar = pygame.Rect(0, 0, W, config.TOPBAR_H)
        draw_rounded_rect(surf, config.C_TOPBAR, topbar, radius=0)
        draw_text(surf, "Enter Passcode to Unlock", f_med, config.C_ORANGE,
                  (W // 2, config.TOPBAR_H // 2), anchor="center")

        # ── 6-dot progress indicator ─────────────────────────────────────────
        dot_spacing = 24
        dot_start_x = (W - 6 * dot_spacing) // 2 + dot_spacing // 2
        dot_y = config.TOPBAR_H + 20
        for i in range(6):
            filled = i < len(self._entered)
            color = config.C_PRIMARY if filled else config.C_BORDER
            pygame.draw.circle(surf, color, (dot_start_x + i * dot_spacing, dot_y), 8)
            pygame.draw.circle(surf, config.C_DIM,
                               (dot_start_x + i * dot_spacing, dot_y), 8, 1)

        # ── Keypad buttons ────────────────────────────────────────────────────
        pad_x = self._pad_x()
        for row in range(config.KP_ROWS):
            for col in range(config.KP_COLS):
                bx = pad_x + col * (config.KP_BTN_W + 6)
                by = config.KP_PAD_Y + row * (config.KP_BTN_H + 6)
                lbl = _KP_LABELS[row][col]

                if lbl == "✓":
                    bg = config.C_GREEN_DK
                elif lbl == "<":
                    bg = config.C_RED_DK
                else:
                    bg = config.C_CARD

                btn_rect = pygame.Rect(bx, by, config.KP_BTN_W, config.KP_BTN_H)
                draw_rounded_rect(surf, bg, btn_rect, radius=6,
                                  border_color=config.C_BORDER)
                draw_text(surf, lbl, f_key, config.C_TEXT, btn_rect.center,
                          anchor="center")

        # Remember pad bounding box for cancel detection
        self._pad_rect = pygame.Rect(
            pad_x - 10,
            config.KP_PAD_Y - 10,
            config.KP_COLS * (config.KP_BTN_W + 6) + 20,
            config.KP_ROWS * (config.KP_BTN_H + 6) + 20,
        )

        # ── Cancel hint ───────────────────────────────────────────────────────
        draw_text(surf, "Tap outside keys to cancel", f_sm, config.C_DIM,
                  (W // 2, H - 6), anchor="midbottom")

    # ── Touch ─────────────────────────────────────────────────────────────────

    def handle_touch(self, pos: tuple, passcode: str) -> dict:
        """
        Returns dict with key 'action':
          'cancel' | 'unlocked' | 'wrong' | 'digit' | 'backspace' | 'none'
        """
        import time
        tx, ty = pos
        pad_x = self._pad_x()

        for row in range(config.KP_ROWS):
            for col in range(config.KP_COLS):
                bx = pad_x + col * (config.KP_BTN_W + 6)
                by = config.KP_PAD_Y + row * (config.KP_BTN_H + 6)
                btn_rect = pygame.Rect(bx, by, config.KP_BTN_W, config.KP_BTN_H)
                if btn_rect.collidepoint(tx, ty):
                    lbl = _KP_LABELS[row][col]

                    if lbl == "<":
                        if self._entered:
                            self._entered = self._entered[:-1]
                        return {"action": "backspace"}

                    elif lbl == "✓":
                        if len(self._entered) == 6:
                            if self._entered == passcode:
                                self._entered = ""
                                return {"action": "unlocked"}
                            else:
                                self._entered = ""
                                self._flash_red = True
                                self._flash_until = time.monotonic() + 0.25
                                return {"action": "wrong"}
                        return {"action": "none"}

                    else:
                        if len(self._entered) < 6:
                            self._entered += lbl
                        return {"action": "digit"}

        # Tap outside keypad → cancel
        if self._pad_rect and not self._pad_rect.collidepoint(tx, ty):
            self._entered = ""
            return {"action": "cancel"}

        return {"action": "none"}
