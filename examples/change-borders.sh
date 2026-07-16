#!/usr/bin/env bash
# change-borders.sh — Example: Modify border settings in Hyprland
# Usage: ./change-borders.sh [size] [active_color] [inactive_color]

set -euo pipefail

SIZE="${1:-2}"
ACTIVE="${2:-rgba(33ccffee)}"
INACTIVE="${3:-rgba(595959aa)}"

echo "Changing border settings:"
echo "  size=$SIZE"
echo "  active_color=$ACTIVE"
echo "  inactive_color=$INACTIVE"
echo ""

# Apply at runtime
hyprctl keyword general:border_size "$SIZE"
hyprctl keyword general:col.active_border "$ACTIVE"
hyprctl keyword general:col.inactive_border "$INACTIVE"

echo "Applied at runtime."
echo ""
echo "Note: DMS manages border colors via ~/.config/hypr/dms/colors.conf"
echo "To override permanently, add AFTER source lines in hyprland.conf."

# Gradient border example
echo ""
echo "For a gradient border, use:"
echo "  hyprctl keyword general:col.active_border 'rgba(33ccffee) rgba(00ff99ee) 45deg'"
