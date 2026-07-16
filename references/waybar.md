# Waybar Reference

## Overview

Waybar is a highly customizable Wayland status bar for wlroots-based compositors,
written in C++. It supports modular configuration, styling with CSS, and
custom scripts.

## Config Files

- **Config:** `~/.config/waybar/config.jsonc` (JSONC — JSON with comments)
- **Style:** `~/.config/waybar/style.css` (standard CSS)

Alternative config path: `~/.config/waybar/config` (plain JSON)

## Config Structure

```jsonc
{
    // Bar positioning
    "layer": "top",              // "top" or "bottom" (Wayland layer)
    "position": "top",           // "top", "bottom", "left", "right"
    "height": 35,                // Bar height in px (horizontal)
    "width": "",                 // Bar width in px (vertical)
    "spacing": 4,                // Spacing between modules
    "margin-top": 0,
    "margin-bottom": 0,
    "margin-left": 0,
    "margin-right": 0,
    "exclusive": true,           // Reserve screen space
    "passthrough": false,        // Click-through when not hovering
    "fixed-center": true,        // Center module is always centered
    "output": ["DP-1"],          // Limit to specific monitors (optional)

    // Module placement
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],

    // Module configurations (see below)
    "clock": { ... },
    "pulseaudio": { ... }
}
```

## Built-in Modules

### hyprland/workspaces

```jsonc
"hyprland/workspaces": {
    "format": "{id}",
    "format": "{name}: {icon}",           // Named workspaces
    "format-icons": {
        "1": "",
        "2": "",
        "urgent": "",
        "active": "",
        "default": ""
    },
    "on-click": "activate",
    "on-scroll-up": "hyprctl dispatch workspace e+1",
    "on-scroll-down": "hyprctl dispatch workspace e-1",
    "all-outputs": false,                  // Show all workspaces on all outputs
    "active-only": false,                  // Show only active workspace
    "sort-by-number": true,
    "persistent-workspaces": {
        "1": [], "2": [], "3": []          // Always show these workspaces
    }
}
```

### hyprland/window

```jsonc
"hyprland/window": {
    "format": "{}",
    "max-length": 50,
    "separate-outputs": true              // Show window for each output
}
```

### clock

```jsonc
"clock": {
    "format": "{:%H:%M}",
    "format-alt": "{:%A, %B %d, %Y}",    // Alt format on click
    "tooltip-format": "<tt>{calendar}</tt>",
    "calendar": {
        "mode": "month",
        "weeks-pos": "left",
        "format": {
            "months": "<span color='#ffead3'><b>{}</b></span>",
            "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
            "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
        }
    }
}
```

### pulseaudio

```jsonc
"pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "🔇 Muted",
    "format-icons": {
        "default": ["🔈", "🔉", "🔊"],
        "headphones": "🎧",
        "headset": "🖳",
        "speaker": "🔊"
    },
    "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
    "on-click-right": "pavucontrol",
    "on-scroll-up": "pactl set-sink-volume @DEFAULT_SINK@ +5%",
    "on-scroll-down": "pactl set-sink-volume @DEFAULT_SINK@ -5%",
    "scroll-step": 5,
    "max-volume": 150
}
```

### network

```jsonc
"network": {
    "format-wifi": "{icon} {essid}",
    "format-ethernet": "🔌 {ipaddr}",
    "format-disconnected": "⚠ Disconnected",
    "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}\n{bandwidthUpBits} ↑ {bandwidthDownBits} ↓",
    "tooltip-format-ethernet": "{ifname}\n{ipaddr}/{cidr}\n{bandwidthUpBits} ↑ {bandwidthDownBits} ↓",
    "on-click": "nm-connection-editor",
    "interval": 5
}
```

### battery

