#!/usr/bin/env bash
# validate.sh — Validate configuration syntax and reload component
# Usage: ./validate.sh <component> [--no-reload] [--auto-rollback]
#
# Validates the configuration for a component, optionally reloads it,
# and optionally rolls back on failure.
#
# Components: hyprland, waybar, kitty, foot, rofi, dunst, mako, hyprlock,
#             hypridle, hyprpaper, pipewire, wireplumber
#
# Exit codes:
#   0 — Validation passed
#   1 — Validation failed
#   2 — Component not recognized

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") <component> [--no-reload] [--auto-rollback]"
    echo ""
    echo "Validate configuration for a desktop component."
    echo ""
    echo "Options:"
    echo "  --no-reload      Validate syntax only, don't reload"
    echo "  --auto-rollback  Automatically restore backup if validation fails"
    echo ""
    echo "Components: hyprland, waybar, kitty, foot, rofi, dunst, mako,"
    echo "            hyprlock, hypridle, hyprpaper, pipewire, wireplumber"
    exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
fi

COMPONENT="$1"
shift || true

DO_RELOAD=true
AUTO_ROLLBACK=false

for arg in "$@"; do
    case "$arg" in
        --no-reload)     DO_RELOAD=false ;;
        --auto-rollback) AUTO_ROLLBACK=true ;;
    esac
done

VALIDATION_OK=true

validate_pass() {
    echo -e "  ${GREEN}✓${NC} $*"
}

validate_fail() {
    echo -e "  ${RED}✗${NC} $*"
    VALIDATION_OK=false
}

validate_warn() {
    echo -e "  ${YELLOW}⚠${NC} $*"
}

validate_info() {
    echo -e "  ${DIM}$*${NC}"
}

# ━━━ Hyprland Validation ━━━

# Find and validate all imported modules
validate_lua_module_syntax() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # Run luac check on the file itself
    if luac -p "$config_file" &>/dev/null; then
        validate_pass "Syntax OK: $(basename "$config_file")"
    else
        validate_fail "Syntax Error in $(basename "$config_file"):"
        local lua_err
        lua_err=$(luac -p "$config_file" 2>&1 || true)
        [[ -n "$lua_err" ]] && validate_info "$lua_err"
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
                validate_lua_module_syntax "$found_file"
            fi
        fi
    done
}

validate_hyprland() {
    local config_lua="$HOME/.config/hypr/hyprland.lua"
    local config_conf="$HOME/.config/hypr/hyprland.conf"

    echo -e "${CYAN}Validating Hyprland configuration...${NC}"

    if [[ -f "$config_lua" ]]; then
        validate_pass "Hyprland Lua config exists"
        declare -g -a VISITED_LUA_FILES=()
        VISITED_LUA_FILES+=("$config_lua")
        validate_lua_module_syntax "$config_lua"
    elif [[ -f "$config_conf" ]]; then
        validate_pass "Hyprland conf config exists"
        # Legacy brace validation
        local open_braces close_braces
        open_braces=$(grep -c '{' "$config_conf" 2>/dev/null || true)
        close_braces=$(grep -c '}' "$config_conf" 2>/dev/null || true)
        if [[ "$open_braces" -ne "$close_braces" ]]; then
            validate_fail "Unmatched braces in $config_conf (open: $open_braces, close: $close_braces)"
        else
            validate_pass "Brace matching OK ($open_braces pairs)"
        fi
    else
        validate_fail "No Hyprland configuration found"
        return 1
    fi

    # Reload and check for errors
    if [[ "$DO_RELOAD" == "true" ]] && [[ "$VALIDATION_OK" == "true" ]]; then
        echo ""
        echo -e "${CYAN}Reloading Hyprland...${NC}"
        local reload_output
        reload_output=$(hyprctl reload 2>&1) || true

        if echo "$reload_output" | grep -qi 'error\|fail\|invalid'; then
            validate_fail "Hyprland reload reported errors"
            validate_info "$reload_output"
        else
            validate_pass "Hyprland reload OK"
        fi

        # Check journal for recent errors (last 10 seconds)
        local recent_errors
        recent_errors=$(journalctl --user -p err --since "10 seconds ago" --no-pager 2>/dev/null | grep -i hypr | head -5 || true)
        if [[ -n "$recent_errors" ]]; then
            validate_warn "Recent errors in journal:"
            echo "$recent_errors" | while read -r line; do
                validate_info "  $line"
            done
        fi
    fi
}

