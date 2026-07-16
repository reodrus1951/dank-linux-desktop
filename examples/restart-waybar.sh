#!/usr/bin/env bash
# restart-waybar.sh — Example: Safely restart Waybar
# Usage: ./restart-waybar.sh

set -euo pipefail

echo "Restarting Waybar..."

# Kill existing instance
if pgrep -x waybar &>/dev/null; then
    OLD_PID=$(pgrep -x waybar | head -1)
    echo "  Killing existing Waybar (PID: $OLD_PID)"
    killall waybar 2>/dev/null || true
    sleep 0.5
else
    echo "  Waybar was not running"
fi

# Validate config before starting
CONFIG=""
if [[ -f "$HOME/.config/waybar/config.jsonc" ]]; then
    CONFIG="$HOME/.config/waybar/config.jsonc"
elif [[ -f "$HOME/.config/waybar/config" ]]; then
    CONFIG="$HOME/.config/waybar/config"
fi

if [[ -n "$CONFIG" ]]; then
    STRIPPED=$(sed 's|//.*||' "$CONFIG" | sed '/\/\*/,/\*\//d')
    if echo "$STRIPPED" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        echo "  ✓ Config JSON is valid"
    else
        echo "  ⚠ Config JSON has syntax errors — Waybar may not start correctly"
        echo "  Run: python3 -c \"import json; json.load(open('$CONFIG'))\" to check"
    fi
fi

# Start Waybar
nohup waybar &>/dev/null &
disown
echo "  Starting new Waybar instance..."

# Wait and verify
sleep 2
if pgrep -x waybar &>/dev/null; then
    NEW_PID=$(pgrep -x waybar | head -1)
    echo "  ✓ Waybar is running (PID: $NEW_PID)"
else
    echo "  ✗ Waybar failed to start"
    echo "  Run 'waybar -l debug' to see errors"
    exit 1
fi

echo ""
echo "Done."
