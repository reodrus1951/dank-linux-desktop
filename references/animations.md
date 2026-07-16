# Animations Reference

## Overview

Hyprland features a highly customizable, curve-driven animation system that runs
entirely on the GPU.

## Config Syntax

Animations are configured in the `animations` section of `hyprland.conf`:

```conf
animations {
    enabled = true

    # 1. Define Bezier Curves
    # bezier = name, x0, y0, x1, y1
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    # 2. Configure Animations
    # animation = target, enabled, speed, curve [, style]
    animation = windows, 1, 7, myBezier
}
```

### Bezier Curves

Curves are defined using cubic bezier points. You can define custom curves or
use the `default` curve.

Visualizer tool: https://cssportal.com/css-cubic-bezier-generator

### Animation Settings

- `target` — The element being animated (see list below)
- `enabled` — `1` (on) or `0` (off)
- `speed` — Duration in decaseconds (1 = 100ms, 5 = 500ms, 10 = 1000ms)
- `curve` — Bezier curve name or `default`
- `style` — Optional style parameter

## Animation Targets

| Name | What it animates | Available styles |
|---|---|---|
| `windows` | All window animations (general fallback) | `slide`, `popin <percent>` |
| `windowsIn` | Window open animation | `slide`, `popin <percent>` |
| `windowsOut` | Window close animation | `slide`, `popin <percent>` |
| `windowsMove` | Window movement/resize | `slide`, `popin <percent>` |
| `fade` | Opacity transitions | — |
| `fadeIn` | Fade in | — |
| `fadeOut` | Fade out | — |
| `fadeDim` | Inactive dimming fade | — |
| `fadeShadow` | Shadow fade | — |
| `fadeSwitch` | Focus switch fade | — |
| `fadeLayersIn` | Layer surface fade in | — |
| `fadeLayersOut` | Layer surface fade out | — |
| `border` | Border color transition | — |
| `borderangle` | Border gradient angle animation | `once`, `loop` |
| `workspaces` | Workspace switch animation | `slide`, `slidevert`, `fade`, `slidefade <percent>`, `slidefadevert <percent>` |
| `specialWorkspace` | Special workspace animation | Same as `workspaces` |
| `layers` | Layer surface animations | `slide`, `popin <percent>`, `fade` |

## Common Presets

### Fast and Snappy

```conf
animations {
    enabled = true
    bezier = snappy, 0.2, 0.9, 0.3, 1.0
    animation = windows, 1, 3, snappy
    animation = windowsOut, 1, 3, snappy, popin 80%
    animation = fade, 1, 3, snappy
    animation = workspaces, 1, 3, snappy
    animation = border, 1, 2, snappy
}
```

### Smooth and Elegant

```conf
animations {
    enabled = true
    bezier = smooth, 0.25, 0.1, 0.25, 1.0
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    animation = windows, 1, 6, smooth
    animation = windowsOut, 1, 4, smoothOut, popin 80%
    animation = fade, 1, 5, smooth
    animation = workspaces, 1, 6, smooth, slidefade 30%
    animation = border, 1, 5, smooth
}
```

### Bouncy

```conf
animations {
    enabled = true
    bezier = bounce, 0.68, -0.55, 0.265, 1.55
    animation = windows, 1, 5, bounce
    animation = windowsOut, 1, 5, bounce, popin 80%
    animation = fade, 1, 5, default
    animation = workspaces, 1, 5, bounce
}
```

### Minimal (subtle)

```conf
animations {
    enabled = true
    bezier = linear, 0, 0, 1, 1
    animation = windows, 1, 2, linear
    animation = windowsOut, 1, 2, linear, popin 90%
    animation = fade, 1, 2, linear
    animation = workspaces, 1, 2, linear, fade
    animation = border, 1, 1, linear
}
```

### Disabled

```conf
animations {
    enabled = false
}
```

## Animated Border

Create a rotating gradient border:

```conf
general {
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
}

animations {
    animation = borderangle, 1, 100, default, loop
}
```

## Performance Notes

- More `blur passes` + animations = more GPU load
- On NVIDIA: animations work well but may require `no_hardware_cursors = true`
- If experiencing lag: reduce animation speed, reduce blur passes
- `vfr = true` in `misc` helps reduce unnecessary frames
