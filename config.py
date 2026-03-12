# ═══════════════════════════════════════════════════════════════════════════
#  ALMED AHU — Pi Zero 2W Eco Display  ·  config.py
#  All credentials and tunable constants in one place.
# ═══════════════════════════════════════════════════════════════════════════

# ── WiFi / Network ───────────────────────────────────────────────────────────
WIFI_SSID     = "PiSpot"       # Same hotspot the AHU ESP32 connects to
WIFI_PASSWORD = "12345678"

# ── MQTT ─────────────────────────────────────────────────────────────────────
MQTT_BROKER   = "192.168.0.253"   # Pi's static IP on AlMed network
MQTT_PORT     = 1883
MQTT_USER     = "almed"
MQTT_PASS     = "Almed1234$"
MQTT_CLIENT   = "pi_eco_display_01"

# ── Screen lock (6-digit passcode) ───────────────────────────────────────────
DEFAULT_PASSCODE = "123123"

# ── Display ──────────────────────────────────────────────────────────────────
# Pi Zero 2W driving a 3.5" / 7" HDMI display (landscape)
SCREEN_W = 480
SCREEN_H = 320
TARGET_FPS   = 30
FULLSCREEN   = True   # Set False for development on desktop

# ── Timing ───────────────────────────────────────────────────────────────────
DISCOVERY_WAIT_S  = 5.0     # Seconds to stay on scanning screen
DEVICE_STALE_S    = 90.0    # Remove device if silent for this long
MQTT_RETRY_S      = 5.0     # Seconds between reconnect attempts
TOUCH_DEBOUNCE_MS = 300     # Milliseconds between accepted touch events
REFRESH_MS        = 350     # Max display refresh interval

# ── Device list layout ───────────────────────────────────────────────────────
LIST_ROWS    = 4
LIST_ROW_H   = 54
TOPBAR_H     = 30
BOTBAR_H     = 30
CARD_RADIUS  = 8

# ── Control screen layout ────────────────────────────────────────────────────
CTRL_TEMP_Y    = 34
CTRL_HUM_Y     = 132
CTRL_CARD_H    = 90
CTRL_BTN_W     = 52
CTRL_BTN_H     = 32
CTRL_BTN_Y_OFF = 52          # Y offset inside card for +/− row

# ── Passcode keypad ──────────────────────────────────────────────────────────
KP_BTN_W = 80
KP_BTN_H = 44
KP_COLS  = 3
KP_ROWS  = 4
KP_PAD_Y = 90

# ── Colour palette (R, G, B) ─────────────────────────────────────────────────
C_BG         = (  0,   0,   0)    # Pure black
C_TOPBAR     = ( 12,  16,  18)    # Very dark blue-grey
C_CARD       = ( 20,  26,  33)    # Dark card
C_CARD2      = ( 28,  38,  48)    # Slightly lighter card
C_BORDER     = ( 42,  52,  70)    # Dim border
C_PRIMARY    = ( 59, 130, 246)    # Blue accent  (#3B82F6)
C_PRIMARY_LT = ( 96, 165, 250)    # Lighter blue (#60A5FA)
C_TEXT       = (255, 255, 255)    # White
C_DIM        = (140, 148, 160)    # Grey text
C_GREEN      = (  7, 224,   0)    # Green
C_GREEN_DK   = (  5, 140,   5)    # Dark green
C_RED        = (248,   0,   0)    # Red
C_RED_DK     = (120,   0,   0)    # Dark red
C_ORANGE     = (253, 140,  20)    # Orange (lock)
C_YELLOW     = (255, 224,   0)    # Yellow (setpoint)
C_HILIGHT    = ( 48,  60,  80)    # Row highlight

# ── Passcode persistence file ────────────────────────────────────────────────
import os
PASSCODE_FILE = os.path.join(os.path.dirname(__file__), ".passcode")
LOCK_STATE_FILE = os.path.join(os.path.dirname(__file__), ".lockstate")
