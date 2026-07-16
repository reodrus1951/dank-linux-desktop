#!/usr/bin/env bash
# recover-config.sh — Example: Recover from a broken Hyprland config
# Usage: ./recover-config.sh [--minimal]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

MINIMAL=false
[[ "${1:-}" == "--minimal" ]] && MINIMAL=true

CONFIG="$HOME/.config/hypr/hyprland.conf"
BACKUP_DIR="$HOME/.config/hypr/.backups"

echo -e "${CYAN}Hyprland Config Recovery Tool${NC}"
echo ""

# Step 1: Check if Hyprland is responsive
if hyprctl version &>/dev/null; then
    echo -e "${GREEN}✓ Hyprland is running and responsive${NC}"
    HYPR_RUNNING=true
else
    echo -e "${YELLOW}⚠ Hyprland is not responding (may be crashed)${NC}"
    HYPR_RUNNING=false
fi

echo ""

# Step 2: Check for backups
if [[ -d "$BACKUP_DIR" ]]; then
    BACKUPS=($(find "$BACKUP_DIR" -maxdepth 1 -name 'hyprland.conf.*' -type f 2>/dev/null | sort))
    BACKUP_COUNT=${#BACKUPS[@]}
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo "Found $BACKUP_COUNT backup(s):"
        for b in "${BACKUPS[@]}"; do
            TS=$(basename "$b" | sed 's/hyprland.conf.//')
            echo "  • $TS"
        done
        echo ""
    else
        echo -e "${YELLOW}No backups found${NC}"
    fi
else
    BACKUP_COUNT=0
    echo -e "${YELLOW}No backup directory found${NC}"
fi

if [[ "$MINIMAL" == "true" ]]; then
    # Step 3a: Apply minimal config
    echo -e "${YELLOW}Applying minimal safe config...${NC}"

    # Backup current broken config
    if [[ -f "$CONFIG" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$CONFIG" "${BACKUP_DIR}/hyprland.conf.broken.$(date +%Y-%m-%d_%H-%M-%S)"
        echo "  Broken config saved to backups"
    fi

    # Copy minimal template
    TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"
    if [[ -f "$TEMPLATE_DIR/hyprland-minimal.conf" ]]; then
        cp "$TEMPLATE_DIR/hyprland-minimal.conf" "$CONFIG"
        echo -e "${GREEN}✓ Minimal config applied${NC}"
    else
        echo -e "${RED}✗ Template not found. Creating inline minimal config...${NC}"
        cat > "$CONFIG" << 'MINIMAL'
monitor = , preferred, auto, auto
input { kb_layout = us }
general { gaps_in = 5; gaps_out = 10; border_size = 2; layout = dwindle }
decoration { rounding = 10 }
misc { disable_hyprland_logo = true }
bind = SUPER, T, exec, kitty
bind = SUPER, Q, killactive
bind = SUPER SHIFT, E, exit
MINIMAL
        echo -e "${GREEN}✓ Inline minimal config created${NC}"
    fi
else
    # Step 3b: Restore from backup
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        LATEST="${BACKUPS[$((BACKUP_COUNT - 1))]}"
        LATEST_TS=$(basename "$LATEST" | sed 's/hyprland.conf.//')

        echo "Restoring from most recent backup: $LATEST_TS"

        # Save broken config
        if [[ -f "$CONFIG" ]]; then
            mkdir -p "$BACKUP_DIR"
            cp "$CONFIG" "${BACKUP_DIR}/hyprland.conf.broken.$(date +%Y-%m-%d_%H-%M-%S)"
        fi

        cp "$LATEST" "$CONFIG"
        echo -e "${GREEN}✓ Config restored from backup${NC}"
    else
        echo -e "${RED}No backups available. Use --minimal for a safe minimal config.${NC}"
        exit 1
    fi
fi

# Step 4: Reload
echo ""
if [[ "$HYPR_RUNNING" == "true" ]]; then
    echo "Reloading Hyprland..."
    hyprctl reload 2>/dev/null && echo -e "${GREEN}✓ Hyprland reloaded${NC}" || echo -e "${YELLOW}⚠ Reload returned an error${NC}"
else
    echo "Hyprland is not running. Start a new session or restart your display manager:"
    echo "  sudo systemctl restart sddm"
fi

echo ""
echo -e "${GREEN}Recovery complete.${NC}"
