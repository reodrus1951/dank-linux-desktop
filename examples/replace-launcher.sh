#!/usr/bin/env bash
# replace-launcher.sh — Example: Switch application launcher
# Usage: ./replace-launcher.sh <launcher>
#   Launchers: rofi, wofi, dms

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <launcher>"
    echo ""
    echo "Launchers:"
    echo "  rofi    — Rofi (drun mode)"
    echo "  wofi    — Wofi"
    echo "  dms     — DMS Spotlight (default for DMS setups)"
    exit 1
fi

LAUNCHER="$1"

BINDS_FILE="$HOME/.config/hypr/dms/binds.conf"
[[ -f "$BINDS_FILE" ]] || BINDS_FILE="$HOME/.config/hypr/hyprland.conf"

echo "Switching launcher to: $LAUNCHER"
echo ""

# Determine the exec command
case "$LAUNCHER" in
    rofi)
        if ! command -v rofi &>/dev/null; then
            echo "Rofi not installed. Install with: sudo pacman -S rofi"
            exit 1
        fi
        EXEC_CMD="rofi -show drun -show-icons"
        ;;
    wofi)
        if ! command -v wofi &>/dev/null; then
            echo "Wofi not installed. Install with: sudo pacman -S wofi"
            exit 1
        fi
        EXEC_CMD="wofi --show drun"
        ;;
    dms)
        EXEC_CMD="dms ipc call spotlight toggle"
        ;;
    *)
        echo "Unknown launcher: $LAUNCHER"
        exit 1
        ;;
esac

# Backup
"$SCRIPT_DIR/backup.sh" "$BINDS_FILE"

# Replace the SUPER+Space binding
if grep -q 'SUPER, space, exec,' "$BINDS_FILE"; then
    sed -i "s|bind = SUPER, space, exec, .*|bind = SUPER, space, exec, $EXEC_CMD|" "$BINDS_FILE"
    echo "✓ Updated SUPER+Space to: $EXEC_CMD"
else
    echo "bind = SUPER, space, exec, $EXEC_CMD" >> "$BINDS_FILE"
    echo "✓ Added SUPER+Space binding: $EXEC_CMD"
fi

# Reload
hyprctl reload

echo ""
echo "Done. Press SUPER+Space to launch $LAUNCHER."
