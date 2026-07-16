#!/usr/bin/env bash
# doctor.sh — Diagnose system health issues for a Hyprland/Caelestia desktop
# Usage: ./doctor.sh [--component <name>] [--fix] [--json]
#
# Checks for:
#   - Broken configs (missing files, syntax errors)
#   - Missing packages (required and optional)
#   - Failed systemd services
#   - Hyprland errors
#   - Waybar crashes
#   - Permission issues
#   - GPU driver issues
#   - Session type and display variables
#   - Journal errors
#
# Exit codes:
#   0 — No issues found
#   1 — Issues found (see output)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

ISSUES=0
WARNINGS=0
COMPONENT_FILTER=""
FIX_MODE=false

for arg in "$@"; do
    case "$arg" in
        --component)
            shift
            COMPONENT_FILTER="${1:-}"
            shift || true
            ;;
        --fix)
            FIX_MODE=true
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--component <name>] [--fix]"
            echo ""
            echo "Diagnose system health issues."
            echo ""
            echo "Options:"
            echo "  --component <name>  Check only a specific component"
            echo "                      (hyprland, waybar, audio, gpu, services, configs)"
            echo "  --fix               Attempt to fix found issues"
            echo "  --help              Show this help"
            exit 0
            ;;
    esac
done

check_ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
check_fail() { echo -e "  ${RED}✗${NC} $*"; ISSUES=$((ISSUES + 1)); }
check_warn() { echo -e "  ${YELLOW}⚠${NC} $*"; WARNINGS=$((WARNINGS + 1)); }
check_info() { echo -e "  ${DIM}$*${NC}"; }
section()    { echo -e "\n${BOLD}${CYAN}━━━━━━ $* ━━━━━━${NC}"; }

