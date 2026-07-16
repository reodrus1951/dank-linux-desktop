#!/usr/bin/env bash
# change-blur.sh — Example: Modify blur settings in Hyprland
# Usage: ./change-blur.sh [size] [passes] [noise]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

SIZE="${1:-5}"
PASSES="${2:-2}"
NOISE="${3:-0.02}"

CONFIG="$HOME/.config/hypr/hyprland.conf"

echo "Changing blur settings:"
echo "  size=$SIZE, passes=$PASSES, noise=$NOISE"
echo ""

# Step 1: Backup
"$SCRIPT_DIR/backup.sh" "$CONFIG"

# Step 2: Check if blur block exists
if grep -q 'blur {' "$CONFIG"; then
    echo "Found existing blur block, updating..."
    # Use hyprctl for runtime change
    hyprctl keyword decoration:blur:size "$SIZE"
    hyprctl keyword decoration:blur:passes "$PASSES"
    hyprctl keyword decoration:blur:noise "$NOISE"
    echo "Applied at runtime via hyprctl."
    echo ""
    echo "To make permanent, edit the blur block in hyprland.conf:"
    echo "  decoration {"
    echo "      blur {"
    echo "          size = $SIZE"
    echo "          passes = $PASSES"
    echo "          noise = $NOISE"
    echo "      }"
    echo "  }"
else
    echo "No blur block found. Adding one at the end of the file..."
    echo "
# Blur settings (added by change-blur.sh)
decoration {
    blur {
        enabled = true
        size = $SIZE
        passes = $PASSES
        noise = $NOISE
    }
}" >> "$CONFIG"
    hyprctl reload
fi

echo ""
echo "Done. Blur updated."
