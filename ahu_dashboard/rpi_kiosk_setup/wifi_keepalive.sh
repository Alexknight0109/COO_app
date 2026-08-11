#!/bin/bash
# =============================================================================
# WiFi reconnect loop (Raspberry Pi OS with NetworkManager / nmcli)
# =============================================================================
# Default credentials below, or override without editing:
#   export WIFI_SSID=YourNet WIFI_PASS=YourSecret
#
# Foreground (Ctrl+C to stop):
#   chmod +x wifi_keepalive.sh && ./wifi_keepalive.sh
#
# Background after copy to Pi:
#   ./wifi_keepalive.sh --daemon
#
# Log: /tmp/wifi-keepalive.log (override with WIFI_KEEPALIVE_LOG)
# =============================================================================

SSID="${WIFI_SSID:-TOT}"
PASS="${WIFI_PASS:-TOT12345}"
INTERVAL="${WIFI_INTERVAL:-30}"
LOG="${WIFI_KEEPALIVE_LOG:-/tmp/wifi-keepalive.log}"

if ! command -v nmcli &>/dev/null; then
  echo "nmcli not found. Install/use NetworkManager, or use wpa_supplicant instead." >&2
  exit 1
fi

if [[ "${1:-}" == "--daemon" ]]; then
  nohup "$0" >>"$LOG" 2>&1 &
  echo "wifi_keepalive started in background (PID $!). Log: $LOG"
  exit 0
fi

exec 200>/tmp/wifi-keepalive.flock
flock -n 200 || {
  echo "Another wifi_keepalive.sh is already running." >&2
  exit 1
}

echo "wifi_keepalive: SSID=$SSID interval=${INTERVAL}s (set WIFI_SSID/WIFI_PASS to override)"
echo "Stop: pkill -f wifi_keepalive.sh"

while true; do
  if ! nmcli -t -f STATE g 2>/dev/null | grep -q '^connected$'; then
    echo "$(date -Is) not connected, connecting to ${SSID}..."
    nmcli dev wifi connect "$SSID" password "$PASS" || true
  fi
  sleep "$INTERVAL"
done
