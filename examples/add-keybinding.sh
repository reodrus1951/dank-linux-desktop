#!/usr/bin/env bash
# add-keybinding.sh — Example: Add a new keybinding to Hyprland
# Usage: ./add-keybinding.sh <modifiers> <key> <dispatcher> [params]
# Example: ./add-keybinding.sh "SUPER" "B" "exec" "firefox"

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

if [[ $# -lt 3 ]]; then
    echo "Usage: $(basename "$0") <modifiers> <key> <dispatcher> [params]"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") 'SUPER' 'B' 'exec' 'firefox'"
    echo "  $(basename "$0") 'SUPER SHIFT' 'S' 'exec' 'grim -g \"\$(slurp)\"'"
    echo "  $(basename "$0") 'SUPER' 'P' 'pseudo'"
    exit 1
fi

MODS="$1"
KEY="$2"
DISPATCHER="$3"
PARAMS="${4:-}"

# Determine target file
BINDS_FILE="$HOME/.config/hypr/dms/binds.conf"
if [[ ! -f "$BINDS_FILE" ]]; then
    BINDS_FILE="$HOME/.config/hypr/hyprland.conf"
fi

BIND_LINE="bind = ${MODS}, ${KEY}, ${DISPATCHER}"
[[ -n "$PARAMS" ]] && BIND_LINE="${BIND_LINE}, ${PARAMS}"

echo "Adding keybinding: $BIND_LINE"
echo "Target file: $BINDS_FILE"
echo ""

# Check for conflicts
EXISTING=$(grep -n "bind.*=.*${MODS},.*${KEY}," "$BINDS_FILE" 2>/dev/null || true)
if [[ -n "$EXISTING" ]]; then
    echo "⚠ Warning: Similar binding already exists:"
    echo "$EXISTING"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
fi

# Backup
"$SCRIPT_DIR/backup.sh" "$BINDS_FILE"

# Append
echo "" >> "$BINDS_FILE"
echo "# Added by add-keybinding.sh on $(date -Iseconds)" >> "$BINDS_FILE"
echo "$BIND_LINE" >> "$BINDS_FILE"

# Reload
hyprctl reload

echo ""
echo "✓ Keybinding added and loaded."
echo "  Press ${MODS} + ${KEY} to test."