```jsonc
"battery": {
    "format": "{icon} {capacity}%",
    "format-charging": "🔌 {capacity}%",
    "format-plugged": "🔌 {capacity}%",
    "format-full": "🔋 Full",
    "format-icons": ["󰂎", "󰁺", "󰁽", "󰁿", "󰂁", "󰁹"],
    "states": {
        "good": 80,
        "warning": 30,
        "critical": 15
    },
    "tooltip-format": "{timeTo}\n{power}W"
}
```

### cpu / memory / disk

```jsonc
"cpu": {
    "format": " {usage}%",
    "interval": 2,
    "tooltip": true
},
"memory": {
    "format": " {used:0.1f}G / {total:0.1f}G",
    "interval": 5,
    "tooltip-format": "{used:0.2f}G / {total:0.2f}G ({percentage}%)"
},
"disk": {
    "format": " {percentage_used}%",
    "path": "/",
    "interval": 30,
    "tooltip-format": "{used} / {total} ({percentage_free}% free)"
}
```

### tray

```jsonc
"tray": {
    "icon-size": 21,
    "spacing": 8,
    "show-passive-items": false
}
```

### custom module

```jsonc
"custom/mymodule": {
    "exec": "/path/to/script.sh",
    "return-type": "json",             // or "" for plain text
    "format": "{} {icon}",
    "format-icons": {
        "default": "🔹"
    },
    "on-click": "/path/to/click-handler.sh",
    "on-click-right": "/path/to/right-click.sh",
    "on-scroll-up": "/path/to/scroll-up.sh",
    "on-scroll-down": "/path/to/scroll-down.sh",
    "interval": 10,                    // Run every N seconds
    "exec-on-event": true,             // Re-run on click events
    "tooltip": true
}
```

**JSON return format:**
```json
{"text": "displayed text", "tooltip": "hover text", "class": "css-class", "alt": "icon-key", "percentage": 50}
```

## CSS Styling

Waybar uses GTK CSS. Key selectors:

```css
/* Whole bar */
window#waybar {
    background: rgba(0, 0, 0, 0.8);
    color: #ffffff;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 13px;
}

/* All modules */
#workspaces, #clock, #battery, #cpu, #memory, #network, #pulseaudio, #tray {
    padding: 0 10px;
    margin: 3px 2px;
    border-radius: 8px;
}

/* Workspace buttons */
#workspaces button {
    padding: 0 5px;
    color: #888888;
    border: none;
    border-radius: 6px;
    background: transparent;
}

#workspaces button.active {
    color: #ffffff;
    background: rgba(255, 255, 255, 0.15);
}

#workspaces button.urgent {
    color: #ff0000;
}

/* Battery states (from config "states") */
#battery.good { color: #26A65B; }
#battery.warning { color: #f39c12; }
#battery.critical { color: #e74c3c; }

/* Tooltip */
tooltip {
    background: rgba(0, 0, 0, 0.9);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
}

tooltip label {
    color: #ffffff;
}
```

## Reload

Waybar does not support hot-reload. Restart it:

```bash
killall waybar
waybar &
```

Or as a one-liner:
```bash
killall waybar; waybar & disown
```

## Multiple Bars

Use an array in the config to define multiple bars:

```jsonc
[
    {
        "position": "top",
        "modules-left": ["hyprland/workspaces"],
        "modules-right": ["clock"]
    },
    {
        "position": "bottom",
        "modules-center": ["cpu", "memory"]
    }
]
```

## Troubleshooting

### Waybar won't start
1. Validate JSON: `cat config.jsonc | sed 's|//.*||' | python3 -c "import sys,json;json.load(sys.stdin)"`
2. Check for trailing commas in JSON
3. Run in foreground: `waybar -l debug`

### Icons not showing
- Install a Nerd Font: `sudo pacman -S ttf-jetbrains-mono-nerd`
- Set the font in CSS: `font-family: "JetBrainsMono Nerd Font"`

### Modules not updating
- Check `interval` setting
- For custom modules, verify script is executable and returns valid output
