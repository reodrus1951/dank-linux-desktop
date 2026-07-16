#!/usr/bin/env bash
# detect.sh — Detect full system configuration for a Hyprland/Caelestia desktop
# Usage: ./detect.sh [--quiet] [--json]
#
# Detects: OS, kernel, GPU, monitors, desktop environment, audio, themes,
#          installed components, systemd services, and configuration paths.
#
# Exit codes:
#   0 — Detection completed successfully
#   1 — Critical detection failure (not Arch-based or not Hyprland)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ━━━ Options ━━━
QUIET=false
JSON_OUTPUT=false

for arg in "$@"; do
    case "$arg" in
        --quiet)  QUIET=true ;;
        --json)   JSON_OUTPUT=true ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--quiet] [--json]"
            echo ""
            echo "Detect full system configuration for a Hyprland/Caelestia desktop."
            echo ""
            echo "Options:"
            echo "  --quiet   Minimal output (key=value format)"
            echo "  --json    Output as JSON"
            echo "  --help    Show this help message"
            exit 0
            ;;
    esac
done

# ━━━ Colors (suppressed in quiet/json mode) ━━━
if [[ "$QUIET" == "false" ]] && [[ "$JSON_OUTPUT" == "false" ]]; then
    BOLD='\033[1m'
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    DIM='\033[2m'
    NC='\033[0m'
else
    BOLD='' CYAN='' GREEN='' YELLOW='' DIM='' NC=''
fi

header() {
    [[ "$QUIET" == "true" ]] || [[ "$JSON_OUTPUT" == "true" ]] && return
    echo -e "\n${BOLD}${CYAN}━━━━━━ $* ━━━━━━${NC}"
}

item() {
    local key="$1" value="$2"
    if [[ "$QUIET" == "true" ]]; then
        echo "${key}=${value}"
    elif [[ "$JSON_OUTPUT" == "false" ]]; then
        printf "  ${GREEN}%-24s${NC} %s\n" "$key:" "$value"
    fi
}

# ━━━ Collect Data ━━━
declare -A DATA

# OS
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    DATA[os_name]="${PRETTY_NAME:-unknown}"
    DATA[os_id]="${ID:-unknown}"
    DATA[os_id_like]="${ID_LIKE:-$ID}"
else
    DATA[os_name]="unknown"
    DATA[os_id]="unknown"
    DATA[os_id_like]="unknown"
fi

# Kernel
DATA[kernel]="$(uname -r 2>/dev/null || echo 'unknown')"
DATA[kernel_arch]="$(uname -m 2>/dev/null || echo 'unknown')"

# Session
DATA[session_type]="${XDG_SESSION_TYPE:-unknown}"
DATA[current_desktop]="${XDG_CURRENT_DESKTOP:-unknown}"
DATA[wayland_display]="${WAYLAND_DISPLAY:-unset}"

# Hyprland
if command -v hyprctl &>/dev/null; then
    HYPR_VER=$(hyprctl version 2>/dev/null | head -1 | sed 's/Hyprland //' | awk '{print $1}' || echo "unknown")
    DATA[hyprland_version]="$HYPR_VER"
    DATA[hyprland_running]="true"
else
    DATA[hyprland_version]="not installed"
    DATA[hyprland_running]="false"
fi

# Caelestia
if command -v caelestia &>/dev/null; then
    DATA[caelestia_installed]="true"
    DATA[caelestia_active]="$(pgrep -f "qs -c caelestia" &>/dev/null && echo 'active' || echo 'inactive')"
else
    DATA[caelestia_installed]="false"
    DATA[caelestia_active]="n/a"
fi

