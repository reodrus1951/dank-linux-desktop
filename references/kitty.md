# Kitty Terminal Reference

## Overview

Kitty is a fast, feature-rich, GPU-based terminal emulator. It supports
ligatures, images, true color, and is highly customizable.

## Config File

`~/.config/kitty/kitty.conf`

Config uses `key value` syntax (space-separated, NOT `key = value`).

## Key Settings

```conf
# Font
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# Cursor
cursor_shape          beam
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Mouse
copy_on_select        clipboard
mouse_hide_wait       3.0
url_style             curly
open_url_with         default
detect_urls           yes

# Performance
repaint_delay    10
input_delay      3
sync_to_monitor  yes

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Window
remember_window_size  yes
initial_window_width  120c
initial_window_height 35c
window_padding_width  8
hide_window_decorations yes
confirm_os_window_close 0

# Tab bar
tab_bar_edge          bottom
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    "{index}: {title}"
active_tab_font_style bold

# Colors — use a theme file
include current-theme.conf

# Background opacity
background_opacity 0.95

# Shell
shell .

# Advanced
allow_remote_control yes
listen_on            unix:/tmp/kitty-{kitty_pid}
```

## Themes

```bash
# List available themes
kitty +kitten themes

# Set a theme (interactive)
kitty +kitten themes

# Or set manually in config:
# include current-theme.conf
```

## Key Bindings

```conf
# Format: map key action
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+enter new_window
map ctrl+shift+w close_window
map ctrl+shift+f5 load_config_file
map ctrl+shift+equal change_font_size all +2.0
map ctrl+shift+minus change_font_size all -2.0
map ctrl+shift+backspace change_font_size all 0
```

## Reload

Kitty reloads config on `SIGUSR1`:
```bash
pkill -USR1 kitty
```

Or use `Ctrl+Shift+F5` from within Kitty.

## Troubleshooting

- **Slow rendering:** Check `sync_to_monitor`, try `repaint_delay 8`
- **Missing glyphs:** Install a Nerd Font, set `symbol_map` for specific ranges
- **Transparency not working on Wayland:** Set `background_opacity` and ensure
  compositor supports it (Hyprland does)
