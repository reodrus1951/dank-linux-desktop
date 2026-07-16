# Desktop Management Skill — Hyprland Lua + Caelestia Shell

A production-ready AI agent skill for safely managing a CachyOS / Arch Linux desktop
running Hyprland (Lua config) and Caelestia Shell.

## Overview

This skill teaches an AI coding assistant how to:

- **Detect** the full system configuration (OS, GPU, monitors, services, themes)
- **Discover** all Lua configuration modules across Hyprland and Caelestia
- **Safely edit** configs with mandatory backups, validation, and auto-rollback
- **Reload** components without breaking the running session
- **Diagnose** and fix common desktop issues
- **Manage packages** using pacman, paru, and yay
- **Recover** from broken configurations

## Supported Stack

| Component | Supported |
|---|---|
| **OS** | CachyOS, EndeavourOS, Arch Linux (any Arch-based) |
| **WM** | Hyprland 0.55+ (Wayland, native Lua config) |
| **Shell** | Caelestia Shell 2.x (Quickshell-based, Material Design 3) |
| **GPU** | NVIDIA (proprietary), AMD (mesa), Intel (mesa) |
| **Audio** | PipeWire + WirePlumber |
| **Terminal** | Kitty, Foot, Ghostty, WezTerm, Alacritty |
| **Launcher** | Caelestia launcher, Rofi, Wofi, Fuzzel |
| **Notifications** | Caelestia shell (built-in), Mako |
| **Lock** | Caelestia lock screen (built-in) |
| **Wallpaper** | Caelestia wallpaper manager |

## Directory Structure

```
dank-linux-desktop/
├── README.md                    # This file
├── SKILL.md                     # AI agent instructions (primary skill file)
├── CLAUDE.md                    # Additional agent context and rules
├── install.sh                   # Installation and verification script
│
├── scripts/                     # Production-ready bash scripts
│   ├── detect.sh                # Full system detection
│   ├── collect-system-info.sh   # Comprehensive info for bug reports
│   ├── find-config.sh           # Find config files for any component
│   ├── backup.sh                # Create/list/diff timestamped backups
│   ├── restore.sh               # Restore backups (latest or by timestamp)
│   ├── safe-edit.sh             # Safe config editing with backup + validation
│   ├── validate.sh              # Validate config and reload component
│   ├── reload.sh                # Reload individual components
│   └── doctor.sh                # Diagnose system health issues
│
├── references/                  # Detailed component documentation
│   └── troubleshooting.md       # Common issues and solutions
│
└── templates/                   # Config file templates
```

## Usage

### For AI Agents

The AI agent reads `SKILL.md` to understand the system and follows the documented
decision process for every change. The agent uses the scripts in `scripts/` as tools.

### For Humans

The scripts work standalone:

```bash
# Detect your system
./scripts/detect.sh

# Run health check
./scripts/doctor.sh

# Backup a config before editing
./scripts/backup.sh ~/.config/caelestia/hypr-user.lua

# Safely edit with auto-rollback on failure
./scripts/safe-edit.sh ~/.config/caelestia/hypr-user.lua caelestia

# Validate Hyprland Lua configs
./scripts/validate.sh hyprland

# Validate Caelestia configs
./scripts/validate.sh caelestia

# Restore if something breaks
./scripts/restore.sh ~/.config/caelestia/hypr-user.lua
```

## Safety Guarantees

1. **Every edit is backed up** — timestamped backups in `.backups/` subdirectories
2. **Every change is validated** — `luac -p` syntax checks + reload verification
3. **Failed changes auto-rollback** — if validation fails, the previous config is restored
4. **Dangerous operations require confirmation** — boot, GPU, network, and disk changes
5. **System modules are never modified directly** — user override files are used
6. **Comments and formatting are preserved** — minimal patches, never full rewrites

## License

MIT License. Use freely.