# ━━━ Waybar Validation ━━━

validate_waybar() {
    echo -e "${CYAN}Validating Waybar configuration...${NC}"

    local config="$HOME/.config/waybar/config.jsonc"
    local config_plain="$HOME/.config/waybar/config"
    local style="$HOME/.config/waybar/style.css"

    # Determine which config file exists
    local active_config=""
    if [[ -f "$config" ]]; then
        active_config="$config"
    elif [[ -f "$config_plain" ]]; then
        active_config="$config_plain"
    else
        validate_fail "No Waybar config found (checked config.jsonc and config)"
        return 1
    fi
    validate_pass "Config exists: $(basename "$active_config")"

    # Try to validate JSON (strip comments and trailing commas first)
    if python3 -c "import sys, re, json; content = open('$active_config').read(); content = re.sub(r'//.*', '', content); content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL); content = re.sub(r',\s*([\]}])', r'\1', content); json.loads(content)" 2>/dev/null; then
        validate_pass "JSON/JSONC syntax valid"
    else
        validate_fail "JSON syntax error in $(basename "$active_config")"
        # Try to find the error
        local json_err
        json_err=$(python3 -c "import sys, re, json; content = open('$active_config').read(); content = re.sub(r'//.*', '', content); content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL); content = re.sub(r',\s*([\]}])', r'\1', content); json.loads(content)" 2>&1 || true)
        [[ -n "$json_err" ]] && validate_info "$json_err"
    fi

    # Check CSS exists
    if [[ -f "$style" ]]; then
        validate_pass "Style CSS exists"
    else
        validate_warn "style.css not found (Waybar will use defaults)"
    fi

    # Reload
    if [[ "$DO_RELOAD" == "true" ]] && [[ "$VALIDATION_OK" == "true" ]]; then
        echo ""
        echo -e "${CYAN}Restarting Waybar...${NC}"
        killall waybar 2>/dev/null || true
        sleep 0.5
        nohup waybar &>/dev/null &
        disown
        sleep 2
        if pgrep -x waybar &>/dev/null; then
            validate_pass "Waybar running (PID: $(pgrep -x waybar | head -1))"
        else
            validate_fail "Waybar failed to start"
        fi
    fi
}

# ━━━ Kitty Validation ━━━

validate_kitty() {
    echo -e "${CYAN}Validating Kitty configuration...${NC}"

    local config="$HOME/.config/kitty/kitty.conf"

    if [[ ! -f "$config" ]]; then
        validate_warn "kitty.conf not found (using defaults)"
        return 0
    fi
    validate_pass "Config exists"

    # Check for obvious issues (invalid key=value lines)
    local line_num=0
    local errors=0
    while IFS= read -r line; do
        ((line_num++))
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        # Skip include directives
        [[ "$line" =~ ^include[[:space:]] ]] && continue
        # Check valid format: key value (space separated, not = in kitty)
        if ! echo "$line" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*\s+'; then
            # Could be a section marker or other valid syntax, just warn
            ((errors++)) || true
        fi
    done < "$config"

    if [[ $errors -gt 5 ]]; then
        validate_warn "Found $errors potentially unusual lines in kitty.conf"
    else
        validate_pass "Config format looks valid"
    fi

    # Reload signal
    if [[ "$DO_RELOAD" == "true" ]]; then
        if pgrep -x kitty &>/dev/null; then
            pkill -USR1 kitty 2>/dev/null || true
            validate_pass "Reload signal sent to Kitty"
        else
            validate_info "Kitty is not running (no reload needed)"
        fi
    fi
}

