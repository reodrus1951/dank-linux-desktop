#!/usr/bin/env bash
# find-config.sh — Find configuration files for a given component
# Usage: ./find-config.sh <component> [--all]
#
# Locates all config files for the specified component, including
# source'd/included files for Hyprland's modular config system.
#
# Components: hyprland, waybar, kitty, foot, ghostty, wezterm, alacritty,
#             rofi, wofi, hyprlock, hypridle, hyprpaper, dunst, mako,
#             wlogout, gtk, qt, pipewire, wireplumber, sddm, greetd, caelestia
#
# Exit codes:
#   0 — Config files found
#   1 — Component not recognized
#   2 — No config files found for component

set -euo pipefail

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $(basename "$0") <component> [--all]"
    echo ""
    echo "Find configuration files for a desktop component."
    echo ""
    echo "Components:"
    echo "  hyprland    Hyprland compositor (discovers source'd files recursively)"
    echo "  waybar      Waybar status bar"
    echo "  kitty       Kitty terminal"
    echo "  foot        Foot terminal"
    echo "  ghostty     Ghostty terminal"
    echo "  wezterm     WezTerm terminal"
    echo "  alacritty   Alacritty terminal"
    echo "  rofi        Rofi launcher"
    echo "  wofi        Wofi launcher"
    echo "  hyprlock    Hyprlock screen locker"
    echo "  hypridle    Hypridle idle daemon"
    echo "  hyprpaper   Hyprpaper wallpaper daemon"
    echo "  dunst       Dunst notification daemon"
    echo "  mako        Mako notification daemon"
    echo "  wlogout     Wlogout logout menu"
    echo "  gtk         GTK 3 and GTK 4 settings"
    echo "  qt          Qt 5 and Qt 6 settings"
    echo "  pipewire    PipeWire audio"
    echo "  wireplumber WirePlumber session manager"
    echo "  sddm        SDDM display manager"
    echo "  greetd      greetd display manager"
    echo "  caelestia   Caelestia Shell"
    echo ""
    echo "Options:"
    echo "  --all       Show file contents alongside paths"
    exit 0
fi

COMPONENT="$1"
SHOW_ALL="${2:-}"
FOUND=0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

