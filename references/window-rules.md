# Window Rules Reference

## Overview

Window rules allow you to apply automatic behavior to windows based on
their class, title, or other properties. Hyprland v0.40+ uses a new
unified `windowrule` syntax with match filters.

## Modern Syntax (v0.40+)

```conf
windowrule = <action> [value], match:<field> <regex> [, match:<field> <regex>]
```

### Match Fields

| Field | Description | Example |
|---|---|---|
| `class` | Window class (WM_CLASS) | `match:class ^(firefox)$` |
| `title` | Window title | `match:title ^(Settings)$` |
| `initialclass` | Initial class (at creation) | `match:initialclass ^(steam)$` |
| `initialtitle` | Initial title (at creation) | `match:initialtitle ^(Sign In)$` |
| `tag` | Window tag | `match:tag ^(mytag)$` |
| `floating` | Is floating (0/1) | `match:floating 1` |
| `fullscreen` | Is fullscreen (0/1) | `match:fullscreen 1` |
| `pinned` | Is pinned (0/1) | `match:pinned 1` |
| `focus` | Is focused (0/1) | `match:focus 1` |
| `workspace` | Workspace ID | `match:workspace 3` |
| `onworkspace` | On workspace | `match:onworkspace w[t1]` |

### Combining Matches (AND)

Multiple `match:` filters in a single rule are AND-combined:

```conf
# Match steam windows with "notification" in title
windowrule = float on, match:class ^(steam)$, match:title ^(notificationtoasts)
```

## Actions

### Layout Actions

```conf
# Float the window
windowrule = float on, match:class ^(pavucontrol)$

# Force tile
windowrule = tile on, match:class ^(firefox)$

# Pin window (stays on all workspaces)
windowrule = pin on, match:class ^(picture-in-picture)$

# Fullscreen
windowrule = fullscreen on, match:class ^(game)$

# Center floating windows
windowrule = center on, match:float 1

# Set window size
windowrule = size 800 600, match:class ^(calculator)$

# Set min/max size
windowrule = minsize 400 300, match:class ^(dialog)$
windowrule = maxsize 1200 900, match:class ^(settings)$

# Move to position
windowrule = move 100 100, match:class ^(sticky-note)$

# Move to workspace
windowrule = workspace 3, match:class ^(discord)$
windowrule = workspace 4 silent, match:class ^(spotify)$
```

### Visual Actions

```conf
# Window opacity (active inactive)
windowrule = opacity 0.9, match:class ^(kitty)$
windowrule = opacity 1.0 0.85, match:class ^(Code)$

# Corner rounding
windowrule = rounding 12, match:class ^(org\.gnome\.)

# Border color
windowrule = bordercolor rgb(ff0000), match:class ^(urgent-app)$

# Border size
windowrule = bordersize 3, match:class ^(focused-app)$

# Shadow
windowrule = noshadow on, match:class ^(dropdown)$

# Blur
windowrule = noblur on, match:class ^(terminal)$

# Dim
windowrule = nodim on, match:class ^(video-player)$
```

### Focus Actions

```conf
# Don't focus on creation
windowrule = no_initial_focus on, match:class ^(steam)$, match:title ^(notificationtoasts)

# Suppress window activate requests
windowrule = suppressevent activate, match:class ^(steam)$

# Focus on creation
windowrule = stayfocused on, match:class ^(rofi)$
```

### Animation Actions

```conf
# Custom animation style
windowrule = animation popin, match:class ^(rofi)$
windowrule = animation slide, match:title ^(dropdown)$

# No animation
windowrule = noanim on, match:class ^(flameshot)$
```

### Special Actions

```conf
# Force XWayland (if needed)
windowrule = xwayland on, match:class ^(legacy-app)$

# Keep window proportions
windowrule = keepaspectratio on, match:class ^(mpv)$

# Tearing (for gaming)
windowrule = immediate on, match:class ^(cs2)$

# Set window group
windowrule = group set, match:class ^(terminal)$

# Disable idle inhibitor
windowrule = idleinhibit none, match:class ^(game)$
# Enable idle inhibitor
windowrule = idleinhibit always, match:class ^(video-player)$
# Only when fullscreen
windowrule = idleinhibit fullscreen, match:class ^(firefox)$
```

## Layer Rules

For layer surfaces (panels, overlays, notifications):

```conf
# layerrule = <action> [value], match:namespace <regex>
layerrule = no_anim on, match:namespace ^(quickshell)$
layerrule = no_anim on, match:namespace ^dms:.*
layerrule = blur on, match:namespace ^(waybar)$
layerrule = ignorezero on, match:namespace ^(waybar)$
layerrule = noanim on, match:namespace ^(notifications)$
```

## Finding Window Class and Title

```bash
# Get active window info
hyprctl activewindow

# List all windows
hyprctl clients

# Interactive: click a window to get its class
# (read the "class" field from hyprctl clients output)
```

## Common Window Rule Patterns

### Floating dialogs
```conf
windowrule = float on, match:class ^(org\.gnome\.Calculator)$
windowrule = float on, match:class ^(pavucontrol)$
windowrule = float on, match:class ^(blueman-manager)$
windowrule = float on, match:class ^(nm-connection-editor)$
windowrule = float on, match:class ^(xdg-desktop-portal)$
```

### Picture-in-Picture
```conf
windowrule = float on, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$
windowrule = pin on, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$
windowrule = size 480 270, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$
windowrule = move 100%-490 100%-280, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$
```

### Gaming
```conf
windowrule = fullscreen on, match:class ^(gamescope)$
windowrule = immediate on, match:class ^(gamescope)$
windowrule = idleinhibit always, match:class ^(gamescope)$
```

### Steam notifications (non-intrusive)
```conf
windowrule = no_initial_focus on, match:class ^(steam)$, match:title ^(notificationtoasts)
windowrule = pin on, match:class ^(steam)$, match:title ^(notificationtoasts)
```

## DMS Window Rules

In a DMS setup, DMS manages some window rules through its panel
(`SUPER + Shift + W`). These are stored in `~/.config/hypr/dms/windowrules.conf`.

User-defined window rules should go in the main `hyprland.conf`, preferably
before the `source` lines for DMS.