# ━━━ Generic INI/TOML Validation ━━━

validate_ini_config() {
    local component="$1"
    local config="$2"

    echo -e "${CYAN}Validating ${component} configuration...${NC}"

    if [[ ! -f "$config" ]]; then
        validate_warn "Config not found: $config"
        return 0
    fi
    validate_pass "Config exists: $(basename "$config")"

    # Check for unmatched brackets/braces
    local ob cb
    ob=$(grep -c '\[' "$config" 2>/dev/null || true)
    cb=$(grep -c '\]' "$config" 2>/dev/null || true)
    if [[ "$ob" -ne "$cb" ]]; then
        validate_fail "Unmatched brackets (open: $ob, close: $cb)"
    else
        validate_pass "Bracket matching OK"
    fi
}

# ━━━ Hyprland-Adjacent Config Validation ━━━

validate_hypr_config() {
    local component="$1"
    local config="$HOME/.config/hypr/${component}.conf"

    echo -e "${CYAN}Validating ${component} configuration...${NC}"

    if [[ ! -f "$config" ]]; then
        validate_warn "${component}.conf not found"
        return 0
    fi
    validate_pass "Config exists"

    # Check braces
    local ob cb
    ob=$(grep -c '{' "$config" 2>/dev/null || true)
    cb=$(grep -c '}' "$config" 2>/dev/null || true)
    if [[ "$ob" -ne "$cb" ]]; then
        validate_fail "Unmatched braces (open: $ob, close: $cb)"
    else
        validate_pass "Brace matching OK"
    fi
}

# ━━━ Systemd Service Validation ━━━

validate_systemd_user() {
    local service="$1"
    local desc="$2"

    echo -e "${CYAN}Validating ${desc}...${NC}"

    if systemctl --user is-active "$service" &>/dev/null; then
        validate_pass "${desc} is active"
    else
        validate_fail "${desc} is not active"
        local status
        status=$(systemctl --user status "$service" --no-pager 2>&1 | tail -3)
        validate_info "$status"
    fi

    if [[ "$DO_RELOAD" == "true" ]] && [[ "$VALIDATION_OK" == "true" ]]; then
        echo -e "${CYAN}Restarting ${desc}...${NC}"
        systemctl --user restart "$service" 2>/dev/null
        sleep 1
        if systemctl --user is-active "$service" &>/dev/null; then
            validate_pass "${desc} restarted successfully"
        else
            validate_fail "${desc} failed to restart"
        fi
    fi
}

# ━━━ Caelestia Validation ━━━

validate_caelestia() {
    echo -e "${CYAN}Validating Caelestia configuration...${NC}"
    local shell_json="$HOME/.config/caelestia/shell.json"
    local hypr_vars="$HOME/.config/caelestia/hypr-vars.lua"
    local hypr_user="$HOME/.config/caelestia/hypr-user.lua"

    if [[ -f "$shell_json" ]]; then
        if python3 -c "import json; json.load(open('$shell_json'))" 2>/dev/null; then
            validate_pass "shell.json syntax is valid"
        else
            validate_fail "shell.json syntax error"
            local json_err
            json_err=$(python3 -c "import json; json.load(open('$shell_json'))" 2>&1 || true)
            [[ -n "$json_err" ]] && validate_info "$json_err"
        fi
    else
        validate_warn "shell.json not found"
    fi

    # Validate Lua files
    for lua_file in "$hypr_vars" "$hypr_user"; do
        if [[ -f "$lua_file" ]]; then
            if luac -p "$lua_file" &>/dev/null; then
                validate_pass "$(basename "$lua_file") syntax is valid"
            else
                validate_fail "$(basename "$lua_file") syntax error:"
                local lua_err
                lua_err=$(luac -p "$lua_file" 2>&1 || true)
                [[ -n "$lua_err" ]] && validate_info "$lua_err"
            fi
        fi
    done

    # Reload Caelestia
    if [[ "$DO_RELOAD" == "true" ]] && [[ "$VALIDATION_OK" == "true" ]]; then
        echo ""
        echo -e "${CYAN}Restarting Caelestia Shell...${NC}"
        caelestia shell -k 2>/dev/null || true
        sleep 0.5
        caelestia shell -d 2>/dev/null || true
        sleep 2
        if pgrep -f "qs -c caelestia" &>/dev/null; then
            validate_pass "Caelestia shell running (PID: $(pgrep -f "qs -c caelestia" | head -1))"
        else
            validate_fail "Caelestia shell failed to start"
        fi
    fi
}

