#!/usr/bin/env bash
# safe-edit.sh — Safely edit a config file with backup, validation, and rollback
# Usage: ./safe-edit.sh <filepath> <component> [--editor <cmd>]
#
# Opens the file for editing (using $EDITOR or nano), then:
# 1. Creates a timestamped backup BEFORE the edit
# 2. Launches the editor
# 3. Validates the config after editing
# 4. Reloads the component
# 5. Auto-rolls back if validation fails
#
# For programmatic use (no editor), use the --stdin flag:
#   echo "new content" | ./safe-edit.sh <filepath> <component> --stdin
#
# Or use --replace to replace specific text:
#   ./safe-edit.sh <filepath> <component> --replace "old text" "new text"
#
# Exit codes:
#   0 — Edit successful, validation passed
#   1 — Edit failed, rolled back
#   2 — Invalid arguments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") <filepath> <component> [options]"
    echo ""
    echo "Safely edit a config file with backup, validation, and auto-rollback."
    echo ""
    echo "Options:"
    echo "  --editor <cmd>              Use specific editor (default: \$EDITOR or nano)"
    echo "  --stdin                     Read new content from stdin (replaces file)"
    echo "  --replace <old> <new>       Replace specific text in the file"
    echo "  --append <text>             Append text to the file"
    echo "  --insert <line> <text>      Insert text at specific line number"
    echo "  --no-validate               Skip validation (NOT recommended)"
    echo ""
    echo "Components: hyprland, waybar, kitty, foot, rofi, dunst, mako, etc."
    echo ""
    echo "Examples:"
    echo "  # Interactive edit"
    echo "  $(basename "$0") ~/.config/caelestia/hypr-user.lua caelestia"
    echo ""
    echo "  # Programmatic append"
    echo "  $(basename "$0") ~/.config/caelestia/hypr-user.lua caelestia --append 'hl.bind(\"SUPER + B\", hl.dsp.exec_cmd(\"firefox\"))'"
    echo ""
    echo "  # Programmatic replace"
    echo "  $(basename "$0") ~/.config/caelestia/hypr-vars.lua caelestia --replace 'windowGapsIn = 5' 'windowGapsIn = 10'"
    exit 0
}

if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
fi

FILEPATH="$(realpath "$1" 2>/dev/null || echo "$1")"
COMPONENT="$2"
shift 2 || true

MODE="interactive"
EDITOR_CMD="${EDITOR:-nano}"
REPLACE_OLD=""
REPLACE_NEW=""
APPEND_TEXT=""
INSERT_LINE=""
INSERT_TEXT=""
DO_VALIDATE=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --editor)    EDITOR_CMD="$2"; shift 2 ;;
        --stdin)     MODE="stdin"; shift ;;
        --replace)   MODE="replace"; REPLACE_OLD="$2"; REPLACE_NEW="$3"; shift 3 ;;
        --append)    MODE="append"; APPEND_TEXT="$2"; shift 2 ;;
        --insert)    MODE="insert"; INSERT_LINE="$2"; INSERT_TEXT="$3"; shift 3 ;;
        --no-validate) DO_VALIDATE=false; shift ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            exit 2
            ;;
    esac
done

# ━━━ Verify file exists ━━━

if [[ ! -f "$FILEPATH" ]]; then
    echo -e "${RED}Error: File not found: ${FILEPATH}${NC}" >&2
    exit 2
fi

# ━━━ Step 1: Backup ━━━

echo -e "${CYAN}Step 1: Creating backup...${NC}"
"$SCRIPT_DIR/backup.sh" "$FILEPATH"

BACKUP_DIR="$(dirname "$FILEPATH")/.backups"
BASENAME="$(basename "$FILEPATH")"
LATEST_BACKUP="$(find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" -type f 2>/dev/null | sort | tail -1)"

echo ""

# ━━━ Step 2: Edit ━━━

echo -e "${CYAN}Step 2: Editing ${FILEPATH}...${NC}"

case "$MODE" in
    interactive)
        echo -e "  ${DIM}Opening with: ${EDITOR_CMD}${NC}"
        "$EDITOR_CMD" "$FILEPATH"
        ;;

    stdin)
        echo -e "  ${DIM}Reading new content from stdin...${NC}"
        cat > "$FILEPATH"
        echo -e "  ${GREEN}✓ Content written${NC}"
        ;;

    replace)
        if [[ -z "$REPLACE_OLD" ]]; then
            echo -e "${RED}Error: --replace requires old and new text${NC}" >&2
            exit 2
        fi

        # Check that old text exists
        if ! grep -qF "$REPLACE_OLD" "$FILEPATH"; then
            echo -e "${RED}Error: Text not found in file: ${REPLACE_OLD}${NC}" >&2
            exit 2
        fi

        # Count occurrences
        local_count=$(grep -cF "$REPLACE_OLD" "$FILEPATH")
        echo -e "  ${DIM}Found ${local_count} occurrence(s) of target text${NC}"

        # Perform replacement (escape special chars for sed)
        local escaped_old escaped_new
        escaped_old=$(printf '%s\n' "$REPLACE_OLD" | sed 's/[.[*^$()+?{|]/\\&/g')
        escaped_new=$(printf '%s\n' "$REPLACE_NEW" | sed 's/[.[*^$()+?{|]/\\&/g' | sed 's/&/\\&/g')
        sed -i "s|${escaped_old}|${escaped_new}|g" "$FILEPATH"

        echo -e "  ${GREEN}✓ Replaced '${REPLACE_OLD}' → '${REPLACE_NEW}'${NC}"
        ;;

    append)
        echo "$APPEND_TEXT" >> "$FILEPATH"
        echo -e "  ${GREEN}✓ Appended text to file${NC}"
        ;;

    insert)
        if [[ -z "$INSERT_LINE" ]] || [[ -z "$INSERT_TEXT" ]]; then
            echo -e "${RED}Error: --insert requires line number and text${NC}" >&2
            exit 2
        fi
        sed -i "${INSERT_LINE}i\\${INSERT_TEXT}" "$FILEPATH"
        echo -e "  ${GREEN}✓ Inserted text at line ${INSERT_LINE}${NC}"
        ;;
esac

echo ""

# ━━━ Step 3: Show diff ━━━

echo -e "${CYAN}Step 3: Changes made:${NC}"
if [[ -n "$LATEST_BACKUP" ]]; then
    if diff --color=auto -u "$LATEST_BACKUP" "$FILEPATH" 2>/dev/null; then
        echo -e "  ${DIM}No changes detected${NC}"
    fi
else
    echo -e "  ${DIM}(no backup to compare against)${NC}"
fi

echo ""

# ━━━ Step 4: Validate ━━━

if [[ "$DO_VALIDATE" == "true" ]]; then
    echo -e "${CYAN}Step 4: Validating ${COMPONENT}...${NC}"
    if "$SCRIPT_DIR/validate.sh" "$COMPONENT" --auto-rollback; then
        echo ""
        echo -e "${GREEN}✓ Edit complete and validated for ${COMPONENT}${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}✗ Validation failed — config has been rolled back${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Step 4: Validation skipped (--no-validate)${NC}"
    echo ""
    echo -e "${GREEN}✓ Edit complete (unvalidated)${NC}"
    exit 0
fi
