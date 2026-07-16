---
name: dank-linux-desktop
description: >
  Safely manage a CachyOS / Arch Linux desktop running Hyprland with Lua config and Caelestia Shell.
  Covers system detection, configuration discovery, safe editing with backups, validation,
  reload workflows, package management, troubleshooting, and recovery procedures.
  Supports NVIDIA, AMD, and Intel GPUs on Wayland.
---

# Desktop Management Skill — Hyprland Lua + Caelestia Shell

## Scope

This skill enables an AI agent to safely inspect, configure, and manage a Linux desktop running:

- **OS**: CachyOS (Arch-based, rolling release, kernel 7.x+)
- **Compositor**: Hyprland 0.55+ (Wayland, configured natively with **Lua**)
- **Desktop Shell**: Caelestia Shell 2.x (Quickshell-based, Material Design 3)
- **Session**: Wayland only (X11 is NOT supported)

### What This Skill Covers

| Area | Examples |
|---|---|
| **Hyprland Lua Config** | `hl.config()`, `hl.bind()`, `hl.monitor()`, `hl.window_rule()`, `hl.on()` events, `hl.gesture()`, `hl.animation()`, `hl.curve()`, custom layouts |
| **Caelestia Shell** | Bar entries, launcher, sidebar, dashboard, notifications, lock screen, wallpaper, color schemes via `shell.json` and IPC commands |
| **User Variable Overrides** | `~/.config/caelestia/hypr-vars.lua` → returns a table merged into `variables.lua` |
| **User Custom Config** | `~/.config/caelestia/hypr-user.lua` → custom monitors, keybinds, window rules, event hooks |
| **Per-Monitor Shell Config** | `~/.config/caelestia/monitors/<NAME>/shell.json` |
| **Terminal Emulators** | Kitty, Foot, Ghostty, WezTerm, Alacritty |
| **Audio** | PipeWire + WirePlumber (managed via `wpctl`) |
| **Package Management** | `pacman`, `paru`, `yay` |
| **GPU** | NVIDIA (proprietary), AMD (mesa), Intel (mesa) on Wayland |
| **System Services** | systemd (system and user units) |

### What This Skill Does NOT Cover

