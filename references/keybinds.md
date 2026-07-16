# Keybindings Reference

## Overview

Hyprland keybindings use a simple declarative syntax. Multiple bind
types are available for different behaviors (repeating, locked, etc.).

## Bind Types

| Keyword | Description |
|---|---|
| `bind` | Standard keybinding |
| `binde` | Repeats on hold (for resize, volume, etc.) |
| `bindl` | Works even when input is locked (for media keys) |
| `bindel` | Repeating + locked (for volume, brightness) |
| `bindr` | Triggers on key release instead of press |
| `bindm` | Mouse bind |
| `bindd` | Bind with description (shown in keybind viewer) |
| `bindmd` | Mouse bind with description |

Combine flags by using the combined keyword: `bindel` = bind + e (repeat) + l (locked).

## Syntax

```conf
bind = MODIFIERS, key, dispatcher, [params]
```

### Modifiers

| Modifier | Key |
|---|---|
| `SUPER` | Super/Windows/Meta key |
| `SHIFT` | Shift |
| `CTRL` | Control |
| `ALT` | Alt |
| `SUPER SHIFT` | Super + Shift |
| `SUPER CTRL` | Super + Ctrl |
| `SUPER ALT` | Super + Alt |

### Keys

- Letter keys: `A` through `Z` (case insensitive)
- Number keys: `0` through `9`
- Function keys: `F1` through `F12`
- Special: `Return`, `space`, `Tab`, `Escape`
- Arrow keys: `left`, `right`, `up`, `down`
- Page: `Page_Up`, `Page_Down`, `Home`, `End`
- Media: `XF86AudioRaiseVolume`, `XF86AudioLowerVolume`, `XF86AudioMute`,
  `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioNext`, `XF86AudioPrev`,
  `XF86MonBrightnessUp`, `XF86MonBrightnessDown`
- Other: `Print`, `Delete`, `Insert`, `minus`, `equal`, `bracketleft`, `bracketright`
- Keycode: `code:XX` (e.g., `code:20` for `-`)
- Mouse: `mouse:272` (LMB), `mouse:273` (RMB), `mouse:274` (MMB)
- Mouse wheel: `mouse_down`, `mouse_up`

## Common Dispatchers

### Window Management

```conf
bind = SUPER, Q, killactive                    # Close focused window
bind = SUPER, F, fullscreen, 1                 # Maximize (keep bar)
bind = SUPER SHIFT, F, fullscreen, 0           # True fullscreen
bind = SUPER SHIFT, T, togglefloating          # Toggle floating
bind = SUPER, W, togglegroup                   # Toggle window group
bind = SUPER, P, pseudo                        # Toggle pseudo-tile
bind = SUPER, R, layoutmsg, togglesplit        # Toggle split direction
```

### Focus

```conf
bind = SUPER, left, movefocus, l               # Focus left
bind = SUPER, right, movefocus, r              # Focus right
bind = SUPER, up, movefocus, u                 # Focus up
bind = SUPER, down, movefocus, d               # Focus down

# Vim-style
bind = SUPER, H, movefocus, l
bind = SUPER, J, movefocus, d
bind = SUPER, K, movefocus, u
bind = SUPER, L, movefocus, r
```

### Move Windows

```conf
bind = SUPER SHIFT, left, movewindow, l
bind = SUPER SHIFT, right, movewindow, r
bind = SUPER SHIFT, up, movewindow, u
bind = SUPER SHIFT, down, movewindow, d
```

### Resize

```conf
binde = SUPER, minus, resizeactive, -10% 0
binde = SUPER, equal, resizeactive, 10% 0
binde = SUPER SHIFT, minus, resizeactive, 0 -10%
binde = SUPER SHIFT, equal, resizeactive, 0 10%

# Mouse resize
bindm = SUPER, mouse:273, resizewindow
```

### Workspaces

```conf
# Switch
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
# ... etc

# Move window to workspace
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2

# Move silently (don't follow)
bind = SUPER ALT, 1, movetoworkspacesilent, 1

# Relative workspace
bind = SUPER, Page_Down, workspace, e+1
bind = SUPER, Page_Up, workspace, e-1

# Mouse wheel
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Special workspace (scratchpad)
bind = SUPER, S, togglespecialworkspace, magic
bind = SUPER SHIFT, S, movetoworkspace, special:magic
```

### Monitor Navigation

```conf
bind = SUPER CTRL, left, focusmonitor, l
bind = SUPER CTRL, right, focusmonitor, r

# Move window to monitor
bind = SUPER SHIFT CTRL, left, movewindow, mon:l
bind = SUPER SHIFT CTRL, right, movewindow, mon:r
```

### Application Launch

```conf
bind = SUPER, T, exec, kitty                  # Terminal
bind = SUPER, E, exec, nautilus                # File manager
bind = SUPER, B, exec, firefox                 # Browser
bind = SUPER, space, exec, rofi -show drun     # App launcher

# DMS launcher
bind = SUPER, space, exec, dms ipc call spotlight toggle
```

### System

```conf
bind = SUPER SHIFT, E, exit                    # Exit Hyprland
bind = SUPER ALT, L, exec, hyprlock            # Lock screen
bind = , Print, exec, grim -g "$(slurp)"       # Screenshot region
bind = SUPER SHIFT, P, dpms, toggle            # Toggle monitors
```

## Mouse Bindings

```conf
# Move window with Super + LMB
bindm = SUPER, mouse:272, movewindow
bindmd = SUPER, mouse:272, Move window, movewindow

# Resize with Super + RMB
bindm = SUPER, mouse:273, resizewindow
bindmd = SUPER, mouse:273, Resize window, resizewindow
```

## Described Bindings

Use `bindd` to add descriptions visible in keybind viewers:

```conf
bindd = SUPER, T, Open terminal, exec, kitty
bindd = SUPER, Q, Close window, killactive
bindd = SUPER, F, Maximize window, fullscreen, 1
```

## Submap (Modal Keybindings)

Create modal keybinding modes (like vim modes):

```conf
# Enter resize mode
bind = SUPER, R, submap, resize

# Resize submap
submap = resize
binde = , right, resizeactive, 10 0
binde = , left, resizeactive, -10 0
binde = , up, resizeactive, 0 -10
binde = , down, resizeactive, 0 10
bind = , Escape, submap, reset
bind = , Return, submap, reset
submap = reset
```

## DMS Keybinding Notes

In a DMS setup, keybindings are stored in `~/.config/hypr/dms/binds.conf`.
This file is user-editable — you can add, modify, or remove keybindings.

DMS keybindings use `dms ipc call` for shell-integrated features:

```conf
bind = SUPER, space, exec, dms ipc call spotlight toggle
bind = SUPER, V, exec, dms ipc call clipboard toggle
bind = SUPER, M, exec, dms ipc call processlist focusOrToggle
```

## Listing Active Bindings

```bash
# Show all active keybindings
hyprctl binds
```
