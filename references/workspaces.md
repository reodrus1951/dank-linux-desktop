# Workspaces Reference

## Overview

Hyprland workspaces are virtual desktops. Each monitor has its own workspace
stack. Workspaces are created dynamically or can be defined statically.

## Basic Workspace Usage

```conf
# Switch to workspace
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2

# Move window to workspace
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2

# Move window silently (don't follow)
bind = SUPER ALT, 1, movetoworkspacesilent, 1

# Relative workspace switching
bind = SUPER, Page_Down, workspace, e+1    # Next
bind = SUPER, Page_Up, workspace, e-1      # Previous
```

## Workspace Configuration

```conf
# Assign workspaces to monitors
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:HDMI-A-1, default:true
workspace = 5, monitor:HDMI-A-1

# Named workspaces
workspace = name:browser, monitor:DP-1
workspace = name:code, monitor:DP-1
workspace = name:chat, monitor:HDMI-A-1

# Workspace rules
workspace = 1, gapsin:0, gapsout:0, border:false    # No gaps/border on workspace 1
workspace = 3, rounding:false                         # No rounding on workspace 3
```

## Special Workspaces (Scratchpads)

Special workspaces are overlay workspaces that can be toggled on/off:

```conf
# Toggle special workspace
bind = SUPER, S, togglespecialworkspace, magic

# Move window to special workspace
bind = SUPER SHIFT, S, movetoworkspace, special:magic
```

Special workspace options:
```conf
workspace = special:magic, gapsin:10, gapsout:20, on-created-empty:kitty
```

## Workspace Selectors

| Selector | Description |
|---|---|
| `1`, `2`, `3`... | Workspace by ID |
| `e+1`, `e-1` | Next/previous (relative) |
| `m+1`, `m-1` | Next/previous on current monitor |
| `r+1`, `r-1` | Next/previous relative to current |
| `name:foo` | Workspace by name |
| `special:name` | Special workspace |
| `empty` | First empty workspace |
| `previous` | Previously active workspace |

## DMS Workspace Features

DMS provides enhanced workspace features:

```conf
# Workspace overview (expose-like)
bind = SUPER, TAB, exec, dms ipc call hypr toggleOverview

# Rename workspace
bind = CTRL SHIFT, R, exec, dms ipc call workspace-rename open
```

## Runtime Workspace Commands

```bash
# Create/switch to workspace
hyprctl dispatch workspace 5

# Move window to workspace
hyprctl dispatch movetoworkspace 3

# Rename workspace
hyprctl dispatch renameworkspace 1 Browser

# Get workspace info
hyprctl workspaces
hyprctl activeworkspace
```

## Workspace Rules vs Window Rules

- **Workspace rules** (`workspace = ...`) define workspace properties
- **Window rules** (`windowrule = workspace 3, ...`) auto-assign windows to workspaces

```conf
# All new Firefox windows go to workspace 2
windowrule = workspace 2, match:class ^(firefox)$

# Discord always on workspace 4
windowrule = workspace 4 silent, match:class ^(discord)$
```

## Tips

- Workspaces are created on demand — no need to pre-define them all
- On multi-monitor setups, each monitor maintains its own workspace list
- The `default:true` option sets the default workspace shown on boot
- DMS workspace renaming lets you give workspaces meaningful names at runtime
