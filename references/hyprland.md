# Hyprland Configuration Reference

## Overview

Hyprland is a dynamic tiling Wayland compositor written in C++. It provides
animations, rounded corners, blur, and extensive customization through a
text-based configuration file.

**Official Wiki:** https://wiki.hyprland.org

## Configuration File

The main configuration file is `~/.config/hypr/hyprland.conf`.

Hyprland supports modular configs via the `source` directive:
```conf
source = ./path/to/other.conf
source = ~/.config/hypr/keybinds.conf
source = ./modules/*.conf          # glob patterns supported
```

### Config Syntax

```conf
# Comments start with #
keyword = value
$variable = value              # Variable declaration
keyword = $variable            # Variable usage

section {
    keyword = value
    subsection {
        keyword = value
    }
}
```

**Important rules:**
- Settings are processed top-to-bottom; later values override earlier ones
- No quotes needed around values (unless the value contains special chars)
- Booleans: `true`/`false` or `yes`/`no` or `1`/`0`
- Colors: `rgba(RRGGBBAA)`, `rgb(RRGGBB)`, `0xAARRGGBB`

## Sections Reference

### general

Controls global window behavior and layout.

```conf
general {
    gaps_in = 5                    # Gap between windows (px)
    gaps_out = 10                  # Gap between windows and screen edge (px)
    border_size = 2                # Window border width (px)
    col.active_border = rgba(33ccffee)    # Active window border color
    col.inactive_border = rgba(595959aa)  # Inactive window border color
    layout = dwindle               # Layout algorithm: dwindle or master
    resize_on_border = true        # Allow resize by dragging border
    no_focus_fallback = false      # Don't fall back focus to another window
    allow_tearing = false          # Allow tearing for specific windows
}
```

### decoration

Visual appearance of windows.

```conf
decoration {
    rounding = 10                  # Corner radius (px)
    active_opacity = 1.0           # Active window opacity (0.0 - 1.0)
    inactive_opacity = 0.95        # Inactive window opacity
    fullscreen_opacity = 1.0       # Fullscreen window opacity
    dim_inactive = false           # Dim inactive windows
    dim_strength = 0.5             # Dimming strength (0.0 - 1.0)

    blur {
        enabled = true
        size = 5                   # Blur kernel size (odd number, 1-15)
        passes = 2                 # Number of blur passes (1-4)
        noise = 0.0117             # Noise amount (0.0 - 1.0)
        contrast = 0.8916          # Contrast (0.0 - 2.0)
        brightness = 0.8172        # Brightness (0.0 - 2.0)
        vibrancy = 0.1696          # Vibrancy (0.0 - 1.0)
        vibrancy_darkness = 0.0    # Vibrancy in dark areas
        new_optimizations = true   # Use new blur optimizations
        xray = false               # Blur behind all windows, not just behind focused
        ignore_opacity = false     # Ignore window opacity for blur
        special = false            # Blur on special workspace
        popups = false             # Blur popups
    }

    shadow {
        enabled = true
        range = 20                 # Shadow range (px)
        render_power = 3           # Shadow falloff (1 = linear, 4 = steep)
        offset = 0 2               # Shadow offset x y
        color = rgba(1a1a1aee)     # Shadow color
        color_inactive = unset     # Shadow color for inactive windows
        sharp = false              # Sharp shadows (no blur)
    }
}
```

### animations

Control window and workspace animations.

```conf
animations {
    enabled = true

    # Define custom bezier curves
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = easeOut, 0.16, 1, 0.3, 1
    bezier = easeIn, 0.5, 0, 0.75, 0

    # Animation format: name, enabled, speed (in ds = 100ms), curve [, style]
    animation = windows, 1, 5, myBezier
    animation = windowsIn, 1, 5, myBezier, slide
    animation = windowsOut, 1, 5, default, popin 80%
    animation = windowsMove, 1, 5, default
    animation = fade, 1, 5, default
    animation = border, 1, 3, default
    animation = borderangle, 1, 8, default
    animation = workspaces, 1, 5, default
    animation = specialWorkspace, 1, 5, default, slidevert
}
```

**Speed:** Measured in decaseconds (100ms units). Speed 5 = 500ms.

**Built-in styles:** `slide`, `popin <percent>`, `slidevert`, `slidefade <percent>`, `fade`

### input

Keyboard, mouse, and touchpad configuration.

```conf
input {
    kb_layout = us                 # Keyboard layout
    kb_variant = intl              # Keyboard variant
    kb_model =                     # Keyboard model
    kb_options = lv3:ralt_switch   # XKB options
    kb_rules =                     # XKB rules
    numlock_by_default = true      # Enable numlock on start
    repeat_rate = 25               # Key repeat rate (keys/sec)
    repeat_delay = 600             # Key repeat delay (ms)
    sensitivity = 0.0              # Mouse sensitivity (-1.0 to 1.0)
    accel_profile = flat           # flat or adaptive
    follow_mouse = 1               # Focus follows mouse (0=off, 1=on, 2=strict)
    natural_scroll = false         # Reverse scroll direction

    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
        drag_lock = false
        scroll_factor = 1.0
    }
}
```

### misc

Miscellaneous settings.

