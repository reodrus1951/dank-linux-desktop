#!/usr/bin/env bash
# install-packages.sh — Example: Safely install packages
# Usage: ./install-packages.sh <package1> [package2] ...

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <package1> [package2] ..."
    echo ""
    echo "Safely install packages using pacman or paru."
    echo "Checks official repos first, falls back to AUR."
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

for pkg in "$@"; do
    echo -e "${CYAN}━━ Package: ${pkg} ━━${NC}"

    # Check if already installed
    if pacman -Qi "$pkg" &>/dev/null; then
        INSTALLED_VER=$(pacman -Qi "$pkg" | grep Version | awk '{print $3}')
        echo -e "  ${GREEN}✓ Already installed (version: $INSTALLED_VER)${NC}"
        echo ""
        continue
    fi

    # Check official repos
    if pacman -Si "$pkg" &>/dev/null; then
        REPO=$(pacman -Si "$pkg" 2>/dev/null | grep Repository | awk '{print $3}')
        VERSION=$(pacman -Si "$pkg" 2>/dev/null | grep Version | awk '{print $3}')
        SIZE=$(pacman -Si "$pkg" 2>/dev/null | grep "Download Size" | awk '{print $4, $5}')
        echo "  Repository: $REPO"
        echo "  Version: $VERSION"
        echo "  Size: $SIZE"
        echo ""
        echo -e "  ${YELLOW}Installing from official repos...${NC}"
        sudo pacman -S --needed "$pkg"
        echo -e "  ${GREEN}✓ Installed${NC}"
    elif [[ -n "$AUR_HELPER" ]]; then
        # Check AUR
        echo "  Not in official repos. Checking AUR..."
        AUR_INFO=$($AUR_HELPER -Si "$pkg" 2>/dev/null || true)
        if [[ -n "$AUR_INFO" ]]; then
            AUR_VOTES=$(echo "$AUR_INFO" | grep -i votes | awk '{print $3}' || echo "?")
            AUR_UPDATED=$(echo "$AUR_INFO" | grep -i "Last Modified" | sed 's/.*: //' || echo "?")
            echo "  AUR package found"
            echo "  Votes: $AUR_VOTES"
            echo "  Last updated: $AUR_UPDATED"

            # Warn if low votes
            if [[ "$AUR_VOTES" != "?" ]] && [[ "$AUR_VOTES" -lt 10 ]]; then
                echo -e "  ${YELLOW}⚠ Low vote count ($AUR_VOTES). Proceed with caution.${NC}"
            fi

            echo ""
            echo -e "  ${YELLOW}Installing from AUR...${NC}"
            $AUR_HELPER -S "$pkg"
            echo -e "  ${GREEN}✓ Installed${NC}"
        else
            echo -e "  ${YELLOW}⚠ Package not found in repos or AUR: $pkg${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ Not in official repos and no AUR helper available${NC}"
        echo "  Install paru: sudo pacman -S paru"
    fi
    echo ""
done

echo -e "${GREEN}Done.${NC}"
