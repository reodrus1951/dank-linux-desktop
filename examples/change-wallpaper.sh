#!/usr/bin/env bash
# change-wallpaper.sh — Example: Set wallpaper using swww or hyprpaper
# Usage: ./change-wallpaper.sh <path> [monitor]

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <path-to-image> [monitor]"
    echo ""
    echo "Arguments:"
    echo "  path-to-image   Path to the image file to use as wallpaper"
    echo "  monitor         Target monitor (default: all)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") ~/Pictures/wallpaper.jpg"
    echo "  $(basename "$0") ~/Pictures/wallpaper.jpg DP-1"
    exit 1
fi

IMAGE="$(realpath "$1")"
MONITOR="${2:-}"

if [[ ! -f "$IMAGE" ]]; then
    echo "Error: Image not found: $IMAGE"
    exit 1
fi

echo "Setting wallpaper: $IMAGE"
[[ -n "$MONITOR" ]] && echo "Monitor: $MONITOR" || echo "Monitor: all"
echo ""

# Try DMS first (preferred for DMS setups)
if command -v dms &>/dev/null && systemctl --user is-active dms.service &>/dev/null; then
    echo "DMS detected — use SUPER+Y to open wallpaper picker"
    echo "Or set directly via DMS settings (SUPER+,)"
    echo ""
    echo "For manual override, continuing with fallback methods..."
fi

# Try swww (animated transitions)
if command -v swww &>/dev/null; then
    # Ensure daemon is running
    pgrep -x swww-daemon &>/dev/null || { swww-daemon & sleep 1; }

    if [[ -n "$MONITOR" ]]; then
        swww img "$IMAGE" -o "$MONITOR" --transition-type fade --transition-duration 2
    else
        swww img "$IMAGE" --transition-type fade --transition-duration 2
    fi
    echo "✓ Wallpaper set via swww (with fade transition)"
    exit 0
fi

# Try hyprpaper
if command -v hyprpaper &>/dev/null; then
    # Ensure hyprpaper is running
    if ! pgrep -x hyprpaper &>/dev/null; then
        hyprpaper &
        sleep 1
    fi

    hyprctl hyprpaper preload "$IMAGE"
    if [[ -n "$MONITOR" ]]; then
        hyprctl hyprpaper wallpaper "$MONITOR,$IMAGE"
    else
        hyprctl hyprpaper wallpaper ",$IMAGE"
    fi
    echo "✓ Wallpaper set via hyprpaper"
    echo ""
    echo "To persist, add to ~/.config/hypr/hyprpaper.conf:"
    echo "  preload = $IMAGE"
    echo "  wallpaper = ${MONITOR:-,},$IMAGE"
    exit 0
fi

# Fallback: swaybg
if command -v swaybg &>/dev/null; then
    killall swaybg 2>/dev/null || true
    swaybg -i "$IMAGE" -m fill &
    disown
    echo "✓ Wallpaper set via swaybg"
    exit 0
fi

echo "Error: No wallpaper daemon found. Install one of:"
echo "  sudo pacman -S hyprpaper"
echo "  paru -S swww"
echo "  sudo pacman -S swaybg"
exit 1
