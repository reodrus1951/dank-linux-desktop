#!/usr/bin/env bash
# change-terminal.sh — Example: Switch default terminal emulator
# Usage: ./change-terminal.sh <terminal>
#   Terminals: kitty, foot, ghostty, wezterm, alacritty

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <terminal>"
    echo ""
    echo "Terminals: kitty, foot, ghostty, wezterm, alacritty"
    exit 1
fi

TERMINAL="$1"

# Verify terminal is installed
if ! command -v "$TERMINAL" &>/dev/null; then
    echo "Error: $TERMINAL is not installed."
    echo ""
    echo "Install it first:"
    case "$TERMINAL" in
        kitty)    echo "  sudo pacman -S kitty" ;;
        foot)      echo "  sudo pacman -S foot" ;;
        ghostty)   echo "  paru -S ghostty" ;;
        wezterm)   echo "  sudo pacman -S wezterm" ;;
        alacritty) echo "  sudo pacman -S alacritty" ;;
    esac
    exit 1
fi

BINDS_FILE="$HOME/.config/hypr/dms/binds.conf"
[[ -f "$BINDS_FILE" ]] || BINDS_FILE="$HOME/.config/hypr/hyprland.conf"

echo "Changing default terminal to: $TERMINAL"
echo "Config file: $BINDS_FILE"
echo ""

# Backup
"$SCRIPT_DIR/backup.sh" "$BINDS_FILE"

# Find and replace the terminal keybinding
if grep -q 'SUPER, T, exec,' "$BINDS_FILE"; then
    sed -i "s|bind = SUPER, T, exec, .*|bind = SUPER, T, exec, $TERMINAL|" "$BINDS_FILE"
    echo "✓ Updated SUPER+T keybinding to launch $TERMINAL"
else
    echo "bind = SUPER, T, exec, $TERMINAL" >> "$BINDS_FILE"
    echo "✓ Added SUPER+T keybinding for $TERMINAL"
fi

# Reload
hyprctl reload

echo ""
echo "Done. Press SUPER+T to open $TERMINAL."
