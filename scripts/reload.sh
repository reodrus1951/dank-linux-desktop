#!/usr/bin/env bash
# reload.sh — Reload a desktop component safely
# Usage: ./reload.sh <component>
#
# Components: hyprland, waybar, dunst, mako, kitty, hyprpaper, hypridle,
#             pipewire, wireplumber, caelestia, sddm, networkmanager, all
#
# Exit codes:
#   0 — Reload successful
#   1 — Reload failed or component not recognized
#   2 — Component not running (nothing to reload)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") <component>"
    echo ""
    echo "Reload a desktop component safely."
    echo ""
    echo "Components:"
    echo "  hyprland        Reload Hyprland config (hyprctl reload)"
    echo "  waybar          Restart Waybar"
    echo "  dunst           Restart Dunst notification daemon"
    echo "  mako            Reload Mako notification daemon"
    echo "  kitty           Send reload signal to Kitty"
    echo "  hyprpaper       Restart Hyprpaper"
    echo "  hypridle        Restart Hypridle"
    echo "  pipewire        Restart PipeWire service"
    echo "  wireplumber     Restart WirePlumber service"
    echo "  caelestia       Restart Caelestia shell"
    echo "  sddm            Restart SDDM (⚠ ends session!)"
    echo "  networkmanager  Restart NetworkManager"
    echo "  all             Reload Hyprland + Waybar"
    exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
fi

COMPONENT="$1"

reload_process() {
    local name="$1"
    local cmd="$2"

    echo -e "${CYAN}Reloading ${name}...${NC}"

    if pgrep -x "$name" &>/dev/null; then
        killall "$name" 2>/dev/null || true
        sleep 0.5
    fi

    # Start detached from terminal
    nohup bash -c "$cmd" &>/dev/null &
    disown

    # Wait a moment and verify
    sleep 2
    if pgrep -x "$name" &>/dev/null; then
        echo -e "${GREEN}✓${NC} ${name} reloaded successfully (PID: $(pgrep -x "$name" | head -1))${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} ${name} failed to start${NC}" >&2
        return 1
    fi
}

reload_systemd_user() {
    local service="$1"
    local desc="$2"

    echo -e "${CYAN}Restarting ${desc}...${NC}"

    if ! systemctl --user is-enabled "$service" &>/dev/null; then
        echo -e "${YELLOW}⚠ ${service} is not enabled${NC}"
    fi

    systemctl --user restart "$service"
    sleep 1

    if systemctl --user is-active "$service" &>/dev/null; then
        echo -e "${GREEN}✓${NC} ${desc} restarted successfully${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} ${desc} failed to restart${NC}" >&2
        systemctl --user status "$service" --no-pager 2>/dev/null | tail -5
        return 1
    fi
}

reload_systemd_system() {
    local service="$1"
    local desc="$2"

    echo -e "${YELLOW}⚠ Restarting ${desc} requires sudo and may end your session!${NC}"
    echo -e "${CYAN}Running: sudo systemctl restart ${service}${NC}"

    sudo systemctl restart "$service"
    sleep 1

    if systemctl is-active "$service" &>/dev/null; then
        echo -e "${GREEN}✓${NC} ${desc} restarted successfully${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} ${desc} failed to restart${NC}" >&2
        return 1
    fi
}

case "$COMPONENT" in
    hyprland|hypr)
        echo -e "${CYAN}Reloading Hyprland config...${NC}"
        OUTPUT=$(hyprctl reload 2>&1)
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ Hyprland config reloaded${NC}"
            if [[ -n "$OUTPUT" ]] && [[ "$OUTPUT" != "ok" ]]; then
                echo -e "  ${DIM}${OUTPUT}${NC}"
            fi
        else
            echo -e "${RED}✗ Hyprland reload failed${NC}" >&2
            echo -e "  ${DIM}${OUTPUT}${NC}"
            exit 1
        fi
        ;;

    waybar)
        reload_process "waybar" "waybar"
        ;;

    dunst)
        reload_process "dunst" "dunst"
        ;;

    mako)
        echo -e "${CYAN}Reloading Mako...${NC}"
        if command -v makoctl &>/dev/null; then
            makoctl reload
            echo -e "${GREEN}✓ Mako reloaded${NC}"
        else
            echo -e "${YELLOW}makoctl not found, trying process restart...${NC}"
            reload_process "mako" "mako"
        fi
        ;;

    kitty)
        echo -e "${CYAN}Sending reload signal to Kitty...${NC}"
        if pgrep -x kitty &>/dev/null; then
            pkill -USR1 kitty
            echo -e "${GREEN}✓ Reload signal sent to Kitty${NC}"
        else
            echo -e "${YELLOW}⚠ Kitty is not running${NC}"
            exit 2
        fi
        ;;

    hyprpaper)
        reload_process "hyprpaper" "hyprpaper"
        ;;

    hypridle)
        reload_process "hypridle" "hypridle"
        ;;

    pipewire)
        reload_systemd_user "pipewire.service" "PipeWire"
        ;;

    wireplumber)
        reload_systemd_user "wireplumber.service" "WirePlumber"
        ;;

    audio)
        echo -e "${CYAN}Restarting full audio stack...${NC}"
        reload_systemd_user "pipewire.service" "PipeWire"
        reload_systemd_user "wireplumber.service" "WirePlumber"
        ;;

    caelestia)
        echo -e "${CYAN}Reloading Caelestia Shell...${NC}"
        caelestia shell -k 2>/dev/null || true
        sleep 0.5
        caelestia shell -d 2>/dev/null || true
        sleep 2
        if pgrep -f "qs -c caelestia" &>/dev/null; then
            echo -e "${GREEN}✓ Caelestia shell reloaded successfully${NC}"
        else
            echo -e "${RED}✗ Caelestia shell failed to start${NC}" >&2
            exit 1
        fi
        ;;

    sddm)
        reload_systemd_system "sddm.service" "SDDM display manager"
        ;;

    greetd)
        reload_systemd_system "greetd.service" "greetd display manager"
        ;;

    networkmanager|nm)
        reload_systemd_system "NetworkManager.service" "NetworkManager"
        ;;

    all)
        echo -e "${CYAN}Reloading all desktop components...${NC}"
        echo ""

        # Hyprland
        hyprctl reload 2>/dev/null && echo -e "${GREEN}✓ Hyprland reloaded${NC}" || echo -e "${YELLOW}⚠ Hyprland reload skipped${NC}"

        # Waybar
        if pgrep -x waybar &>/dev/null; then
            killall waybar 2>/dev/null || true
            sleep 0.5
            nohup waybar &>/dev/null &
            disown
            sleep 2
            pgrep -x waybar &>/dev/null && echo -e "${GREEN}✓ Waybar reloaded${NC}" || echo -e "${YELLOW}⚠ Waybar failed to restart${NC}"
        fi

        echo ""
        echo -e "${GREEN}✓ Desktop reload complete${NC}"
        ;;

    *)
        echo -e "${RED}Unknown component: ${COMPONENT}${NC}" >&2
        echo ""
        echo "Use --help to see available components."
        exit 1
        ;;
esac

exit 0
