# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  config.py
# ═══════════════════════════════════════════════════════════════════════════

# ── MQTT ─────────────────────────────────────────────────────────────────────
MQTT_BROKER   = "192.168.0.253"   # Pi's static IP on AlMed network
MQTT_PORT     = 1883
MQTT_USER     = "almed"
MQTT_PASS     = "Almed1234$"
MQTT_CLIENT   = "pi_eco_display_01"

# ── Screen lock ───────────────────────────────────────────────────────────────
DEFAULT_PASSCODE = "123123"

# ── Display ──────────────────────────────────────────────────────────────────
SCREEN_W   = 480
SCREEN_H   = 320
TARGET_FPS = 30
FULLSCREEN = True

# ── Timing ───────────────────────────────────────────────────────────────────
DISCOVERY_WAIT_S  = 5.0
DEVICE_STALE_S    = 90.0
MQTT_RETRY_S      = 5.0
TOUCH_DEBOUNCE_MS = 280
REFRESH_MS        = 350

# ── Layout ───────────────────────────────────────────────────────────────────
CARD_RADIUS  = 10
TOPBAR_H     = 38
BOTBAR_H     = 22

# Select / scan list
LIST_ROWS    = 3          # 3 cards visible at 480×320
LIST_ROW_H   = 86         # card height (82) + 4 gap

# Control screen  (cards fill y=40 to y=256, run-bar y=256 h=64)
CTRL_TEMP_Y    = 40
CTRL_HUM_Y     = 148       # 40 + 104 + 4
CTRL_CARD_H    = 104
CTRL_BTN_W     = 58
CTRL_BTN_H     = 30
CTRL_BTN_Y_OFF = 68        # button top offset from card top

# Keypad  (3×4 grid, 88×50 buttons, 8px gaps)
KP_BTN_W = 88
KP_BTN_H = 50
KP_GAP   = 8
KP_COLS  = 3
KP_ROWS  = 4
KP_PAD_Y = 86              # grid top-y (below header + dot row)

# ── Colours ───────────────────────────────────────────────────────────────────
C_BG         = ( 15,  23,  42)   # #0F172A  deep navy
C_TOPBAR     = ( 15,  23,  42)   # same as BG
C_CARD       = ( 30,  41,  59)   # #1E293B  surface card
C_CARD2      = ( 38,  52,  74)   # slightly lighter variant
C_BORDER     = ( 51,  65,  85)   # #334155  dividers / borders

C_PRIMARY    = ( 59, 130, 246)   # #3B82F6  blue accent
C_PRIMARY_LT = ( 96, 165, 250)   # #60A5FA  light blue

C_TEXT       = (241, 245, 249)   # #F1F5F9  near-white
C_DIM        = (100, 116, 139)   # #64748B  muted grey

C_GREEN      = ( 16, 185, 129)   # #10B981  emerald
C_GREEN_BG   = ( 10,  72,  52)   # dark green card bg
C_GREEN_DK   = (  5,  90,  60)   # run-bar bg
C_RED        = (239,  68,  68)   # #EF4444
C_RED_BG     = ( 80,  18,  18)   # dark red card bg
C_RED_DK     = ( 90,  15,  15)   # stop-bar bg
C_ORANGE     = (251, 146,  60)   # #FB923C
C_YELLOW     = (250, 204,  21)   # #FACC15

# ── Passcode persistence files ────────────────────────────────────────────────
import os
PASSCODE_FILE   = os.path.join(os.path.dirname(__file__), ".passcode")
LOCK_STATE_FILE = os.path.join(os.path.dirname(__file__), ".lockstate")
