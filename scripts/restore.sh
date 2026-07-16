#!/usr/bin/env bash
# restore.sh — Restore a configuration file from backup
# Usage:
#   ./restore.sh <filepath>                   Restore most recent backup
#   ./restore.sh <filepath> <timestamp>       Restore specific backup
#   ./restore.sh --preview <filepath>         Show what would be restored
#
# Exit codes:
#   0 — Restored successfully
#   1 — Error (file/backup not found)
#   2 — No backups available

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") [--preview] <filepath> [timestamp]"
    echo ""
    echo "Restore a configuration file from a timestamped backup."
    echo ""
    echo "Options:"
    echo "  --preview   Show which backup would be restored, without restoring"
    echo "  --help      Show this help"
    echo ""
    echo "Arguments:"
    echo "  filepath    Path to the config file to restore"
    echo "  timestamp   Specific backup timestamp (e.g., 2026-07-02_13-45-30)"
    echo "              If omitted, restores the most recent backup."
    exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
fi

PREVIEW=false
if [[ "$1" == "--preview" ]]; then
    PREVIEW=true
    shift
fi

if [[ $# -lt 1 ]]; then
    echo -e "${RED}Error: filepath is required${NC}" >&2
    exit 1
fi

FILEPATH="$(realpath "$1" 2>/dev/null || echo "$1")"
TIMESTAMP="${2:-}"

BACKUP_DIR="$(dirname "$FILEPATH")/.backups"
BASENAME="$(basename "$FILEPATH")"

# ━━━ Find Backup ━━━

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo -e "${RED}Error: No backups directory found at: ${BACKUP_DIR}${NC}" >&2
    exit 2
fi

if [[ -n "$TIMESTAMP" ]]; then
    # Specific timestamp requested
    BACKUP_FILE="${BACKUP_DIR}/${BASENAME}.${TIMESTAMP}"
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo -e "${RED}Error: Backup not found: ${BACKUP_FILE}${NC}" >&2
        echo ""
        echo "Available backups:"
        find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" -type f 2>/dev/null | sort | while read -r f; do
            echo "  $(basename "$f" | sed "s/^${BASENAME}\.//")"
        done
        exit 1
    fi
else
    # Find most recent backup (excluding pre-restore files)
    BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" ! -name "*.pre-restore.*" -type f 2>/dev/null | sort | tail -1)"
    if [[ -z "$BACKUP_FILE" ]] || [[ ! -f "$BACKUP_FILE" ]]; then
        echo -e "${RED}Error: No backups found for: ${FILEPATH}${NC}" >&2
        exit 2
    fi
fi

BACKUP_TS="$(basename "$BACKUP_FILE" | sed "s/^${BASENAME}\.//")"

# ━━━ Preview Mode ━━━

if [[ "$PREVIEW" == "true" ]]; then
    echo -e "${CYAN}Would restore:${NC}"
    echo -e "  ${DIM}Backup:  ${BACKUP_FILE}${NC}"
    echo -e "  ${DIM}Target:  ${FILEPATH}${NC}"
    echo -e "  ${DIM}Backup timestamp: ${BACKUP_TS}${NC}"
    echo -e "  ${DIM}Backup size: $(du -h "$BACKUP_FILE" | awk '{print $1}')${NC}"

    if [[ -f "$FILEPATH" ]]; then
        echo ""
        echo -e "${CYAN}Diff (backup → current):${NC}"
        diff --color=auto -u "$BACKUP_FILE" "$FILEPATH" || true
    else
        echo -e "  ${YELLOW}Current file does not exist (will be created)${NC}"
    fi
    exit 0
fi

# ━━━ Restore ━━━

echo -e "${CYAN}Restoring: ${FILEPATH}${NC}"
echo -e "  ${DIM}From backup: ${BACKUP_TS}${NC}"

# If the current file exists, save it as a pre-restore backup first
if [[ -f "$FILEPATH" ]]; then
    PRE_RESTORE="${BACKUP_DIR}/${BASENAME}.pre-restore.$(date +%Y-%m-%d_%H-%M-%S)"
    cp -p "$FILEPATH" "$PRE_RESTORE"
    echo -e "  ${DIM}Pre-restore backup saved: $(basename "$PRE_RESTORE")${NC}"
fi

# Perform the restore
cp -p "$BACKUP_FILE" "$FILEPATH"

echo -e "${GREEN}✓ Restored successfully${NC}"
echo -e "  ${DIM}File: ${FILEPATH}${NC}"
echo -e "  ${DIM}From: ${BACKUP_TS}${NC}"

# Hint about reloading
echo ""
echo -e "${YELLOW}Remember to reload the affected component:${NC}"
echo "  scripts/reload.sh <component>"
echo "  # or: hyprctl reload"

exit 0