# ━━━ Main Dispatch ━━━

echo ""

case "$COMPONENT" in
    hyprland|hypr)      validate_hyprland ;;
    waybar)             validate_waybar ;;
    kitty)              validate_kitty ;;
    foot)               validate_ini_config "Foot" "$HOME/.config/foot/foot.ini" ;;
    rofi)               validate_ini_config "Rofi" "$HOME/.config/rofi/config.rasi" ;;
    dunst)              validate_ini_config "Dunst" "$HOME/.config/dunst/dunstrc" ;;
    mako)               validate_ini_config "Mako" "$HOME/.config/mako/config" ;;
    hyprlock)           validate_hypr_config "hyprlock" ;;
    hypridle)           validate_hypr_config "hypridle" ;;
    hyprpaper)          validate_hypr_config "hyprpaper" ;;
    pipewire)           validate_systemd_user "pipewire.service" "PipeWire" ;;
    wireplumber)        validate_systemd_user "wireplumber.service" "WirePlumber" ;;
    caelestia)          validate_caelestia ;;
    *)
        echo -e "${RED}Unknown component: ${COMPONENT}${NC}" >&2
        exit 2
        ;;
esac

# ━━━ Result ━━━

echo ""
if [[ "$VALIDATION_OK" == "true" ]]; then
    echo -e "${GREEN}✓ Validation passed for ${COMPONENT}${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation FAILED for ${COMPONENT}${NC}"

    if [[ "$AUTO_ROLLBACK" == "true" ]]; then
        echo -e "${YELLOW}Auto-rollback enabled — attempting restore...${NC}"

        case "$COMPONENT" in
            hyprland|hypr)
                local rolled_back=false
                if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
                    "$SCRIPT_DIR/restore.sh" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null && rolled_back=true
                fi
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null && rolled_back=true
                
                # Also restore overrides in ~/.config/caelestia if they were modified
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/caelestia/hypr-vars.lua" 2>/dev/null && rolled_back=true
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/caelestia/hypr-user.lua" 2>/dev/null && rolled_back=true

                if [[ "$rolled_back" == "true" ]]; then
                    hyprctl reload 2>/dev/null && \
                        echo -e "${GREEN}✓ Rolled back to previous configs${NC}" || \
                        echo -e "${RED}✗ Rollback failed! Manual intervention needed.${NC}"
                else
                    echo -e "${YELLOW}No backups found to roll back${NC}"
                fi
                ;;
            caelestia)
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/caelestia/shell.json" 2>/dev/null || true
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/caelestia/hypr-vars.lua" 2>/dev/null || true
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/caelestia/hypr-user.lua" 2>/dev/null || true
                caelestia shell -k 2>/dev/null || true
                sleep 0.5
                caelestia shell -d 2>/dev/null || true
                echo -e "${GREEN}✓ Rolled back to previous Caelestia configs${NC}"
                ;;
            waybar)
                "$SCRIPT_DIR/restore.sh" "$HOME/.config/waybar/config.jsonc" 2>/dev/null && \
                    killall waybar 2>/dev/null; nohup waybar &>/dev/null & disown; \
                    echo -e "${GREEN}✓ Rolled back to previous config${NC}" || \
                    echo -e "${RED}✗ Rollback failed! Manual intervention needed.${NC}"
                ;;
            *)
                echo -e "${YELLOW}Auto-rollback not implemented for ${COMPONENT}${NC}"
                ;;
        esac
    fi

    exit 1
fi
