# Input Configuration Reference

## Overview

Input configuration controls keyboard layouts, mouse behavior, touchpad
settings, and input device customization in Hyprland.

## Keyboard

```conf
input {
    kb_layout = us                 # XKB layout (e.g., us, de, fr, es, latam)
    kb_variant = intl              # Layout variant (e.g., intl, dvorak, colemak)
    kb_model =                     # Keyboard model (usually empty)
    kb_options = lv3:ralt_switch   # XKB options (comma-separated)
    kb_rules =                     # XKB rules (usually empty)
    numlock_by_default = true      # Start with NumLock on
    resolve_binds_by_sym = false   # Resolve keybinds by symbol instead of keycode
    repeat_rate = 25               # Key repeat rate (keys per second)
    repeat_delay = 600             # Key repeat delay (ms before repeat starts)
}
```

### Common XKB Options

| Option | Description |
|---|---|
| `lv3:ralt_switch` | Right Alt for level 3 (accented chars) |
| `caps:escape` | Caps Lock as Escape |
| `caps:swapescape` | Swap Caps Lock and Escape |
| `caps:ctrl_modifier` | Caps Lock as Ctrl |
| `compose:ralt` | Right Alt as Compose |
| `grp:alt_shift_toggle` | Alt+Shift to switch layouts |
| `grp:win_space_toggle` | Super+Space to switch layouts |

### Multiple Keyboard Layouts

```conf
input {
    kb_layout = us,es,de
    kb_variant = intl,,
    kb_options = grp:alt_shift_toggle    # Alt+Shift to switch
}
```

## Mouse

```conf
input {
    sensitivity = 0.0              # Mouse sensitivity (-1.0 to 1.0, 0 = default)
    accel_profile = flat           # flat (no accel) or adaptive (accel)
    force_no_accel = false         # Force disable acceleration
    follow_mouse = 1               # Focus follows mouse
                                   # 0 = click to focus
                                   # 1 = focus follows mouse
                                   # 2 = strict follow (always changes focus)
                                   # 3 = focus follows mouse, doesn't refocus on click
    mouse_refocus = true           # Refocus on mouse enter (for follow_mouse > 0)
    float_switch_override_focus = 1 # Override focus for float/tile switch
    scroll_method = 2fg            # 2fg (two-finger), edge, on_button_down, no_scroll
    scroll_button = 0              # Button for on_button_down scroll
    natural_scroll = false         # Reverse scroll direction
}
```

## Touchpad

```conf
input {
    touchpad {
        natural_scroll = true      # Reverse scroll (natural for touchpads)
        disable_while_typing = true # Disable touchpad while typing
        tap-to-click = true        # Tap to click
        drag_lock = false          # Lock drag on lift
        scroll_factor = 1.0        # Scroll speed multiplier
        clickfinger_behavior = false # Use button positions instead of finger count
        middle_button_emulation = false # Middle click with 3 fingers
    }
}
```

## Per-Device Configuration

Override settings for specific input devices:

```conf
# Find device names
# hyprctl devices

device {
    name = logitech-g-pro-x-superlight-2
    sensitivity = -0.5
    accel_profile = flat
}

device {
    name = at-translated-set-2-keyboard
    kb_layout = es
    kb_variant =
}
```

### Finding Device Names

```bash
hyprctl devices
```

Output shows device names under "Keyboards:", "Mice:", "Tablets:", etc.

## Gestures (Touchpad)

```conf
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_min_speed_to_force = 30
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
    workspace_swipe_direction_lock = true
    workspace_swipe_forever = false
    workspace_swipe_use_r = false          # Use 'r' for right (inverted)
}
```

## Tablet Configuration

```conf
input {
    tablet {
        output = DP-1              # Map tablet to specific monitor
        region_position = 0 0      # Tablet active region position
        region_size = 0 0          # Tablet active region size (0 0 = full)
        relative_input = false     # Use relative instead of absolute input
        transform = 0              # Transform (rotation) 0-7
    }
}
```

## Troubleshooting

### Keyboard layout not working
- Verify layout exists: `localectl list-x11-keymap-layouts | grep <layout>`
- Check variants: `localectl list-x11-keymap-variants <layout>`
- Test in Hyprland: `hyprctl keyword input:kb_layout us,es`

### Mouse sensitivity wrong
- For gaming: use `accel_profile = flat` and `sensitivity = 0.0`
- If cursor feels sluggish: increase sensitivity or check if acceleration is enabled

### Touchpad not responding
- Check device is detected: `hyprctl devices`
- Verify libinput is working: `libinput list-devices`