```conf
misc {
    disable_hyprland_logo = true        # Disable the anime wallpaper
    disable_splash_rendering = true     # Disable splash text
    force_default_wallpaper = 0         # 0 = no default wallpaper
    vfr = true                          # Variable frame rate (saves power)
    vrr = 0                             # Variable refresh rate (0=off, 1=on, 2=fullscreen only)
    mouse_move_enables_dpms = true      # Mouse movement wakes monitor
    key_press_enables_dpms = true       # Keypress wakes monitor
    animate_manual_resizes = false      # Animate manual window resizes
    animate_mouse_windowdragging = false # Animate mouse window dragging
    enable_swallow = false              # Enable window swallowing
    swallow_regex = ^(kitty)$           # Regex for swallowing window class
    focus_on_activate = false           # Focus window on activate request
    new_window_takes_over_fullscreen = 2 # 0=behind, 1=takes over, 2=unfullscreen
}
```

### dwindle

Dwindle layout settings.

```conf
dwindle {
    pseudotile = false             # Enable pseudo-tiling
    preserve_split = true          # Keep split direction on window close
    force_split = 0                # 0=follow mouse, 1=left, 2=right
    smart_split = false            # Smart split based on cursor position
    smart_resizing = true          # Smart resize direction
    no_gaps_when_only = 0          # 0=off, 1=no gaps with single window, 2=also no border
}
```

### master

Master layout settings.

```conf
master {
    mfact = 0.55                   # Master window width factor (0.0-1.0)
    new_on_top = false             # New windows on top of stack
    orientation = left             # Master window position: left, right, top, bottom, center
    always_center_master = false   # Center master window in 'center' orientation
    smart_resizing = true          # Smart resize direction
    no_gaps_when_only = 0          # Same as dwindle
}
```

### cursor

Cursor settings (Hyprland v0.40+).

```conf
cursor {
    no_hardware_cursors = false    # Use software cursors (set true for NVIDIA)
    hotspot_padding = 1            # Padding around cursor hotspot
    inactive_timeout = 0           # Hide cursor after N seconds of inactivity (0=never)
    no_warps = false               # Don't warp cursor on focus change
    enable_hyprcursor = true       # Use hyprcursor library
    default_monitor =              # Default monitor for cursor on startup
}
```

**NVIDIA note:** Set `no_hardware_cursors = true` if cursor appears corrupted
or has wrong colors (especially in HDR mode).

### Environment Variables

```conf
env = XCURSOR_SIZE, 24
env = XCURSOR_THEME, Adwaita
env = HYPRCURSOR_SIZE, 24
env = HYPRCURSOR_THEME, Adwaita
env = QT_QPA_PLATFORMTHEME, qt6ct
env = QT_QPA_PLATFORM, wayland;xcb
env = GDK_BACKEND, wayland,x11,*
env = SDL_VIDEODRIVER, wayland
env = CLUTTER_BACKEND, wayland
env = MOZ_ENABLE_WAYLAND, 1
env = ELECTRON_OZONE_PLATFORM_HINT, auto

# NVIDIA-specific
env = LIBVA_DRIVER_NAME, nvidia
env = __GLX_VENDOR_LIBRARY_NAME, nvidia
env = NVD_BACKEND, direct
env = GBM_BACKEND, nvidia-drm      # May cause issues, use if needed
```

### Startup Applications

```conf
exec-once = dbus-update-activation-environment --systemd --all
exec-once = systemctl --user start hyprland-session.target
exec-once = waybar
exec-once = hyprpaper
exec-once = hypridle

# exec = runs on every config reload (not just once)
exec = notify-send "Config reloaded"
```

## hyprctl Commands

`hyprctl` is the IPC tool for querying and controlling Hyprland:

```bash
# Information
hyprctl version                    # Hyprland version
hyprctl monitors                   # Monitor info
hyprctl workspaces                 # Workspace info
hyprctl activewindow               # Active window info
hyprctl clients                    # All windows
hyprctl binds                      # All keybindings
hyprctl systeminfo                 # Full system info

# Actions
hyprctl reload                     # Reload config
hyprctl dispatch exec kitty        # Execute command
hyprctl dispatch workspace 3       # Switch workspace
hyprctl dispatch killactive        # Kill active window
hyprctl dispatch togglefloating    # Toggle floating
hyprctl dispatch fullscreen 1      # Toggle fullscreen

# Settings
hyprctl keyword general:gaps_in 10        # Change setting at runtime
hyprctl keyword decoration:rounding 15    # Change setting at runtime
hyprctl keyword monitor DP-1,disable      # Disable monitor

# Batch mode
hyprctl --batch "keyword general:gaps_in 10; keyword general:gaps_out 20"
```

## Multiple Monitor Setup

```conf
# Format: monitor = name, resolution@rate, position, scale [, options]
monitor = DP-1, 2560x1440@280, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1

# Options:
# vrr, 0|1|2                  Variable refresh rate
# bitdepth, 8|10              Bit depth
# cm, srgb|dcip3              Color management
# mirror, <name>              Mirror another monitor
# transform, 0-7              Rotation/flip

# Fallback for any unmatched monitor
monitor = , preferred, auto, auto
```

## Plugin System

Hyprland supports plugins loaded as shared libraries:

```conf
# Load a plugin
plugin = /path/to/plugin.so

# Or use hyprctl
# hyprctl plugin load /path/to/plugin.so
```

Check loaded plugins: `hyprctl plugin list`
