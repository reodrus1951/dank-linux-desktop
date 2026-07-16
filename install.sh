#!/usr/bin/env bash
# install.sh — Install and verify the Desktop Management Skill
# Usage: ./install.sh [--check-only]

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SKILL_DIR}/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERR]${NC}  $*"; }
log_header()  { echo -e "\n${BOLD}${CYAN}━━━━━━ $* ━━━━━━${NC}"; }

CHECK_ONLY=false
if [[ "${1:-}" == "--check-only" ]]; then
    CHECK_ONLY=true
fi

ERRORS=0
WARNINGS=0

check_command() {
    local cmd="$1"
    local desc="${2:-$1}"
    local required="${3:-true}"

    if command -v "$cmd" &>/dev/null; then
        log_ok "$desc found: $(command -v "$cmd")"
        return 0
    elif [[ "$required" == "true" ]]; then
        log_error "$desc NOT found (required)"
        ERRORS=$((ERRORS + 1))
        return 0
    else
        log_warn "$desc not found (optional)"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi
}

check_service() {
    local svc="$1"
    local desc="${2:-$1}"
    local user="${3:-true}"

    if [[ "$user" == "true" ]]; then
        if systemctl --user is-active "$svc" &>/dev/null; then
            log_ok "$desc is active (user service)"
            return 0
        else
            log_warn "$desc is not active"
            WARNINGS=$((WARNINGS + 1))
            return 0
        fi
    else
        if systemctl is-active "$svc" &>/dev/null; then
            log_ok "$desc is active (system service)"
            return 0
        else
            log_warn "$desc is not active"
            WARNINGS=$((WARNINGS + 1))
            return 0
        fi
    fi
}

# ━━━ Header ━━━
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Desktop Management Skill — Installer               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ━━━ Step 1: Verify OS ━━━
log_header "Step 1: Verifying Operating System"

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    log_info "Detected OS: ${PRETTY_NAME:-unknown}"

    if [[ "${ID_LIKE:-$ID}" == *"arch"* ]] || [[ "${ID:-}" == "arch" ]] || [[ "${ID:-}" == "cachyos" ]]; then
        log_ok "Arch-based system confirmed"
    else
        log_error "This skill requires an Arch-based system (detected: ${ID:-unknown})"
        ERRORS=$((ERRORS + 1))
    fi
else
    log_error "/etc/os-release not found — cannot detect OS"
    ERRORS=$((ERRORS + 1))
fi

# ━━━ Step 2: Verify Session ━━━
log_header "Step 2: Verifying Session Type"

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    log_ok "Wayland session confirmed"
else
    log_warn "Not running in a Wayland session (current: ${XDG_SESSION_TYPE:-unset})"
    log_warn "Hyprland requires Wayland. Some scripts may not work."
    WARNINGS=$((WARNINGS + 1))
fi

# ━━━ Step 3: Verify Core Tools ━━━
log_header "Step 3: Verifying Core Tools"

check_command "hyprctl"     "Hyprland (hyprctl)"
check_command "pacman"      "pacman"
check_command "systemctl"   "systemd (systemctl)"
check_command "bash"        "Bash"
check_command "grep"        "grep"
check_command "sed"         "sed"
check_command "awk"         "awk"
check_command "diff"        "diff"
check_command "date"        "date"
check_command "journalctl"  "journalctl"
check_command "lspci"       "lspci"          "false"

# ━━━ Step 4: Verify Desktop Components ━━━
log_header "Step 4: Verifying Desktop Components"

check_command "caelestia"    "Caelestia Shell CLI"          "false"
check_command "qs"           "Quickshell"                    "false"
check_command "luac"         "Lua compiler (luac)"           "false"
check_command "foot"         "Foot terminal"                 "false"
check_command "kitty"        "Kitty terminal"                "false"
check_command "fuzzel"       "Fuzzel launcher"               "false"

# ━━━ Step 5: Verify Package Managers ━━━
log_header "Step 5: Verifying Package Managers"

check_command "paru"  "paru (AUR helper)"  "false"
check_command "yay"   "yay (AUR helper)"   "false"

if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    log_warn "No AUR helper found. AUR packages cannot be installed."
    log_warn "Install paru: sudo pacman -S paru"
fi

# ━━━ Step 6: Verify Services ━━━
log_header "Step 6: Verifying Services"

# Check if Caelestia shell is running (not a systemd service)
if pgrep -f "qs -c caelestia" &>/dev/null; then
    log_ok "Caelestia Shell is running"
