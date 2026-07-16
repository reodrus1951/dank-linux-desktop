# Hyprlock Reference

## Overview

Hyprlock is a screen locker for Hyprland. It supports background images,
input fields, labels, and animations — all rendered on the GPU.

## Config File

`~/.config/hypr/hyprlock.conf`

## Configuration

```conf
general {
    disable_loading_bar = false
    hide_cursor = true
    grace = 0                      # Grace period (seconds) before locking
    no_fade_in = false
    no_fade_out = false
    ignore_empty_input = false
}

# Background (one per monitor, or use wildcard)
background {
    monitor =                      # Empty = all monitors
    path = /path/to/wallpaper.png  # Or "screenshot" to use current screen
    blur_passes = 3
    blur_size = 8
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
    color = rgba(25, 20, 20, 1.0)  # Fallback if no image
}

# Input field (password)
input-field {
    monitor =
    size = 250, 50
    outline_thickness = 3
    dots_size = 0.33               # 0.0 - 1.0 relative to input height
    dots_spacing = 0.15
    dots_center = true
    dots_rounding = -1             # -1 = circle
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = true
    fade_timeout = 1000            # ms
    placeholder_text = <i>Password...</i>
    hide_input = false
    rounding = -1                  # -1 = follow decoration rounding
    check_color = rgb(204, 136, 34)
    fail_color = rgb(204, 34, 34)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    fail_transition = 300          # ms
    capslock_color = -1
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false

    position = 0, -20
    halign = center
    valign = center
}

# Labels (text overlays)
label {
    monitor =
    text = Hi there, $USER
    text_align = center
    color = rgba(200, 200, 200, 1.0)
    font_size = 25
    font_family = Fira Sans
    rotate = 0

    position = 0, 80
    halign = center
    valign = center
}

# Time label
label {
    monitor =
    text = cmd[update:1000] date +"%H:%M"
    color = rgba(200, 200, 200, 1.0)
    font_size = 64
    font_family = Fira Sans Bold

    position = 0, 200
    halign = center
    valign = center
}

# Date label
label {
    monitor =
    text = cmd[update:60000] date +"%A, %B %d"
    color = rgba(200, 200, 200, 0.8)
    font_size = 20
    font_family = Fira Sans

    position = 0, 130
    halign = center
    valign = center
}
```

## Variables

Available in text fields:
- `$USER` — username
- `$FAIL` — last failure message
- `$ATTEMPTS` — number of failed attempts
- `cmd[update:ms] command` — run command periodically

## Usage

```bash
# Lock screen
hyprlock

# Or via DMS
dms ipc call lock lock

# Or via keybind in Hyprland config
bind = SUPER ALT, L, exec, hyprlock
```

## Position and Alignment

- `position = x, y` — offset from alignment point
- `halign` — `left`, `center`, `right`
- `valign` — `top`, `center`, `bottom`

## Troubleshooting

- **Black screen:** Check `path` in background section, ensure image exists
- **Input field not showing:** Check `monitor` field, leave empty for all
- **PAM errors:** Check `/etc/pam.d/hyprlock` exists