show_file() {
    local filepath="$1"
    local label="${2:-}"
    local expanded="${filepath/#\~/$HOME}"

    if [[ -f "$expanded" ]]; then
        echo -e "${GREEN}✓${NC} ${filepath}"
        if [[ -n "$label" ]]; then
            echo -e "  ${DIM}${label}${NC}"
        fi
        local size
        size=$(wc -l < "$expanded")
        echo -e "  ${DIM}${size} lines, $(du -h "$expanded" | awk '{print $1}')${NC}"
        if [[ "$SHOW_ALL" == "--all" ]]; then
            echo -e "  ${DIM}─── contents ───${NC}"
            sed 's/^/  │ /' "$expanded"
            echo -e "  ${DIM}─── end ───${NC}"
        fi
        FOUND=$((FOUND + 1))
    elif [[ -d "$expanded" ]]; then
        echo -e "${CYAN}📁${NC} ${filepath}/"
        local count
        count=$(find "$expanded" -maxdepth 1 -type f | wc -l)
        echo -e "  ${DIM}Directory with ${count} file(s)${NC}"
        for f in "$expanded"/*; do
            [[ -f "$f" ]] && echo -e "  ${GREEN}├──${NC} $(basename "$f") ${DIM}($(wc -l < "$f") lines)${NC}"
        done
        FOUND=$((FOUND + 1))
    fi
}

show_missing() {
    local filepath="$1"
    local expanded="${filepath/#\~/$HOME}"
    if [[ ! -e "$expanded" ]]; then
        echo -e "${YELLOW}○${NC} ${filepath} ${DIM}(not found)${NC}"
    fi
}

# Recursively find Hyprland source'd files
find_hyprland_sources() {
    local config_file="$1"
    local base_dir
    base_dir="$(dirname "$config_file")"

    if [[ ! -f "$config_file" ]]; then
        return
    fi

    while IFS= read -r line; do
        # Match: source = ./path or source = /absolute/path or source = ~/path
        local source_path
        source_path=$(echo "$line" | sed -n 's/^source\s*=\\s*//p' | xargs || echo "")
        # Fallback if the sed matches but requires cleaning
        if [[ -z "$source_path" ]]; then
            source_path=$(echo "$line" | sed -E 's/^source\s*=\s*(.*)/\1/' | xargs || echo "")
        fi

        if [[ -z "$source_path" ]]; then
            continue
        fi

        # Resolve relative paths
        if [[ "$source_path" == ./* ]]; then
            source_path="${base_dir}/${source_path#./}"
        elif [[ "$source_path" == ~/* ]]; then
            source_path="${HOME}/${source_path#\~/}"
        elif [[ "$source_path" != /* ]]; then
            # Implicit relative path
            source_path="${base_dir}/${source_path}"
        fi

        # Handle glob patterns
        if [[ "$source_path" == *"*"* ]]; then
            for expanded_file in $source_path; do
                if [[ -f "$expanded_file" ]]; then
                    local is_auto=""
                    if head -3 "$expanded_file" | grep -qi 'auto-generated\|do not edit'; then
                        is_auto="⚠ Auto-generated"
                    fi
                    show_file "$expanded_file" "$is_auto"
                    find_hyprland_sources "$expanded_file"
                fi
            done
        elif [[ -f "$source_path" ]]; then
            local is_auto=""
            if head -3 "$source_path" | grep -qi 'auto-generated\|do not edit'; then
                is_auto="⚠ Auto-generated"
            fi
            show_file "$source_path" "$is_auto"
            find_hyprland_sources "$source_path"
        fi
    done < <(grep -E '^\s*source\s*=' "$config_file" 2>/dev/null || true)
}

# Recursively find Hyprland/Caelestia required Lua modules
find_hyprland_lua_sources() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        return
    fi

    # Extract required modules from lines like: require("module")
    local modules
    modules=$(grep -E 'require\s*\(\s*["'\''][^"'\'']+["'\'']\s*\)' "$config_file" 2>/dev/null | sed -E 's/.*require\s*\(\s*["'\'']([^"'\'']+)["'\'']\s*\).*/\1/' || true)

    for mod in $modules; do
        # Replace . with /
        local rel_path
        rel_path=$(echo "$mod" | tr '.' '/')

        local found_file=""
        if [[ -f "$HOME/.config/hypr/${rel_path}.lua" ]]; then
            found_file="$HOME/.config/hypr/${rel_path}.lua"
        elif [[ -f "$HOME/.config/caelestia/${rel_path}.lua" ]]; then
            found_file="$HOME/.config/caelestia/${rel_path}.lua"
        fi

        if [[ -n "$found_file" ]]; then
            if [[ ! " ${VISITED_LUA_FILES[*]:-} " =~ " ${found_file} " ]]; then
                VISITED_LUA_FILES+=("$found_file")
                local label=""
                if [[ "$found_file" == *"/caelestia/"* ]]; then
                    label="Caelestia override module"
                elif head -3 "$found_file" | grep -qi 'generated by'; then
                    label="⚠ Auto-generated file"
                fi
                show_file "$found_file" "$label"
                find_hyprland_lua_sources "$found_file"
            fi
        fi
    done
}

echo -e "${CYAN}Finding config files for: ${COMPONENT}${NC}"
echo ""

case "$COMPONENT" in
    hyprland|hypr)
        if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
            show_file "~/.config/hypr/hyprland.lua" "Primary Hyprland config (Lua)"
            echo ""
            echo -e "${CYAN}Required files:${NC}"
            declare -g -a VISITED_LUA_FILES=()
            VISITED_LUA_FILES+=("$HOME/.config/hypr/hyprland.lua")
            find_hyprland_lua_sources "$HOME/.config/hypr/hyprland.lua"
        else
            show_file "~/.config/hypr/hyprland.conf" "Primary Hyprland config (Legacy)"
            echo ""
            echo -e "${CYAN}Source'd files:${NC}"
            find_hyprland_sources "$HOME/.config/hypr/hyprland.conf"
        fi
        echo ""
        echo -e "${CYAN}Other files in ~/.config/hypr/:${NC}"
        for f in "$HOME"/.config/hypr/*.conf "$HOME"/.config/hypr/*.lua "$HOME"/.config/hypr/*.sh; do
            [[ -f "$f" ]] || continue
            local_name=$(basename "$f")
            # Skip the main configs and backup files
            if [[ "$local_name" != "hyprland.conf" ]] && [[ "$local_name" != "hyprland.lua" ]] && [[ "$local_name" != *.backup.* ]] && [[ "$local_name" != *.bak ]]; then
                if [[ ! " ${VISITED_LUA_FILES[*]:-} " =~ " ${f} " ]]; then
                    show_file "$f"
                fi
            fi
        done
        # Check for plugins
        if [[ -d "$HOME/.config/hypr/plugins" ]]; then
            show_file "~/.config/hypr/plugins"
        fi
        ;;

    waybar)
        show_file "~/.config/waybar/config.jsonc"
        show_file "~/.config/waybar/config"
        show_file "~/.config/waybar/style.css"
        show_missing "~/.config/waybar/config.jsonc"
        ;;

    kitty)
        show_file "~/.config/kitty/kitty.conf"
        show_file "~/.config/kitty/current-theme.conf"
        # Kitty can include other files
        if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
            for inc in $(grep -E '^include\s+' "$HOME/.config/kitty/kitty.conf" 2>/dev/null | awk '{print $2}'); do
                if [[ "$inc" == ./* ]]; then
                    show_file "$HOME/.config/kitty/${inc#./}"
                else
                    show_file "$HOME/.config/kitty/$inc"
                fi
            done
        fi
        show_missing "~/.config/kitty/kitty.conf"
        ;;

    foot)
        show_file "~/.config/foot/foot.ini"
        show_missing "~/.config/foot/foot.ini"
        ;;

    ghostty)
        show_file "~/.config/ghostty/config"
        show_missing "~/.config/ghostty/config"
        ;;

    wezterm)
        show_file "~/.config/wezterm/wezterm.lua"
        show_missing "~/.config/wezterm/wezterm.lua"
        ;;

    alacritty)
        show_file "~/.config/alacritty/alacritty.toml"
        show_file "~/.config/alacritty/alacritty.yml"
        show_missing "~/.config/alacritty/alacritty.toml"
        ;;

    rofi)
        show_file "~/.config/rofi/config.rasi"
        if [[ -d "$HOME/.config/rofi/themes" ]]; then
            show_file "~/.config/rofi/themes"
        fi
        show_missing "~/.config/rofi/config.rasi"
        ;;

    wofi)
        show_file "~/.config/wofi/config"
        show_file "~/.config/wofi/style.css"
        show_missing "~/.config/wofi/config"
        ;;

    hyprlock)
        show_file "~/.config/hypr/hyprlock.conf"
        show_missing "~/.config/hypr/hyprlock.conf"
        ;;

    hypridle)
        show_file "~/.config/hypr/hypridle.conf"
        show_missing "~/.config/hypr/hypridle.conf"
        ;;

    hyprpaper)
        show_file "~/.config/hypr/hyprpaper.conf"
        show_missing "~/.config/hypr/hyprpaper.conf"
        ;;

    dunst)
        show_file "~/.config/dunst/dunstrc"
        show_missing "~/.config/dunst/dunstrc"
        ;;

    mako)
        show_file "~/.config/mako/config"
        show_missing "~/.config/mako/config"
        ;;

    wlogout)
        show_file "~/.config/wlogout/layout"
        show_file "~/.config/wlogout/style.css"
        show_missing "~/.config/wlogout/layout"
        ;;

    gtk)
        show_file "~/.config/gtk-3.0/settings.ini"
        show_file "~/.config/gtk-4.0/settings.ini"
        show_file "~/.gtkrc-2.0"
        ;;

    qt)
        show_file "~/.config/qt5ct/qt5ct.conf"
        show_file "~/.config/qt6ct/qt6ct.conf"
        ;;

    pipewire)
        show_file "~/.config/pipewire"
        show_file "/etc/pipewire"
        ;;

    wireplumber)
        show_file "~/.config/wireplumber"
        show_file "/etc/wireplumber"
        ;;

    sddm)
        echo -e "${YELLOW}Note: SDDM configs require root to view${NC}"
        show_file "/etc/sddm.conf"
        if [[ -d "/etc/sddm.conf.d" ]]; then
            show_file "/etc/sddm.conf.d"
        fi
        ;;

    greetd)
        echo -e "${YELLOW}Note: greetd configs require root to view${NC}"
        show_file "/etc/greetd/config.toml"
        ;;

    caelestia)
        show_file "~/.config/caelestia/shell.json" "Shell Layout Config"
        show_file "~/.config/caelestia/hypr-vars.lua" "User Variable Overrides"
        show_file "~/.config/caelestia/hypr-user.lua" "User Custom Rules"
        if [[ -d "$HOME/.config/caelestia/monitors" ]]; then
            show_file "~/.config/caelestia/monitors" "Monitors config directory"
        fi
        echo ""
        echo -e "${CYAN}Caelestia shell status:${NC}"
        echo -e "  $(pgrep -f "qs -c caelestia" &>/dev/null && echo 'active' || echo 'inactive')"
        ;;

    *)
        echo -e "${YELLOW}Unknown component: ${COMPONENT}${NC}"
        echo ""
        echo "Try one of: hyprland, waybar, kitty, foot, ghostty, wezterm,"
        echo "alacritty, rofi, wofi, hyprlock, hypridle, hyprpaper, dunst,"
        echo "mako, wlogout, gtk, qt, pipewire, wireplumber, sddm, greetd, caelestia"
        exit 1
        ;;
esac

echo ""
if [[ $FOUND -eq 0 ]]; then
    echo -e "${YELLOW}No config files found for ${COMPONENT}${NC}"
    exit 2
else
    echo -e "${DIM}Found ${FOUND} config file(s)${NC}"
fi

exit 0
