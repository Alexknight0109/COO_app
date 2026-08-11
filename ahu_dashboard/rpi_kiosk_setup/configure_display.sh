#!/bin/bash
# =============================================================================
# ALMED AHU Dashboard - Display configuration (Radxa / Pi / any X11 kiosk)
# =============================================================================
# Fixes tiny UI when HDMI defaults to 1080p on a smaller native panel.
# Edit the values below to match your panel, then reboot or relaunch kiosk.
# =============================================================================

# Target mode for 7" ALMED panels (same as Pi kiosk: 1024x600 landscape).
DISPLAY_WIDTH="${ALMED_DISPLAY_WIDTH:-1024}"
DISPLAY_HEIGHT="${ALMED_DISPLAY_HEIGHT:-600}"
DISPLAY_REFRESH="${ALMED_DISPLAY_REFRESH:-60}"

# Rotation: normal | left | right | inverted
# Use "left" or "right" if the panel is mounted portrait but UI is landscape.
DISPLAY_ROTATION="${ALMED_DISPLAY_ROTATION:-normal}"

# Leave empty to auto-detect the first connected HDMI output.
DISPLAY_OUTPUT="${ALMED_DISPLAY_OUTPUT:-}"

# Optional UI scale if the panel is truly high-DPI (e.g. 1.5 or 2).
# Leave at 1 for standard 7" 1024x600 panels.
UI_SCALE="${ALMED_UI_SCALE:-1}"

configure_display() {
    command -v xrandr >/dev/null 2>&1 || {
        echo "configure_display: xrandr not found, skipping"
        return 0
    }

    local output="$DISPLAY_OUTPUT"
    if [ -z "$output" ]; then
        output=$(xrandr --query 2>/dev/null | awk '
            / connected/ {
                name = $1
                if ($2 == "connected" || $2 == "primary") {
                    print name
                    exit
                }
            }
        ')
    fi

    if [ -z "$output" ]; then
        echo "configure_display: no connected output found"
        return 1
    fi

    local mode="${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
    echo "configure_display: output=$output mode=$mode rotation=$DISPLAY_ROTATION"

    if ! xrandr --query 2>/dev/null | awk -v m="$mode" '$1 == m { found=1 } END { exit !found }'; then
        local modeline
        modeline=$(cvt "$DISPLAY_WIDTH" "$DISPLAY_HEIGHT" "$DISPLAY_REFRESH" 2>/dev/null | sed -n 's/Modeline //p')
        if [ -n "$modeline" ]; then
            local mode_name="${mode}_${DISPLAY_REFRESH}.00"
            xrandr --newmode "$mode_name" $modeline 2>/dev/null || true
            xrandr --addmode "$output" "$mode_name" 2>/dev/null || true
            mode="$mode_name"
        fi
    fi

    xrandr --output "$output" --mode "$mode" --rotate "$DISPLAY_ROTATION" 2>/dev/null \
        || xrandr --output "$output" --rotate "$DISPLAY_ROTATION" 2>/dev/null \
        || true

    if [ "$UI_SCALE" != "1" ] && [ "$UI_SCALE" != "1.0" ]; then
        export GDK_SCALE="$UI_SCALE"
        export GDK_DPI_SCALE=1
        echo "configure_display: GDK_SCALE=$GDK_SCALE"
    fi
}

configure_display
