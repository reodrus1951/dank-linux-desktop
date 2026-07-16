# Hypridle Reference

## Overview

Hypridle is an idle daemon for Hyprland. It can trigger actions after
specified periods of inactivity — typically dimming the screen, locking,
and eventually turning off monitors.

## Config File

`~/.config/hypr/hypridle.conf`

## Configuration

```conf
general {
    lock_cmd = pidof hyprlock || hyprlock          # Avoid multiple instances
    before_sleep_cmd = loginctl lock-session        # Lock before suspend
    after_sleep_cmd = hyprctl dispatch dpms on      # Turn on monitors after wake
    ignore_dbus_inhibit = false                     # Respect inhibit signals
    ignore_systemd_inhibit = false                  # Respect systemd inhibit
}

# Dim screen after 2.5 minutes
listener {
    timeout = 150                                   # seconds
    on-timeout = brightnessctl -s set 10            # Dim
    on-resume = brightnessctl -r                    # Restore brightness
}

# Lock screen after 5 minutes
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

# Turn off monitors after 5.5 minutes
listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

# Suspend after 30 minutes
listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
```

## How It Works

- Listeners trigger when the user is idle for `timeout` seconds
- `on-timeout` runs the specified command
- `on-resume` runs when user activity is detected again
- Multiple listeners can be defined; they are independent
- Each listener tracks its own timeout independently

## Common Patterns

### Desktop (no battery)
For desktops, you typically don't want to suspend:

```conf
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Lock after 10 minutes
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

# Monitors off after 15 minutes
listener {
    timeout = 900
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

### Laptop (battery conscious)
```conf
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 120
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 600
    on-timeout = systemctl suspend
}
```

## Running

```bash
# Start (usually via exec-once in hyprland.conf)
exec-once = hypridle

# Or manually
hypridle &
```

## Troubleshooting

- **Not locking:** Check `loginctl lock-session` works manually
- **Not dimming:** Check `brightnessctl` is installed and working
- **Inhibited:** Media players and video calls inhibit idle via D-Bus;
  check with `systemd-inhibit --list`