else
    log_warn "Caelestia Shell is not running"
    WARNINGS=$((WARNINGS + 1))
fi

# ━━━ Step 7: Verify Config Files ━━━
log_header "Step 7: Verifying Configuration Files"

check_file() {
    local path="$1"
    local desc="$2"
    local expanded_path="${path/#\~/$HOME}"

    if [[ -f "$expanded_path" ]]; then
        log_ok "$desc exists: $path"
        return 0
    elif [[ -d "$expanded_path" ]]; then
        log_ok "$desc directory exists: $path"
        return 0
    else
        log_warn "$desc not found: $path"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi
}

check_file "~/.config/hypr/hyprland.lua"         "Hyprland Lua config"
check_file "~/.config/hypr/variables.lua"         "Hyprland variables"
check_file "~/.config/caelestia"                  "Caelestia config directory"
check_file "~/.config/caelestia/hypr-vars.lua"    "User variable overrides"
check_file "~/.config/caelestia/hypr-user.lua"    "User custom config"
check_file "~/.config/caelestia/shell.json"       "Caelestia shell config"

# ━━━ Step 8: GPU Detection ━━━
log_header "Step 8: GPU Detection"

GPU_INFO=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || echo "unknown")
if [[ "$GPU_INFO" == *"NVIDIA"* ]]; then
    log_ok "NVIDIA GPU detected"
    if command -v nvidia-smi &>/dev/null; then
        NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "unknown")
        log_info "NVIDIA driver version: $NVIDIA_VERSION"
    else
        log_warn "nvidia-smi not found — driver may not be installed"
        WARNINGS=$((WARNINGS + 1))
    fi
elif [[ "$GPU_INFO" == *"AMD"* ]] || [[ "$GPU_INFO" == *"ATI"* ]]; then
    log_ok "AMD GPU detected"
elif [[ "$GPU_INFO" == *"Intel"* ]]; then
    log_ok "Intel GPU detected"
else
    log_warn "Could not detect GPU: $GPU_INFO"
    WARNINGS=$((WARNINGS + 1))
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
    log_header "Check Complete"
    echo -e "${BOLD}Errors: ${RED}${ERRORS}${NC}  ${BOLD}Warnings: ${YELLOW}${WARNINGS}${NC}"
    exit "$ERRORS"
fi

# ━━━ Step 9: Make Scripts Executable ━━━
log_header "Step 9: Setting Script Permissions"

if [[ -d "$SCRIPTS_DIR" ]]; then
    chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
    log_ok "All scripts in scripts/ are now executable"
else
    log_error "scripts/ directory not found at $SCRIPTS_DIR"
    ERRORS=$((ERRORS + 1))
fi

# Make example scripts executable
if [[ -d "${SKILL_DIR}/examples" ]]; then
    chmod +x "${SKILL_DIR}/examples"/*.sh 2>/dev/null || true
    log_ok "All scripts in examples/ are now executable"
fi

# ━━━ Step 10: Create Backup Directory ━━━
log_header "Step 10: Initializing Backup Structure"

BACKUP_DIRS=(
    "$HOME/.config/hypr/.backups"
    "$HOME/.config/caelestia/.backups"
)

for dir in "${BACKUP_DIRS[@]}"; do
    if [[ -d "$(dirname "$dir")" ]]; then
        mkdir -p "$dir"
        log_ok "Created backup directory: $dir"
    fi
done

# ━━━ Step 11: Initial Detection ━━━
log_header "Step 11: Running Initial System Detection"

if [[ -x "${SCRIPTS_DIR}/detect.sh" ]]; then
    echo ""
    "${SCRIPTS_DIR}/detect.sh" --quiet || true
    echo ""
else
    log_warn "detect.sh not found or not executable"
    WARNINGS=$((WARNINGS + 1))
fi

# ━━━ Summary ━━━
log_header "Installation Complete"

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ Skill installed successfully!${NC}"
else
    echo -e "${RED}${BOLD}✗ Installation completed with $ERRORS error(s)${NC}"
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}  $WARNINGS warning(s) — optional components missing${NC}"
fi

echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo "  ./scripts/detect.sh           # Detect system configuration"
echo "  ./scripts/doctor.sh           # Run health diagnostics"
echo "  ./scripts/backup.sh <file>    # Backup a config file"
echo "  ./scripts/safe-edit.sh <file> # Safely edit a config"
echo ""

exit "$ERRORS"
