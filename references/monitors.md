# Monitor Configuration Reference

## Overview

Monitor configuration in Hyprland controls resolution, refresh rate,
position, scaling, rotation, and advanced features like VRR and HDR.

## Syntax

```conf
monitor = name, resolution@rate, position, scale [, options...]
```

**Parameters:**
- `name` — Output name (e.g., `DP-1`, `HDMI-A-1`, `eDP-1`) or `desc:` prefix for
 description matching
- `resolution` — `WIDTHxHEIGHT` or `preferred` or `highres` or `highrr`
- `rate` — Refresh rate in Hz (e.g., `60`, `144`, `280`)
- `position` — `XxY` offset in pixels (e.g., `0x0`, `2560x0`) or `auto`
- `scale` — Display scaling factor (e.g., `1`, `1.5`, `2`)

## Finding Monitor Names

```bash
# List connected monitors
hyprctl monitors

# Output example:
# Monitor DP-1 (ID 0):
#     2560x1440@279.96100 at 0x0
#     description: ASUSTek COMPUTER INC XG27AQWMG W3LMTR017821
#     make: ASUSTek COMPUTER INC
#     model: XG27AQWMG

# List all available modes
hyprctl monitors all
```

## Configuration Examples

### Single Monitor

```conf
# Use preferred mode
monitor = DP-1, preferred, auto, 1

# Specific resolution and refresh rate
monitor = DP-1, 2560x1440@280, 0x0, 1

# HiDPI (4K with 2x scaling)
monitor = DP-1, 3840x2160@60, 0x0, 2
```

### Dual Monitor (Side by Side)

```conf
# Left monitor at position 0,0; right monitor offset by left monitor's width
monitor = DP-1, 2560x1440@280, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

### Dual Monitor (Stacked)

```conf
# Top monitor
monitor = DP-1, 2560x1440@144, 0x0, 1
# Bottom monitor (offset by top monitor's height)
monitor = DP-2, 2560x1440@60, 0x1440, 1
```

### Description-Based Matching

More reliable than output names (which can change between reboots):

```conf
monitor = desc:ASUSTek COMPUTER INC XG27AQWMG W3LMTR017821, 2560x1440@280, 0x0, 1
monitor = desc:LG Electronics LG ULTRAGEAR+, 2560x1440@240, 2560x0, 1
```

### Catch-All Fallback

Always include a fallback for unmatched monitors:

```conf
monitor = , preferred, auto, auto
```

## Advanced Options

Options are comma-separated after the scale parameter:

```conf
monitor = DP-1, 2560x1440@280, 0x0, 1, vrr, 1, bitdepth, 10, cm, dcip3
```

### VRR (Variable Refresh Rate / Adaptive Sync)

```conf
# vrr, 0  — Disabled
# vrr, 1  — Always on
# vrr, 2  — Only in fullscreen
```
