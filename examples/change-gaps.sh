#!/usr/bin/env bash
# change-gaps.sh — Example: Modify gap settings in Hyprland
# Usage: ./change-gaps.sh [gaps_in] [gaps_out]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

GAPS_IN="${1:-5}"
GAPS_OUT="${2:-10}"

echo "Changing gap settings:"
echo "  gaps_in=$GAPS_IN, gaps_out=$GAPS_OUT"
echo ""

# Apply at runtime via hyprctl (instant, non-persistent)
hyprctl keyword general:gaps_in "$GAPS_IN"
hyprctl keyword general:gaps_out "$GAPS_OUT"

echo "Applied at runtime."
echo ""
echo "Note: DMS manages gaps via ~/.config/hypr/dms/layout.conf"
echo "These runtime changes will be overridden on next DMS restart."
echo ""
echo "To make permanent, add AFTER the source lines in hyprland.conf:"
echo "  general {"
echo "      gaps_in = $GAPS_IN"
echo "      gaps_out = $GAPS_OUT"
echo "  }"
