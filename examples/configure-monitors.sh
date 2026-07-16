#!/usr/bin/env bash
# configure-monitors.sh — Example: Set up multi-monitor layout
# Usage: ./configure-monitors.sh [layout]
#   Layouts: side-by-side (default), stacked, mirror

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

LAYOUT="${1:-side-by-side}"

echo "Monitor Configuration Tool"
echo ""

# Detect monitors
echo "Detected monitors:"
hyprctl monitors | grep -E '^Monitor |^\s+\d+x\d+' | head -20
echo ""

MONITORS=($(hyprctl monitors | grep '^Monitor ' | awk '{print $2}'))
MON_COUNT=${#MONITORS[@]}

if [[ $MON_COUNT -lt 1 ]]; then
    echo "Error: No monitors detected"
    exit 1
fi

echo "Found $MON_COUNT monitor(s): ${MONITORS[*]}"
echo ""

if [[ $MON_COUNT -eq 1 ]]; then
    echo "Only one monitor detected. Setting preferred mode."
    hyprctl keyword monitor "${MONITORS[0]}, preferred, auto, 1"
    echo "✓ Monitor configured"
    exit 0
fi

# Get resolutions
get_resolution() {
    hyprctl monitors | grep -A1 "^Monitor $1" | tail -1 | awk '{print $1}' | cut -d@ -f1
}

RES1=$(get_resolution "${MONITORS[0]}")
WIDTH1=$(echo "$RES1" | cut -dx -f1)

echo "Layout: $LAYOUT"
echo ""

case "$LAYOUT" in
    side-by-side)
        echo "Setting side-by-side layout:"
        echo "${MONITORS[0]} at 0x0"
        echo "  ${MONITORS[1]} at ${WIDTH1}x0"
        hyprctl --batch "\
            keyword monitor ${MONITORS[0]},preferred,0x0,1; \
            keyword monitor ${MONITORS[1]},preferred,${WIDTH1}x0,1"
        ;;
    stacked)
        HEIGHT1=$(echo "$RES1" | cut -dx -f2)
        echo "Setting stacked layout:"
        echo "  ${MONITORS[0]} at 0x0"
        echo "  ${MONITORS[1]} at 0x${HEIGHT1}"
        hyprctl --batch "\
            keyword monitor ${MONITORS[0]},preferred,0x0,1; \
            keyword monitor ${MONITORS[1]},preferred,0x${HEIGHT1},1"
        ;;
    mirror)
        echo "Setting mirror layout:"
        echo "  ${MONITORS[1]} mirrors ${MONITORS[0]}"
        hyprctl --batch "\
            keyword monitor ${MONITORS[0]},preferred,auto,1; \
            keyword monitor ${MONITORS[1]},preferred,auto,auto,mirror,${MONITORS[0]}"
        ;;
    *)
        echo "Unknown layout: $LAYOUT"
        echo "Options: side-by-side, stacked, mirror"
        exit 1
        ;;
esac

echo ""
echo "✓ Monitor layout applied (runtime only)."
echo ""
echo "To make permanent, add to hyprland.conf (after source lines):"
echo "  # Or use DMS display settings: SUPER + ,"