- Server administration, containers, databases
- Kernel development or custom compilation
- Non-Hyprland compositors (Sway, KDE, GNOME)
- Network firewall rules beyond NetworkManager

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Hyprland Compositor (v0.55+, native Lua parser)        │
│  ├── Entry: ~/.config/hypr/hyprland.lua                 │
│  │   ├── package.path adds ~/.config/caelestia/         │
│  │   ├── require("hypr-vars") → hypr-vars.lua           │
│  │   │   (returns table, merged into variables.lua)     │
│  │   ├── require("hyprland.env")                        │
│  │   ├── require("hyprland.general")                    │
│  │   ├── require("hyprland.input")                      │
│  │   ├── require("hyprland.misc")                       │
│  │   ├── require("hyprland.animations")                 │
│  │   ├── require("hyprland.decoration")                 │
│  │   ├── require("hyprland.group")                      │
│  │   ├── require("hyprland.execs")                      │
│  │   │   └── hl.on("hyprland.start", fn)                │
│  │   │       └── hl.exec_cmd("caelestia shell -d")      │
│  │   ├── require("hyprland.rules")                      │
│  │   ├── require("hyprland.gestures")                   │
│  │   ├── require("hyprland.keybinds")                   │
│  │   └── require("hypr-user") ⬅ USER FILE (last!)      │
│  │                                                      │
│  Caelestia Shell (Quickshell process)                    │
│  ├── Process: qs -c caelestia                           │
│  ├── Config: ~/.config/caelestia/shell.json             │
│  ├── Per-monitor: ~/.config/caelestia/monitors/*/       │
│  └── Globals: caelestia:launcher, caelestia:sidebar...  │
└─────────────────────────────────────────────────────────┘
```

### Configuration Loading Order (Critical!)

1. `hyprland.lua` sets `package.path` to include `~/.config/caelestia/`
2. `hypr-vars.lua` is loaded FIRST — its returned table overrides keys in `variables.lua`
3. System config modules are loaded (`env`, `general`, `input`, etc.)
4. `hypr-user.lua` is loaded LAST — user's custom binds, rules, and monitors apply here
5. Caelestia shell starts as a separate process via `caelestia shell -d`

**Key insight**: Because `hypr-user.lua` loads after all system modules, it can override
any bind, rule, or setting. For variable overrides (gaps, borders, etc.), use `hypr-vars.lua`.
For everything else (binds, rules, monitors, hooks), use `hypr-user.lua`.

---

## Hyprland Lua API Reference

The global `hl` table provides the full compositor API. LSP stubs are at `/usr/share/hypr/stubs/hl.meta.lua`.

### Core Configuration

```lua
-- Set config options (nested table matching Hyprland config sections)
hl.config({
    general = { layout = "dwindle", gaps_in = 5, gaps_out = 10, border_size = 3 },
    decoration = { rounding = 15, blur = { enabled = true, size = 8, passes = 2 } },
    input = { kb_layout = "us", repeat_rate = 35 },
    misc = { disable_hyprland_logo = true },
})

-- Read a config value at runtime
local val = hl.get_config("general.gaps_in")

-- Set environment variables
hl.env("XCURSOR_THEME", "sweet-cursors")
```

### Keybindings

```lua
-- Basic bind: keys string + dispatcher
hl.bind("SUPER + T", hl.dsp.exec_cmd("foot"))

-- Bind with options
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("XF86AudioPlay", hl.dsp.global("caelestia:mediaToggle"), { locked = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Bind to a Lua function (for complex logic)
hl.bind("SUPER + ALT + P", function()
    local win = hl.get_active_window()
    if win then hl.dispatch(hl.dsp.window.float()) end
end)

-- Bind options: repeating, locked, release, mouse, long_press, description
```

### Dispatchers (`hl.dsp`)

```lua
hl.dsp.exec_cmd("command")          -- Execute shell command
hl.dsp.global("name")               -- Send global shortcut (for Caelestia IPC)
hl.dsp.focus({ workspace = "+1" })  -- Focus workspace
hl.dsp.focus({ direction = "left" })-- Focus window direction

-- Window dispatchers
hl.dsp.window.close()
hl.dsp.window.float({ action = "on" })
hl.dsp.window.fullscreen({ mode = "fullscreen" | "maximized" })
hl.dsp.window.move({ workspace = 3 })
hl.dsp.window.move({ direction = "right" })
hl.dsp.window.resize({ x = 100, y = 100, relative = true })
hl.dsp.window.center()
hl.dsp.window.pin()
hl.dsp.window.drag()              -- For mouse drag binding
hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true" })
hl.dsp.window.cycle_next()

-- Group dispatchers
hl.dsp.group.toggle()
hl.dsp.group.next()
hl.dsp.group.prev()
hl.dsp.group.lock_active()

-- Workspace dispatchers
hl.dsp.workspace.toggle_special()
```

### Monitors

```lua
hl.monitor({
    output   = "DP-1",          -- or "" for catch-all default
    mode     = "2560x1440@280.0",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,              -- optional: 8 or 10
    vrr      = 1,               -- optional: 0=off, 1=on, 2=fullscreen-only
})
```

### Window Rules

```lua
-- Match by class, title, float, xwayland, tag, fullscreen
hl.window_rule({
    match = { class = "firefox" },
    opacity = "0.95 override",
    workspace = "2",
})

-- Tag-based rules (assign a tag, then apply rules to tag)
hl.window_rule({ match = { class = "steam" }, tag = "+game" })
hl.window_rule({ match = { tag = "game" }, immediate = true, idle_inhibit = "always" })

-- Sized floaters
hl.window_rule({
    match  = { class = "pavucontrol" },
    float  = true,
    size   = "(monitor_w*0.6) (monitor_h*0.7)",
    center = true,
})
```

### Workspace & Layer Rules

```lua
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 20 })
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true })
```

### Event Hooks

```lua
-- Available events: hyprland.start, config.reloaded, hyprland.shutdown,
-- window.open, window.close, window.active, window.title, window.class,
-- window.fullscreen, window.move_to_workspace, window.pin, window.urgent,
-- workspace.active, workspace.created, workspace.removed,
-- monitor.added, monitor.removed, monitor.focused

hl.on("hyprland.start", function()
    hl.exec_cmd("some-startup-command")
end)

hl.on("window.open", function(win)
    -- win has: class, title, address, floating, size, pid, etc.
    if win.class == "special-app" then
        hl.dispatch(hl.dsp.window.float({ window = win }))
    end
end)
```

### Animations & Curves

```lua
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard" })
```

### Gestures

```lua
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "special" })
hl.gesture({ fingers = 3, direction = "down", action = function()
    hl.exec_cmd("caelestia toggle specialws")
end })
```

### Device Configuration

```lua
hl.device({ name = "logitech-g502", sensitivity = -0.5, accel_profile = "flat" })
```

### Runtime Queries

```lua
local win     = hl.get_active_window()    -- HL.Window or nil
local ws      = hl.get_active_workspace() -- HL.Workspace or nil
local mon     = hl.get_active_monitor()   -- HL.Monitor or nil
local windows = hl.get_windows()          -- HL.Window[]
local pos     = hl.get_cursor_pos()       -- HL.Vec2 or nil

-- Window properties: class, title, address, floating, pinned, size.x, size.y,
--                    fullscreen, workspace, monitor, pid, xwayland, hidden, etc.
-- Monitor properties: name, width, height, scale, x, y, refresh_rate, etc.
```

### Timers

```lua
hl.timer(function() print("fired") end, { timeout = 5000, type = "oneshot" })
hl.timer(function() print("tick") end, { timeout = 1000, type = "repeat" })
```

### Custom Layouts

```lua
hl.layout.register("my-layout", {
    recalculate = function(ctx)
        for i, target in ipairs(ctx.targets) do
            target:place(ctx:grid_cell(i, 3))  -- 3-column grid
        end
    end,
})
```

### Execute Commands

```lua
-- exec_cmd runs a shell command (exec-once equivalent in hyprland.start hook)
hl.exec_cmd("command-here")

-- Dispatch an exec dispatcher (for use within binds)
hl.dispatch(hl.dsp.exec_cmd("command"))
```

---

## Caelestia Shell Reference

### Versions Installed

- **caelestia-shell-git**: 2.1.0 (Quickshell 0.3.0)
- **caelestia-cli**: 1.1.1

### CLI Commands

| Command | Purpose |
|---|---|
| `caelestia shell -d` | Start shell (daemonized) |
| `caelestia shell -k` | Kill running shell |
| `caelestia shell -l` | Tail the shell log |
| `caelestia shell -s` | Print all IPC targets/functions |
| `caelestia shell <msg>` | Send IPC message to shell |
| `caelestia scheme list` | List color schemes |
| `caelestia scheme get` | Get current scheme |
| `caelestia scheme set <name>` | Set color scheme |
| `caelestia wallpaper -f <path>` | Set wallpaper |
| `caelestia wallpaper -r [dir]` | Random wallpaper |
| `caelestia screenshot` | Full screenshot |
| `caelestia screenshot -r` | Region screenshot |
| `caelestia record` | Start screen recording |
| `caelestia record -s` | Record with audio |
| `caelestia toggle <ws>` | Toggle special workspace |
| `caelestia clipboard` | Open clipboard history |
| `caelestia emoji -p` | Open emoji picker |

### Shell IPC Targets

Send IPC via `caelestia shell <target> <function> [args]`:

| Target | Functions |
|---|---|
| **drawers** | `list()`, `isOpen(drawer)`, `toggle(drawer)` |
| **nexus** | `open()` |
| **picker** | `open()`, `openFreeze()`, `openClip()`, `openFreezeClip()` |
| **brightness** | `get()`, `set(value)`, `getFor(query)`, `setFor(query, value)` |
| **lock** | `lock()`, `unlock()`, `isLocked()` |
| **audio** | `cycleOutput()` |
| **hypr** | `listSpecialWorkspaces()`, `refreshDevices()`, `cycleSpecialWorkspace(dir)` |
| **wallpaper** | `get()`, `set(path)`, `list()` |
| **notifs** | `isDndEnabled()`, `toggleDnd()`, `clear()`, `enableDnd()`, `disableDnd()` |
| **toaster** | `info(title, msg, icon)`, `warn(...)`, `success(...)`, `error(...)` |
| **mpris** | `playPause()`, `play()`, `pause()`, `stop()`, `next()`, `previous()`, `list()`, `getActive(prop)` |

### Caelestia Keybind Globals

Keybinds communicate with Caelestia via `hl.dsp.global("caelestia:<name>")`:

| Global | Purpose |
|---|---|
| `caelestia:launcher` | Open app launcher (bound to SUPER release) |
| `caelestia:sidebar` | Toggle sidebar panel |
| `caelestia:session` | Open session dialog (logout/reboot/etc.) |
| `caelestia:lock` | Lock screen |
| `caelestia:clearNotifs` | Clear all notifications |
| `caelestia:showall` | Show all panels |
| `caelestia:screenshot` | Screenshot UI |
| `caelestia:screenshotFreeze` | Freeze-frame screenshot |
| `caelestia:mediaToggle` | Play/pause media |
| `caelestia:mediaNext` | Next track |
| `caelestia:mediaPrev` | Previous track |
| `caelestia:mediaStop` | Stop media |
| `caelestia:brightnessUp` | Increase brightness |
| `caelestia:brightnessDown` | Decrease brightness |

### shell.json Structure

Located at `~/.config/caelestia/shell.json`. Key sections:

```json
{
  "appearance": { "transparency": { "enabled": true } },
  "background": { "wallpaperEnabled": true },
  "bar": {
    "entries": [
      { "id": "logo|workspaces|activeWindow|clock|tray|statusIcons|power", "zone": "left|middle|right", "enabled": true }
    ],
    "persistent": false,
    "showOnHover": true,
    "clock": { "showDate": true, "background": true },
    "workspaces": { "shown": 3, "activeTrail": true },
    "status": { "showAudio": true, "showBattery": false, "showNetwork": false },
    "tray": { "background": true, "compact": false }
  },
  "launcher": { "enabled": true, "favouriteApps": ["app.desktop.id", ...], "showOnHover": true },
  "sidebar": { "enabled": true, "dragThreshold": 35 },
  "dashboard": { "enabled": true },
  "general": { "apps": { "terminal": ["foot"], "explorer": ["thunar"] }, "logo": "caelestia" },
  "services": { "maxVolume": 2 }
}
```

Per-monitor overrides: `~/.config/caelestia/monitors/<MONITOR_NAME>/shell.json`

---

## Configuration Files Map

| File | Purpose | Safe to Edit? |
|---|---|---|
| `~/.config/hypr/hyprland.lua` | Entry point, loads all modules | ⚠ Avoid — modify overrides instead |
| `~/.config/hypr/variables.lua` | Default variables (apps, gaps, keybinds) | ⚠ Avoid — use hypr-vars.lua |
| `~/.config/hypr/hyprland/*.lua` | System config modules | ⚠ Avoid — use hypr-user.lua |
| `~/.config/hypr/scheme/current.lua` | Color scheme tokens | ⚠ Managed by Caelestia |
| `~/.config/caelestia/hypr-vars.lua` | **User variable overrides** | ✅ Primary override target |
| `~/.config/caelestia/hypr-user.lua` | **User custom config** | ✅ Primary config target |
| `~/.config/caelestia/shell.json` | **Shell layout/behavior** | ✅ Shell config target |
| `~/.config/caelestia/monitors/*/shell.json` | Per-monitor shell overrides | ✅ |

### Default Variables (from `variables.lua`)

These can be overridden in `hypr-vars.lua` by returning a table with any of these keys:

```lua
return {
    -- Apps
    terminal = "foot",            browser = "firefox",
    editor = "codium",            fileExplorer = "thunar",

    -- Styling
    windowOpacity = 0.95,         windowRounding = 15,
    windowBorderSize = 3,         windowGapsIn = 5,
    windowGapsOut = 10,           workspaceGaps = 20,

    -- Blur
    blurEnabled = true,           blurSize = 8,
    blurPasses = 2,

    -- Shadow
    shadowEnabled = true,         shadowRange = 15,

    -- Audio
    volumeStep = 10,              volumeMax = 100,

    -- Cursor
    cursorTheme = "sweet-cursors", cursorSize = 24,

    -- Keybinds (modifier combos)
    kbTerminal = "SUPER + T",     kbBrowser = "SUPER + W",
    kbCloseWindow = "SUPER + Q",  kbWindowFullscreen = "SUPER + F",
    kbToggleWindowFloating = "SUPER + ALT + space",
    kbSpecialWs = "SUPER + S",    kbMusicWs = "SUPER + M",
    -- ... (see variables.lua for full list)
}
```

---

## Safety Rules

### ABSOLUTE RULES — NEVER VIOLATE

1. **NEVER run destructive commands** (`rm -rf`, `dd`, `mkfs`, `fdisk`) without explicit user confirmation.
2. **NEVER edit system boot/mount files** (`/etc/fstab`, mkinitcpio, bootloader, LUKS) without explicit confirmation AND a backup.
3. **NEVER overwrite a complete config file** when only one setting needs to change. Use targeted edits.
4. **ALWAYS create a timestamped backup** before editing ANY configuration file.
5. **ALWAYS validate** configuration after editing and **auto-rollback on failure**.
6. **NEVER install unverified AUR packages.** Only recommend well-known, actively maintained packages.
7. **NEVER modify system module files** (`~/.config/hypr/hyprland/*.lua`) directly. Use the user override files.

### Editing Priorities

| Change Type | Target File |
|---|---|
| Visual styling (gaps, borders, rounding, blur, shadow) | `hypr-vars.lua` |
| Default apps (terminal, browser, editor) | `hypr-vars.lua` |
| Keybind modifier prefixes | `hypr-vars.lua` |
| Custom keybinds and window rules | `hypr-user.lua` |
| Monitor config (resolution, scale, position, HDR) | `hypr-user.lua` |
| Event hooks and startup commands | `hypr-user.lua` |
| Shell bar, launcher, sidebar settings | `shell.json` |
| Color scheme | `caelestia scheme set <name>` CLI |
| Wallpaper | `caelestia wallpaper -f <path>` CLI |

### When to Ask Confirmation

- Change affects system boot, network, or GPU config
- Installing or removing packages
- Modifying systemd services
- Change could break the current session
- You are uncertain about the correct approach

### When to Proceed Without Asking

- Adding a keybinding to `hypr-user.lua`
- Changing visual settings in `hypr-vars.lua` or `shell.json`
- Editing terminal emulator appearance
- The user explicitly asked for a specific change

---

## Agent Decision Process

```
1. DETECT the current system state
   └─> Run: scripts/detect.sh

2. DISCOVER the relevant configuration
   └─> Run: scripts/find-config.sh <component>
   └─> Read the config files to understand current state

3. ASSESS the change
   ├─> Is it a visual/variable override? → Target hypr-vars.lua
   ├─> Is it a custom bind/rule/monitor? → Target hypr-user.lua
   ├─> Is it a shell layout option? → Target shell.json
   └─> Is it a DANGER ZONE edit? → ASK CONFIRMATION

4. BACKUP the target file(s)
   └─> Run: scripts/backup.sh <filepath>

5. MAKE the change
   └─> Use safe-edit.sh or targeted file editing

6. VALIDATE the change
   └─> Run: scripts/validate.sh <component>

7. RELOAD the component
   └─> Run: scripts/reload.sh <component>

8. VERIFY success
   └─> Check hyprctl / caelestia shell -l output
   └─> If FAILED → scripts/restore.sh <filepath> (auto-rollback)
```

---

## Validation & Reload

### Validate

```bash
scripts/validate.sh hyprland    # luac -p on all Lua modules recursively + hyprctl reload
scripts/validate.sh caelestia   # JSON check on shell.json + luac -p on Lua files + shell restart
scripts/validate.sh waybar      # Process check + JSON syntax
```

### Reload

| Component | Method |
|---|---|
| `hyprland` | `hyprctl reload` |
| `caelestia` | `caelestia shell -k && sleep 0.5 && caelestia shell -d` |
| `waybar` | `killall waybar; waybar &` |
| `kitty` | `pkill -USR1 kitty` |
| `pipewire` | `systemctl --user restart pipewire.service` |

### Doctor (Full Health Check)

```bash
scripts/doctor.sh               # Full system health diagnosis
scripts/doctor.sh --component hyprland  # Targeted check
scripts/doctor.sh --fix         # Attempt auto-fixes
```

---

## Troubleshooting

### Log Sources

```bash
journalctl --user -n 50 --no-pager          # User session log
caelestia shell -l | tail -n 50              # Caelestia shell log
hyprctl configerrors                         # Hyprland config errors
hyprctl systeminfo                           # System info dump
```

### Recovery

```bash
# Shell crashed
caelestia shell -k
caelestia shell -d

# Config broken — restore from backup
scripts/restore.sh ~/.config/caelestia/hypr-user.lua
hyprctl reload

# Full panic recovery
scripts/restore.sh ~/.config/hypr/hyprland.lua
scripts/restore.sh ~/.config/caelestia/hypr-vars.lua
scripts/restore.sh ~/.config/caelestia/hypr-user.lua
hyprctl reload
caelestia shell -k && caelestia shell -d
```

---

## Examples

### Example 1: Override border size and gaps

Edit `~/.config/caelestia/hypr-vars.lua`:
```lua
return {
    windowBorderSize = 4,
    windowGapsIn = 8,
    windowGapsOut = 12,
    windowRounding = 20,
}
```
Then: `hyprctl reload`

### Example 2: Add custom keybind and window rule

Append to `~/.config/caelestia/hypr-user.lua`:
```lua
-- Launch pavucontrol with SUPER+ALT+V
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("pavucontrol"))

-- Float and center pavucontrol
hl.window_rule({
    match  = { class = "org.pulseaudio.pavucontrol" },
    float  = true,
    size   = "(monitor_w*0.6) (monitor_h*0.7)",
    center = true,
})
```

### Example 3: Configure monitor with HDR

Append to `~/.config/caelestia/hypr-user.lua`:
```lua
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@280.0",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,
})

experimental = { color_management = true }
render = { cm_auto_hdr = true }
```

### Example 4: Modify shell launcher favorites

Edit `~/.config/caelestia/shell.json`, changing the `launcher.favouriteApps` array:
```json
"launcher": {
    "favouriteApps": [
        "org.kde.dolphin",
        "org.gnome.Ptyxis",
        "firefox",
        "antigravity-ide"
    ]
}
```
Then: `scripts/validate.sh caelestia`

### Example 5: Add a startup hook

Append to `~/.config/caelestia/hypr-user.lua`:
```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet --indicator")
end)
```

### Example 6: React to window events

Append to `~/.config/caelestia/hypr-user.lua`:
```lua
hl.on("window.open", function(win)
    if win.class == "steam_app_default" then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", window = win }))
    end
end)
```
