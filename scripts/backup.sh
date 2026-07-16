#!/usr/bin/env bash
# backup.sh — Create, list, and diff timestamped configuration backups
# Usage:
#   ./backup.sh <filepath>                    Create a timestamped backup
#   ./backup.sh --list <filepath>             List all backups for a file
#   ./backup.sh --diff <filepath>             Diff current vs most recent backup
#   ./backup.sh --diff <filepath> <timestamp> Diff current vs specific backup
#   ./backup.sh --cleanup <filepath> [keep]   Remove old backups, keep N newest (default: 20)
#
# Backups are stored in a .backups/ directory next to the original file.
# Format: <filename>.<YYYY-MM-DD_HH-MM-SS>
#
# Exit codes:
#   0 — Success
#   1 — Error (file not found, invalid arguments)
#   2 — No backups found (for --list, --diff)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") [--list|--diff|--cleanup] <filepath> [args...]"
    echo ""
    echo "Commands:"
    echo "  <filepath>                      Create a timestamped backup"
    echo "  --list <filepath>               List all backups for a file"
    echo "  --diff <filepath> [timestamp]   Diff current vs backup"
    echo "  --cleanup <filepath> [keep]     Remove old backups (default keep: 20)"
    echo "  --help                          Show this help"
    exit 0
}

get_backup_dir() {
    local filepath="$1"
    local dir
    dir="$(dirname "$filepath")"
    echo "${dir}/.backups"
}

get_backup_prefix() {
    local filepath="$1"
    basename "$filepath"
}

timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

# ━━━ Parse Arguments ━━━

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
fi

ACTION="create"
case "$1" in
    --list)    ACTION="list";    shift ;;
    --diff)    ACTION="diff";    shift ;;
    --cleanup) ACTION="cleanup"; shift ;;
esac

if [[ $# -lt 1 ]]; then
    echo -e "${RED}Error: filepath is required${NC}" >&2
    exit 1
fi

FILEPATH="$(realpath "$1" 2>/dev/null || echo "$1")"
BACKUP_DIR="$(get_backup_dir "$FILEPATH")"
BASENAME="$(get_backup_prefix "$FILEPATH")"

# ━━━ Create Backup ━━━

if [[ "$ACTION" == "create" ]]; then
    if [[ ! -f "$FILEPATH" ]]; then
        echo -e "${RED}Error: File not found: ${FILEPATH}${NC}" >&2
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"

    TS="$(timestamp)"
    BACKUP_PATH="${BACKUP_DIR}/${BASENAME}.${TS}"

    # Avoid overwriting if backup already exists (sub-second operations)
    if [[ -f "$BACKUP_PATH" ]]; then
        BACKUP_PATH="${BACKUP_PATH}.$(date +%N | head -c3)"
    fi

    cp -p "$FILEPATH" "$BACKUP_PATH"
    echo -e "${GREEN}✓${NC} Backup created: ${BACKUP_PATH}"
    echo -e "  ${DIM}Original: ${FILEPATH}${NC}"
    echo -e "  ${DIM}Size: $(du -h "$BACKUP_PATH" | awk '{print $1}')${NC}"
    exit 0
fi

# ━━━ List Backups ━━━

if [[ "$ACTION" == "list" ]]; then
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups directory found for: ${FILEPATH}${NC}"
        exit 2
    fi

    BACKUPS=()
    while IFS= read -r -d '' f; do
        BACKUPS+=("$f")
    done < <(find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" -type f -print0 2>/dev/null | sort -z)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No backups found for: ${FILEPATH}${NC}"
        exit 2
    fi

    echo -e "${CYAN}Backups for: ${FILEPATH}${NC}"
    echo -e "${CYAN}Directory: ${BACKUP_DIR}${NC}"
    echo ""

    for backup in "${BACKUPS[@]}"; do
        local_name="$(basename "$backup")"
        ts="${local_name#${BASENAME}.}"
        size="$(du -h "$backup" | awk '{print $1}')"
        mod_time="$(stat -c '%y' "$backup" | cut -d'.' -f1)"
        echo -e "  ${GREEN}•${NC} ${ts}  ${DIM}(${size}, modified ${mod_time})${NC}"
    done

    echo ""
    echo -e "${DIM}Total: ${#BACKUPS[@]} backup(s)${NC}"
    exit 0
fi

# ━━━ Diff Against Backup ━━━

if [[ "$ACTION" == "diff" ]]; then
    if [[ ! -f "$FILEPATH" ]]; then
        echo -e "${RED}Error: File not found: ${FILEPATH}${NC}" >&2
        exit 1
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups directory found for: ${FILEPATH}${NC}"
        exit 2
    fi

    SPECIFIC_TS="${2:-}"

    if [[ -n "$SPECIFIC_TS" ]]; then
        BACKUP_FILE="${BACKUP_DIR}/${BASENAME}.${SPECIFIC_TS}"
        if [[ ! -f "$BACKUP_FILE" ]]; then
            echo -e "${RED}Error: Backup not found: ${BACKUP_FILE}${NC}" >&2
            exit 1
        fi
    else
        BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" -type f 2>/dev/null | sort | tail -1)"
        if [[ -z "$BACKUP_FILE" ]] || [[ ! -f "$BACKUP_FILE" ]]; then
            echo -e "${YELLOW}No backups found for: ${FILEPATH}${NC}"
            exit 2
        fi
    fi

    echo -e "${CYAN}Comparing:${NC}"
    echo -e "  ${DIM}Backup:  $(basename "$BACKUP_FILE")${NC}"
    echo -e "  ${DIM}Current: ${FILEPATH}${NC}"
    echo ""

    if diff --color=auto -u "$BACKUP_FILE" "$FILEPATH"; then
        echo -e "${GREEN}✓ No differences${NC}"
    else
        echo ""
        echo -e "${YELLOW}Files differ (see diff above)${NC}"
    fi
    exit 0
fi

# ━━━ Cleanup Old Backups ━━━

if [[ "$ACTION" == "cleanup" ]]; then
    KEEP="${2:-20}"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups directory found for: ${FILEPATH}${NC}"
        exit 2
    fi

    BACKUPS=()
    while IFS= read -r f; do
        BACKUPS+=("$f")
    done < <(find "$BACKUP_DIR" -maxdepth 1 -name "${BASENAME}.*" -type f 2>/dev/null | sort)

    local_total=${#BACKUPS[@]}

    if [[ $local_total -le $KEEP ]]; then
        echo -e "${GREEN}✓ Only ${local_total} backup(s) exist, keeping all (threshold: ${KEEP})${NC}"
        exit 0
    fi

    TO_DELETE=$((local_total - KEEP))
    echo -e "${CYAN}Cleaning up: removing ${TO_DELETE} old backup(s), keeping newest ${KEEP}${NC}"

    for ((i = 0; i < TO_DELETE; i++)); do
        rm -f "${BACKUPS[$i]}"
        echo -e "  ${DIM}Removed: $(basename "${BACKUPS[$i]}")${NC}"
    done

    echo -e "${GREEN}✓ Cleanup complete. ${KEEP} backup(s) remaining.${NC}"
    exit 0
fi
