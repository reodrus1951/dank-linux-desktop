# Agent Instructions — Desktop Management (Hyprland Lua + Caelestia)

## Identity

You are managing a CachyOS (Arch Linux) desktop running Hyprland 0.55+ on Wayland
with Caelestia Shell as the desktop shell layer. Configuration is written in **Lua**
(not the legacy hyprlang `.conf` syntax).

## Critical Context

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Wayland Session                                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Hyprland (compositor, native Lua config parser)  │  │
│  │  ├─︎─︎ Entry: ~/.config/hypr/hyprland.lua           │  │
│  │  ├─︎─︎ Modules: ~/.config/hypr/hyprland/*.lua       │  │
│  │  ├─︎─︎ Variables: ~/.config/hypr/variables.lua      │  │
│  │  ├─︎─︎ User overrides: ~/.config/caelestia/         │  │
│  │  │   ├─︎─︎ hypr-vars.lua  (variable overrides)      │  │
│  │  │   └─︎─︎ hypr-user.lua  (custom config, LAST)     │  │
│  │  └─︎─︎ Scheme: ~/.config/hypr/scheme/current.lua    │  │
│  ├─︎─︎─────────────────────────────────────────────────┤  │
│  │  Caelestia Shell (Quickshell process)             │  │
│  │  ├─︎─︎ Process: qs -c caelestia                     │  │
│  │  ├─︎─︎ Config: ~/.config/caelestia/shell.json       │  │
│  │  └─︎─︎ CLI: caelestia shell -d/-k/-l/-s             │  │
│  ├─︎─︎─────────────────────────────────────────────────┤  │
│  │  PipeWire + WirePlumber (audio)                   │  │
│  │  └─︎─︎ Services: pipewire, wireplumber              │  │
│  └─︎─︎─────────────────────────────────────────────────┘  │
│  GPU: NVIDIA RTX 4070 Ti (proprietary driver)           │
│  Network: NetworkManager                                │
└─────────────────────────────────────────────────────────┘
```

### Config Loading Order (Hyprland Lua)

Hyprland parses `hyprland.lua` sequentially via Lua `require()`:

1. `package.path` extended to include `~/.config/caelestia/`
2. `hypr-vars.lua` loaded — returned table merges into `variables.lua`
3. System modules loaded: `env`, `general`, `input`, `misc`, `animations`,
   `decoration`, `group`, `execs`, `rules`, `gestures`, `keybinds`
4. `hypr-user.lua` loaded **LAST** — user custom binds, rules, monitors

**Key insight:** `hypr-user.lua` runs last, so it can override any bind, rule,
or setting from the system modules. For variable overrides (gaps, borders, etc.),
use `hypr-vars.lua` which merges into the variables table before system modules run.

### Choosing WHERE to Edit

| Change Type | Target File |
|---|---|
| Visual styling (gaps, borders, rounding, blur, shadow) | `hypr-vars.lua` |
| Default apps, cursor theme, volume step | `hypr-vars.lua` |
| Keybind modifier prefixes | `hypr-vars.lua` |
| Custom keybinds, window rules, event hooks | `hypr-user.lua` |
| Monitor config (resolution, scale, HDR, VRR) | `hypr-user.lua` |
| Shell bar, launcher, sidebar, dashboard | `shell.json` |
| Color scheme | `caelestia scheme set <name>` |
| Wallpaper | `caelestia wallpaper -f <path>` |

### Caelestia IPC

Caelestia exposes functionality via IPC globals and CLI:

```lua
-- From keybinds (in hypr-user.lua):
hl.bind("SUPER + N", hl.dsp.global("caelestia:sidebar"))
hl.bind("SUPER + SUPER_L", hl.dsp.global("caelestia:launcher"), { release = true })
```

```bash
# From shell:
caelestia shell drawers toggle sidebar
caelestia shell lock lock
caelestia shell notifs toggleDnd
caelestia shell toaster info "Title" "Message" "icon-name"
caelestia shell wallpaper set "/path/to/image.jpg"
```

## Decision Rules

### Before ANY Config Edit

1. Run `scripts/find-config.sh <component>` to locate all relevant files
2. Read the files to understand current state
3. Verify the target file is a user-editable file (hypr-vars, hypr-user, shell.json)
4. Run `scripts/backup.sh <filepath>` to create a backup
5. Make the minimal change needed
6. Run `scripts/validate.sh <component>` to verify

### Error Recovery Priority

1. **Auto-rollback** — `validate.sh` handles this automatically
2. **Manual restore** — `scripts/restore.sh <file>`
3. **Shell restart** — `caelestia shell -k && caelestia shell -d`
4. **TTY recovery** — `Ctrl+Alt+F2`, login, fix config, `Ctrl+Alt+F1`

## NVIDIA-Specific Rules

This system has an NVIDIA RTX 4070 Ti. Key considerations:

1. **Environment variables** are set in `hyprland/env.lua` (system module)
2. **HDR support** — Monitor runs 10-bit with `cm_auto_hdr = true` in `hypr-user.lua`
3. **VRR** — Monitor supports up to 280Hz
4. **After kernel updates:** CachyOS handles NVIDIA module rebuilds via hooks

## Package Management Rules

1. **Always use `paru`** as the AUR helper (CachyOS default)
2. **Prefer official repos** (`pacman -S`) over AUR
3. **Check CachyOS repos first** — they have optimized builds
4. **Never install without showing the user** what will be installed

## File Encoding

All config files use UTF-8. The user writes comments in Spanish.
Preserve all non-ASCII characters exactly.

## Session Variables

These environment variables are critical and must never be modified:

```
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
WAYLAND_DISPLAY=wayland-1
HYPRLAND_INSTANCE_SIGNATURE=<hash>
```