# Hyprland Config Type
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    DATA[hyprland_config_type]="lua"
elif [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    DATA[hyprland_config_type]="legacy-conf"
else
    DATA[hyprland_config_type]="unknown"
fi

# Quickshell
DATA[quickshell_installed]="$(command -v quickshell &>/dev/null && echo 'true' || echo 'false')"

# GPU
GPU_LINE=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 || echo "")
if [[ -n "$GPU_LINE" ]]; then
    DATA[gpu_full]="$GPU_LINE"
    if [[ "$GPU_LINE" == *"NVIDIA"* ]]; then
        DATA[gpu_vendor]="nvidia"
        DATA[gpu_model]=$(echo "$GPU_LINE" | sed 's/.*\[//' | sed 's/\].*//')
        DATA[nvidia_driver]="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'unknown')"
    elif [[ "$GPU_LINE" == *"AMD"* ]] || [[ "$GPU_LINE" == *"ATI"* ]]; then
        DATA[gpu_vendor]="amd"
        DATA[gpu_model]=$(echo "$GPU_LINE" | sed 's/.*\[//' | sed 's/\].*//')
        DATA[nvidia_driver]="n/a"
    elif [[ "$GPU_LINE" == *"Intel"* ]]; then
        DATA[gpu_vendor]="intel"
        DATA[gpu_model]=$(echo "$GPU_LINE" | sed 's/.*\[//' | sed 's/\].*//')
        DATA[nvidia_driver]="n/a"
    else
        DATA[gpu_vendor]="unknown"
        DATA[gpu_model]="$GPU_LINE"
        DATA[nvidia_driver]="n/a"
    fi
else
    DATA[gpu_vendor]="unknown"
    DATA[gpu_model]="unknown"
    DATA[gpu_full]="not detected"
    DATA[nvidia_driver]="n/a"
fi

# Monitors
if command -v hyprctl &>/dev/null; then
    MONITOR_COUNT=$(hyprctl monitors 2>/dev/null | grep -c '^Monitor ' || echo "0")
    MONITOR_LIST=$(hyprctl monitors 2>/dev/null | grep '^Monitor ' | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    DATA[monitor_count]="$MONITOR_COUNT"
    DATA[monitor_list]="$MONITOR_LIST"
else
    DATA[monitor_count]="unknown"
    DATA[monitor_list]="unknown"
fi

# Audio
DATA[pipewire_active]="$(systemctl --user is-active pipewire.service 2>/dev/null || echo 'inactive')"
DATA[wireplumber_active]="$(systemctl --user is-active wireplumber.service 2>/dev/null || echo 'inactive')"

# Package managers
DATA[pacman]="$(command -v pacman &>/dev/null && echo 'installed' || echo 'missing')"
DATA[paru]="$(command -v paru &>/dev/null && echo 'installed' || echo 'missing')"
DATA[yay]="$(command -v yay &>/dev/null && echo 'installed' || echo 'missing')"

# Terminals
TERMINALS=()
command -v kitty      &>/dev/null && TERMINALS+=("kitty")
command -v foot       &>/dev/null && TERMINALS+=("foot")
command -v ghostty    &>/dev/null && TERMINALS+=("ghostty")
command -v wezterm    &>/dev/null && TERMINALS+=("wezterm")
command -v alacritty  &>/dev/null && TERMINALS+=("alacritty")
DATA[terminals]="$(IFS=','; echo "${TERMINALS[*]:-none}")"

# Launcher
LAUNCHERS=()
command -v rofi &>/dev/null && LAUNCHERS+=("rofi")
command -v wofi &>/dev/null && LAUNCHERS+=("wofi")
[[ "${DATA[caelestia_installed]:-}" == "true" ]] && LAUNCHERS+=("caelestia-spot")
DATA[launchers]="$(IFS=','; echo "${LAUNCHERS[*]:-none}")"

# Notification daemon
NOTIFIERS=()
command -v dunst &>/dev/null && NOTIFIERS+=("dunst")
command -v mako  &>/dev/null && NOTIFIERS+=("mako")
[[ "${DATA[caelestia_installed]:-}" == "true" ]] && NOTIFIERS+=("caelestia-notifications")
DATA[notification_daemons]="$(IFS=','; echo "${NOTIFIERS[*]:-none}")"

# Wallpaper daemon
WALLPAPER=()
command -v hyprpaper &>/dev/null && WALLPAPER+=("hyprpaper")
command -v swww      &>/dev/null && WALLPAPER+=("swww")
command -v swaybg    &>/dev/null && WALLPAPER+=("swaybg")
DATA[wallpaper_daemons]="$(IFS=','; echo "${WALLPAPER[*]:-none}")"

# Lock / Idle
DATA[hyprlock]="$(command -v hyprlock &>/dev/null && echo 'installed' || echo 'missing')"
DATA[hypridle]="$(command -v hypridle &>/dev/null && echo 'installed' || echo 'missing')"

# Waybar
DATA[waybar]="$(command -v waybar &>/dev/null && echo 'installed' || echo 'missing')"

# Wlogout
DATA[wlogout]="$(command -v wlogout &>/dev/null && echo 'installed' || echo 'missing')"

# Display manager
DM="none"
command -v sddm   &>/dev/null && DM="sddm"
command -v greetd  &>/dev/null && DM="${DM:+$DM,}greetd"
[[ "$DM" == "none" ]] || true
DATA[display_manager]="$DM"

# Themes
DATA[gtk_theme]="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo 'unknown')"
DATA[icon_theme]="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo 'unknown')"
DATA[cursor_theme]="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || echo 'unknown')"
DATA[font]="$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'" || echo 'unknown')"

