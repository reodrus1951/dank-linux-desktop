#!/usr/bin/env bash
# collect-system-info.sh — Collect comprehensive system info for bug reports
# Usage: ./collect-system-info.sh [output-file]
#
# Generates a detailed system report suitable for filing bug reports or
# sharing with support. Collects hardware, software, config, and log info.
#
# Exit codes:
#   0 — Report generated successfully
#   1 — Failed to generate report

set -euo pipefail

OUTPUT="${1:-/tmp/system-info-$(date +%Y%m%d_%H%M%S).txt}"

section() {
    echo ""
    echo "============================================================"
    echo "  $*"
    echo "============================================================"
}

run_safe() {
    local desc="$1"
    shift
    echo "── $desc ──"
    if eval "$@" 2>&1; then
        true
    else
        echo "(command failed or not available)"
    fi
    echo ""
}

{
    echo "System Information Report"
    echo "Generated: $(date -Iseconds)"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"

    section "OPERATING SYSTEM"
    run_safe "os-release" "cat /etc/os-release"
    run_safe "Kernel" "uname -a"
    run_safe "Kernel cmdline" "cat /proc/cmdline"

    section "HARDWARE"
    run_safe "CPU" "lscpu | head -20"
    run_safe "Memory" "free -h"
    run_safe "GPU (lspci)" "lspci | grep -iE 'vga|3d|display'"
    run_safe "GPU (lspci detail)" "lspci -v -s \$(lspci | grep -iE 'vga|3d|display' | head -1 | awk '{print \$1}') 2>/dev/null | head -30"
    run_safe "Block devices" "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT"
    run_safe "USB devices" "lsusb 2>/dev/null | head -20"

    section "NVIDIA GPU (if applicable)"
    run_safe "nvidia-smi" "nvidia-smi 2>/dev/null"
    run_safe "NVIDIA kernel module" "cat /proc/driver/nvidia/version 2>/dev/null"
    run_safe "NVIDIA packages" "pacman -Qs nvidia 2>/dev/null"

    section "DISPLAY / WAYLAND"
    run_safe "Session type" "echo XDG_SESSION_TYPE=\$XDG_SESSION_TYPE"
    run_safe "Current desktop" "echo XDG_CURRENT_DESKTOP=\${XDG_CURRENT_DESKTOP:-unset}"
    run_safe "Wayland display" "echo WAYLAND_DISPLAY=\${WAYLAND_DISPLAY:-unset}"
    run_safe "Hyprland instance" "echo HYPRLAND_INSTANCE_SIGNATURE=\${HYPRLAND_INSTANCE_SIGNATURE:-unset}"

    section "HYPRLAND"
    run_safe "Version" "hyprctl version 2>/dev/null"
    run_safe "Monitors" "hyprctl monitors 2>/dev/null"
    run_safe "Active window" "hyprctl activewindow 2>/dev/null"
    run_safe "Workspaces" "hyprctl workspaces 2>/dev/null"
    run_safe "Plugins" "hyprctl plugin list 2>/dev/null"
    run_safe "System info" "hyprctl systeminfo 2>/dev/null"

    section "CAELESTIA SHELL"
    run_safe "Caelestia CLI" "caelestia -v 2>/dev/null"
    run_safe "Caelestia process" "pgrep -af 'qs -c caelestia' 2>/dev/null"
    run_safe "Quickshell" "which qs 2>/dev/null"

    section "AUDIO"
    run_safe "PipeWire service" "systemctl --user status pipewire.service 2>/dev/null"
    run_safe "WirePlumber service" "systemctl --user status wireplumber.service 2>/dev/null"
    run_safe "PipeWire info" "pactl info 2>/dev/null"
    run_safe "Audio sinks" "pactl list sinks short 2>/dev/null"
    run_safe "Audio sources" "pactl list sources short 2>/dev/null"
    run_safe "WirePlumber status" "wpctl status 2>/dev/null | head -40"

    section "NETWORK"
    run_safe "NetworkManager" "systemctl status NetworkManager.service 2>/dev/null | head -10"
    run_safe "Interfaces" "ip -br addr 2>/dev/null"
    run_safe "DNS" "cat /etc/resolv.conf 2>/dev/null"

    section "SYSTEMD USER SERVICES"
    run_safe "Running services" "systemctl --user list-units --type=service --state=running --no-pager --plain"
    run_safe "Failed services" "systemctl --user list-units --type=service --state=failed --no-pager --plain"

    section "SYSTEMD SYSTEM SERVICES"
    run_safe "Display manager" "systemctl status display-manager.service 2>/dev/null | head -10"
    run_safe "SDDM" "systemctl is-active sddm.service 2>/dev/null"
    run_safe "greetd" "systemctl is-active greetd.service 2>/dev/null"

    section "PACKAGES"
    run_safe "Package manager" "pacman --version | head -2"
    run_safe "Repos" "grep -E '^\[[a-zA-Z0-9_-]+\]' /etc/pacman.conf"
    run_safe "AUR helpers" "which paru yay 2>/dev/null"
    run_safe "Explicitly installed (count)" "pacman -Qe | wc -l"
    run_safe "Hyprland packages" "pacman -Qs hypr 2>/dev/null"
    run_safe "Desktop packages" "pacman -Qs 'waybar\|kitty\|rofi\|wofi\|dunst\|mako' 2>/dev/null | head -30"

    section "THEMES"
    run_safe "GTK theme" "gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null"
    run_safe "Icon theme" "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null"
    run_safe "Cursor theme" "gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null"
    run_safe "Font" "gsettings get org.gnome.desktop.interface font-name 2>/dev/null"
    run_safe "Color scheme" "gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null"

    section "CONFIGURATION FILES"
    run_safe "Hyprland Lua config" "head -30 ~/.config/hypr/hyprland.lua 2>/dev/null"
    run_safe "Caelestia configs" "ls -la ~/.config/caelestia/ 2>/dev/null"
    run_safe "Caelestia shell.json" "cat ~/.config/caelestia/shell.json 2>/dev/null"
    run_safe "User vars" "cat ~/.config/caelestia/hypr-vars.lua 2>/dev/null"
    run_safe "User config" "cat ~/.config/caelestia/hypr-user.lua 2>/dev/null"

    section "RECENT JOURNAL ERRORS"
    run_safe "Hyprland errors (last 20)" "journalctl --user -p err -n 20 --no-pager 2>/dev/null"
    run_safe "GPU kernel errors" "journalctl -b -k -p err | grep -iE 'nvidia|amdgpu|i915|drm' | tail -10 2>/dev/null"
    run_safe "Caelestia shell log" "caelestia shell -l 2>/dev/null | tail -20"

    section "ENVIRONMENT"
    run_safe "Relevant env vars" "env | grep -iE 'XDG|WAYLAND|HYPR|QT|GTK|CURSOR|DISPLAY|NVIDIA|LIBVA|GBM|MOZ|ELECTRON' | sort"

} > "$OUTPUT" 2>&1

echo "System info collected: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | awk '{print $1}')"
exit 0