should_check() {
    [[ -z "$COMPONENT_FILTER" ]] || [[ "$COMPONENT_FILTER" == "$1" ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Session & Environment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "session"; then
    section "Session & Environment"

    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        check_ok "Session type: wayland"
    else
        check_fail "Session type is '${XDG_SESSION_TYPE:-unset}' (expected: wayland)"
    fi

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        check_ok "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
    else
        check_fail "WAYLAND_DISPLAY is not set"
    fi

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        check_ok "HYPRLAND_INSTANCE_SIGNATURE is set"
    else
        check_warn "HYPRLAND_INSTANCE_SIGNATURE is not set (are you in a Hyprland session?)"
    fi

    if [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]]; then
        check_ok "XDG_CURRENT_DESKTOP: Hyprland"
    else
        check_warn "XDG_CURRENT_DESKTOP: ${XDG_CURRENT_DESKTOP:-unset}"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Hyprland
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "hyprland"; then
    section "Hyprland"

    if command -v hyprctl &>/dev/null; then
        check_ok "hyprctl is available"

        # Check if Hyprland is responsive
        if hyprctl version &>/dev/null; then
            HYPR_VER=$(hyprctl version 2>/dev/null | head -1 || echo "unknown")
            check_ok "Hyprland is responsive: $HYPR_VER"
        else
            check_fail "Hyprland is not responding to hyprctl"
        fi

        # Check for config errors
        HYPR_ERRORS=$(hyprctl systeminfo 2>/dev/null | grep -i 'error\|warning' || true)
        if [[ -n "$HYPR_ERRORS" ]]; then
            check_warn "Hyprland reports issues:"
            echo "$HYPR_ERRORS" | while read -r line; do check_info "  $line"; done
        else
            check_ok "No errors reported by hyprctl"
        fi

        # Check monitors
        MON_COUNT=$(hyprctl monitors 2>/dev/null | grep -c '^Monitor ' || true)
        if [[ "$MON_COUNT" -gt 0 ]]; then
            check_ok "$MON_COUNT monitor(s) active"
        else
            check_fail "No active monitors detected"
        fi
    else
        check_fail "hyprctl is not installed"
    fi

    # Helper to validate all imported Lua modules
    doctor_lua_module_syntax() {
        local config_file="$1"
        if [[ ! -f "$config_file" ]]; then
            return 0
        fi

        if luac -p "$config_file" &>/dev/null; then
            check_ok "Syntax OK: $(basename "$config_file")"
        else
            check_fail "Syntax Error in $(basename "$config_file")"
            local lua_err
            lua_err=$(luac -p "$config_file" 2>&1 || true)
            [[ -n "$lua_err" ]] && check_info "  $lua_err"
        fi

        local modules
        modules=$(grep -E 'require\s*\(\s*["'\''][^"'\'']+["'\'']\s*\)' "$config_file" 2>/dev/null | sed -E 's/.*require\s*\(\s*["'\'']([^"'\'']+)["'\'']\s*\).*/\1/' || true)

        for mod in $modules; do
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
                    doctor_lua_module_syntax "$found_file"
                fi
            fi
        done
    }

    # Config files
    if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
        check_ok "hyprland.lua exists"
        declare -a VISITED_LUA_FILES=()
        VISITED_LUA_FILES+=("$HOME/.config/hypr/hyprland.lua")
        doctor_lua_module_syntax "$HOME/.config/hypr/hyprland.lua"
    elif [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        check_ok "hyprland.conf exists"

        # Check braces
        OB=$(grep -c '{' "$HOME/.config/hypr/hyprland.conf" || true)
        CB=$(grep -c '}' "$HOME/.config/hypr/hyprland.conf" || true)
        if [[ "$OB" -ne "$CB" ]]; then
            check_fail "Unmatched braces in hyprland.conf (open: $OB, close: $CB)"
        fi

        # Check source'd files
        HYPR_DIR="$HOME/.config/hypr"
        while IFS= read -r line; do
            sp=$(echo "$line" | sed -n 's/^source\s*=\s*//p' | xargs || echo "")
            if [[ -z "$sp" ]]; then
                sp=$(echo "$line" | sed -E 's/^source\s*=\s*(.*)/\1/' | xargs || echo "")
            fi
            [[ -z "$sp" ]] && continue
            # Resolve relative paths from hyprland.conf directory
            if [[ "$sp" == ./* ]]; then
                sp="${HYPR_DIR}/${sp#./}"
            elif [[ "$sp" == ~/* ]]; then
                sp="${HOME}/${sp#\~/}"
            elif [[ "$sp" != /* ]]; then
                # Relative path without ./
                sp="${HYPR_DIR}/${sp}"
            fi
            if [[ "$sp" != *"*"* ]] && [[ ! -f "$sp" ]]; then
                check_fail "Source'd file missing: $sp"
            fi
        done < <(grep -E '^\s*source\s*=' "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true)
    else
        check_fail "No Hyprland config file (hyprland.lua or hyprland.conf) found"
    fi

    # Caelestia directory
    if [[ -d "$HOME/.config/caelestia" ]]; then
        check_ok "Caelestia config directory exists"
        shell_json="$HOME/.config/caelestia/shell.json"
        if [[ -f "$shell_json" ]]; then
            if python3 -c "import json; json.load(open('$shell_json'))" &>/dev/null; then
                check_ok "shell.json syntax is valid"
            else
                check_fail "shell.json syntax error"
            fi
        else
            check_warn "shell.json not found"
        fi
    else
        check_warn "Caelestia config directory not found"
    fi

    # Journal errors
    HYPR_JOURNAL=$(journalctl --user -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -ic hypr || true)
    if [[ "$HYPR_JOURNAL" -gt 0 ]]; then
        check_warn "$HYPR_JOURNAL Hyprland-related error(s) in journal (last hour)"
    else
        check_ok "No Hyprland errors in journal (last hour)"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Waybar
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "waybar"; then
    section "Waybar"

    if command -v waybar &>/dev/null; then
        check_ok "Waybar is installed"

        if pgrep -x waybar &>/dev/null; then
            check_ok "Waybar is running (PID: $(pgrep -x waybar | head -1))"
        elif pgrep -f "qs -c caelestia" &>/dev/null; then
            check_ok "Waybar is NOT running (Caelestia shell is active)"
        else
            check_fail "Waybar is NOT running"

            if [[ "$FIX_MODE" == "true" ]]; then
                check_info "Attempting to start Waybar..."
                nohup waybar &>/dev/null &
                disown
                sleep 2
                if pgrep -x waybar &>/dev/null; then
                    check_ok "Waybar started successfully"
                    ISSUES=$((ISSUES - 1))
                else
                    check_fail "Could not start Waybar"
                fi
            fi
        fi
    else
        check_warn "Waybar is not installed"
    fi

    # Config validation
    for cfg in "$HOME/.config/waybar/config.jsonc" "$HOME/.config/waybar/config"; do
        if [[ -f "$cfg" ]]; then
            check_ok "Config exists: $(basename "$cfg")"
            if python3 -c "import sys, re, json; content = open('$cfg').read(); content = re.sub(r'//.*', '', content); content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL); content = re.sub(r',\s*([\]}])', r'\1', content); json.loads(content)" 2>/dev/null; then
                check_ok "JSON/JSONC syntax valid"
            else
                check_fail "JSON syntax error in $(basename "$cfg")"
            fi
            break
        fi
    done
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Audio
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "audio"; then
    section "Audio (PipeWire)"

    if systemctl --user is-active pipewire.service &>/dev/null; then
        check_ok "PipeWire is active"
    else
        check_fail "PipeWire is NOT active"
        if [[ "$FIX_MODE" == "true" ]]; then
            check_info "Attempting to restart PipeWire..."
            systemctl --user restart pipewire.service 2>/dev/null || true
            sleep 1
            if systemctl --user is-active pipewire.service &>/dev/null; then
                check_ok "PipeWire restarted"
                ISSUES=$((ISSUES - 1))
            fi
        fi
    fi

    if systemctl --user is-active wireplumber.service &>/dev/null; then
        check_ok "WirePlumber is active"
    else
        check_fail "WirePlumber is NOT active"
        if [[ "$FIX_MODE" == "true" ]]; then
            systemctl --user restart wireplumber.service 2>/dev/null || true
            sleep 1
            if systemctl --user is-active wireplumber.service &>/dev/null; then
                check_ok "WirePlumber restarted"
                ISSUES=$((ISSUES - 1))
            fi
        fi
    fi

    # Check for audio sinks
    SINK_COUNT=$(pactl list sinks short 2>/dev/null | wc -l || true)
    if [[ "$SINK_COUNT" -gt 0 ]]; then
        check_ok "$SINK_COUNT audio sink(s) available"
    else
        check_warn "No audio sinks detected"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GPU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "gpu"; then
    section "GPU"

    GPU_LINE=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 || echo "")
    if [[ -n "$GPU_LINE" ]]; then
        check_ok "GPU detected: $GPU_LINE"
    else
        check_fail "No GPU detected by lspci"
    fi

    if [[ "$GPU_LINE" == *"NVIDIA"* ]]; then
        # NVIDIA checks
        if lsmod | grep -q nvidia; then
            check_ok "NVIDIA kernel module loaded"
        else
            check_fail "NVIDIA kernel module NOT loaded"
        fi

        if command -v nvidia-smi &>/dev/null; then
            if nvidia-smi &>/dev/null; then
                DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "unknown")
                check_ok "nvidia-smi working (driver: $DRIVER_VER)"
            else
                check_fail "nvidia-smi present but failing"
            fi
        else
            check_warn "nvidia-smi not found"
        fi

        # Check for common NVIDIA env vars
        if grep -qr 'LIBVA_DRIVER_NAME' "$HOME/.config/hypr/" 2>/dev/null; then
            check_ok "LIBVA_DRIVER_NAME configured"
        else
            check_warn "LIBVA_DRIVER_NAME not set in Hyprland config (may cause video decode issues)"
        fi
    fi

    # Check DRM kernel messages
    DRM_ERRORS=$(journalctl -b -k -p err 2>/dev/null | grep -iE 'nvidia|amdgpu|i915|drm' | tail -5 || true)
    if [[ -n "$DRM_ERRORS" ]]; then
        check_warn "GPU-related kernel errors found:"
        echo "$DRM_ERRORS" | while read -r line; do check_info "  $line"; done
    else
        check_ok "No GPU kernel errors this boot"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Systemd Services
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "services"; then
    section "Systemd Services"

    # User services
    FAILED_USER=$(systemctl --user list-units --type=service --state=failed --no-pager --plain 2>/dev/null | grep -c '.service' || true)
    if [[ "$FAILED_USER" -gt 0 ]]; then
        check_fail "$FAILED_USER failed user service(s):"
        systemctl --user list-units --type=service --state=failed --no-pager --plain 2>/dev/null | grep '.service' | while read -r line; do
            check_info "  $line"
        done
    else
        check_ok "No failed user services"
    fi

    # Key processes/services
    if pgrep -f "qs -c caelestia" &>/dev/null; then
        check_ok "Caelestia shell is active"
    else
        check_warn "Caelestia shell is not active"
    fi

    for svc in pipewire.service wireplumber.service; do
        if systemctl --user is-active "$svc" &>/dev/null; then
            check_ok "$svc is active"
        else
            check_warn "$svc is not active"
        fi
    done

    # System services
    if systemctl is-active NetworkManager.service &>/dev/null; then
        check_ok "NetworkManager is active"
    else
        check_warn "NetworkManager is not active"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Config Files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "configs"; then
    section "Configuration Files"

    CONFIGS=(
        "$HOME/.config/hypr/hyprland.lua:Hyprland Lua"
        "$HOME/.config/caelestia/shell.json:Caelestia layout"
        "$HOME/.config/caelestia/hypr-vars.lua:Caelestia vars"
        "$HOME/.config/caelestia/hypr-user.lua:Caelestia user config"
        "$HOME/.config/waybar/config.jsonc:Waybar config"
        "$HOME/.config/waybar/style.css:Waybar style"
    )

    for entry in "${CONFIGS[@]}"; do
        local_path="${entry%%:*}"
        local_desc="${entry##*:}"
        if [[ -f "$local_path" ]]; then
            # Check permissions
            if [[ -r "$local_path" ]]; then
                check_ok "$local_desc exists and is readable"
            else
                check_fail "$local_desc exists but is NOT readable"
            fi
        else
            check_warn "$local_desc not found: $local_path"
        fi
    done

    # Check for backup directories
    if [[ -d "$HOME/.config/hypr/.backups" ]]; then
        BACKUP_COUNT=$(find "$HOME/.config/hypr/.backups" -type f | wc -l)
        check_ok "Hyprland backups directory exists ($BACKUP_COUNT backups)"
    else
        check_warn "No Hyprland backup directory (run backup.sh to create)"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Packages
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

if should_check "packages"; then
    section "Required Packages"

    REQUIRED_PKGS=(hyprland waybar kitty)
    OPTIONAL_PKGS=(rofi wofi hyprlock hypridle hyprpaper mako dunst wlogout)

    for pkg in "${REQUIRED_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            check_ok "$pkg installed"
        else
            check_fail "$pkg NOT installed"
        fi
    done

    check_info ""
    check_info "Optional packages:"
    for pkg in "${OPTIONAL_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            check_ok "$pkg installed"
        else
            check_info "$pkg not installed (optional)"
        fi
    done
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${BOLD}━━━ Summary ━━━${NC}"
echo ""

if [[ $ISSUES -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ System is healthy — no issues found${NC}"
elif [[ $ISSUES -eq 0 ]]; then
    echo -e "${YELLOW}${BOLD}⚠ System is mostly healthy — ${WARNINGS} warning(s)${NC}"
else
    echo -e "${RED}${BOLD}✗ Found ${ISSUES} issue(s) and ${WARNINGS} warning(s)${NC}"
    if [[ "$FIX_MODE" == "false" ]]; then
        echo -e "${DIM}Run with --fix to attempt automatic repairs${NC}"
    fi
fi

echo ""
exit $(( ISSUES > 0 ? 1 : 0 ))