# Network
DATA[networkmanager]="$(systemctl is-active NetworkManager.service 2>/dev/null || echo 'inactive')"

# ━━━ Output ━━━

if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "{"
    FIRST=true
    for key in $(echo "${!DATA[@]}" | tr ' ' '\n' | sort); do
        if [[ "$FIRST" == "true" ]]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  "%s": "%s"' "$key" "${DATA[$key]}"
    done
    echo ""
    echo "}"
    exit 0
fi

header "Operating System"
item "OS"          "${DATA[os_name]}"
item "ID"          "${DATA[os_id]}"
item "Base"        "${DATA[os_id_like]}"
item "Kernel"      "${DATA[kernel]}"
item "Architecture" "${DATA[kernel_arch]}"

header "Desktop Environment"
item "Session Type"   "${DATA[session_type]}"
item "Desktop"        "${DATA[current_desktop]}"
item "Wayland Display" "${DATA[wayland_display]}"
item "Hyprland"       "${DATA[hyprland_version]} (${DATA[hyprland_config_type]})"
item "Caelestia"      "${DATA[caelestia_installed]} (${DATA[caelestia_active]})"
item "Quickshell"     "${DATA[quickshell_installed]}"

header "GPU"
item "Vendor"         "${DATA[gpu_vendor]}"
item "Model"          "${DATA[gpu_model]}"
[[ "${DATA[gpu_vendor]}" == "nvidia" ]] && item "NVIDIA Driver" "${DATA[nvidia_driver]}"

header "Monitors"
item "Count"          "${DATA[monitor_count]}"
item "Outputs"        "${DATA[monitor_list]}"

header "Audio"
item "PipeWire"       "${DATA[pipewire_active]}"
item "WirePlumber"    "${DATA[wireplumber_active]}"

header "Installed Components"
item "Terminals"      "${DATA[terminals]}"
item "Launchers"      "${DATA[launchers]}"
item "Notifications"  "${DATA[notification_daemons]}"
item "Wallpaper"      "${DATA[wallpaper_daemons]}"
item "Waybar"         "${DATA[waybar]}"
item "Hyprlock"       "${DATA[hyprlock]}"
item "Hypridle"       "${DATA[hypridle]}"
item "Wlogout"        "${DATA[wlogout]}"
item "Display Manager" "${DATA[display_manager]}"

header "Package Managers"
item "pacman"         "${DATA[pacman]}"
item "paru"           "${DATA[paru]}"
item "yay"            "${DATA[yay]}"

header "Themes"
item "GTK Theme"      "${DATA[gtk_theme]}"
item "Icon Theme"     "${DATA[icon_theme]}"
item "Cursor Theme"   "${DATA[cursor_theme]}"
item "Font"           "${DATA[font]}"

header "Network"
item "NetworkManager" "${DATA[networkmanager]}"

if [[ "$QUIET" == "false" ]]; then
    echo ""
fi

exit 0
