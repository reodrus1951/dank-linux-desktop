# Wallpaper Daemons Reference

## Hyprpaper

The default wallpaper daemon for Hyprland. Lightweight, supports per-monitor
wallpapers and IPC.

### Config File

`~/.config/hypr/hyprpaper.conf`

```conf
# Preload images into memory
preload = /path/to/wallpaper1.jpg
preload = /path/to/wallpaper2.png

# Assign wallpapers to monitors
wallpaper = DP-1, /path/to/wallpaper1.jpg
wallpaper = HDMI-A-1, /path/to/wallpaper2.png

# Default for unmatched monitors
wallpaper = , /path/to/default.jpg

# Settings
splash = false              # Disable splash text
ipc = on                    # Enable IPC for runtime changes
```

### IPC Commands

```bash
# Change wallpaper at runtime
hyprctl hyprpaper preload /path/to/new.jpg
hyprctl hyprpaper wallpaper "DP-1,/path/to/new.jpg"

# Unload unused images
hyprctl hyprpaper unload /path/to/old.jpg
hyprctl hyprpaper unload all
```

### Startup

```conf
# In hyprland.conf
exec-once = hyprpaper
```

---

## swww

Animated wallpaper daemon with transition effects. More feature-rich
than hyprpaper but heavier.

### Installation

```bash
paru -S swww
```

### Usage

```bash
# Start the daemon
swww-daemon &

# Set wallpaper with transition
swww img /path/to/wallpaper.jpg

# Transitions
swww img /path/to/wallpaper.jpg --transition-type wipe
swww img /path/to/wallpaper.jpg --transition-type grow --transition-pos center
swww img /path/to/wallpaper.jpg --transition-type fade --transition-duration 2

# Available transitions: simple, fade, left, right, top, bottom, wipe,
#                        wave, grow, center, any, outer, random

# Per-monitor
swww img /path/to/wallpaper.jpg -o DP-1

# Query current wallpaper
swww query
```

### Startup

```conf
# In hyprland.conf
exec-once = swww-daemon
exec-once = swww img /path/to/wallpaper.jpg
```

---

## swaybg

Simple static wallpaper setter. Lightest option, no IPC.

### Usage

```bash
# Solid color
swaybg -c '#1a1a2e'

# Image (fill mode)
swaybg -i /path/to/wallpaper.jpg -m fill

# Modes: stretch, fill, fit, center, tile
```

### Startup

```conf
exec-once = swaybg -i /path/to/wallpaper.jpg -m fill
```

---

## DMS Wallpaper

DMS includes its own wallpaper selector accessible via:

```bash
# Open wallpaper picker
dms ipc call dankdash wallpaper
# Or use keybind: SUPER + Y
```

DMS manages wallpapers through its own system. When using DMS,
prefer the built-in wallpaper management over external daemons.

---

## Choosing a Wallpaper Daemon

| Feature | hyprpaper | swww | swaybg | DMS |
|---|---|---|---|---|
| Weight | Light | Medium | Lightest | Integrated |
| Transitions | None | Yes (animated) | None | Via UI |
| IPC | Yes | Yes | No | Yes |
| Per-monitor | Yes | Yes | No | Yes |
| Animated wallpapers | No | GIF support | No | No |
| Recommended for DMS | No | No | No | **Yes** |

**Recommendation:** If using DMS, use the built-in wallpaper management.
If not using DMS, use hyprpaper for static or swww for animated transitions.
