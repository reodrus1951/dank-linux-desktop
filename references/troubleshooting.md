# Troubleshooting Reference

## Diagnostic Commands

### Quick Health Check

```bash
# Is Hyprland running?
hyprctl version

# Are critical services running?
systemctl --user is-active pipewire wireplumber dms

# Any failed services?
systemctl --user --failed

# Recent errors?
journalctl --user -p err --since "1 hour ago" --no-pager | tail -20
```

---

## Common Issues

### 1. Screen Flickering / Artifacts

**NVIDIA:**
```bash
# Check driver version
nvidia-smi

# Ensure correct env vars in hyprland.conf
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# Try disabling hardware cursors
# cursor { no_hardware_cursors = true }

# Check for kernel DRM errors
journalctl -b -k | grep -i nvidia | tail -10
```

**AMD:**
```bash
# Check mesa version
pacman -Qi mesa | grep Version

# Check DRM errors
journalctl -b -k | grep -i amdgpu | tail -10

# Force correct backend
# env = AMD_VULKAN_ICD,radv
```

### 2. Applications Crash on Startup

```bash
# Run the app from terminal to see errors
firefox 2>&1 | head -50

# Common fix: missing Wayland support
# Add to hyprland.conf:
# env = MOZ_ENABLE_WAYLAND,1         # Firefox
# env = ELECTRON_OZONE_PLATFORM_HINT,auto  # Electron apps

# For XWayland apps that crash:
# Check xwayland is running
pgrep Xwayland
```

### 3. Waybar Not Showing

```bash
# Check if running
pgrep waybar

# Start manually to see errors
waybar -l debug 2>&1 | head -30

# Common: JSON syntax error
# Validate config
cat ~/.config/waybar/config.jsonc | sed 's|//.*||' | python3 -c "import sys,json;json.load(sys.stdin)"

# Common: trailing comma in JSON
# JSONC allows comments but NOT trailing commas
```

### 4. No Sound

```bash
# Check PipeWire
systemctl --user status pipewire
systemctl --user status wireplumber

# Restart audio stack
systemctl --user restart pipewire wireplumber

# Check for sinks
pactl list sinks short

# If no sinks, check ALSA
aplay -l

# For HDMI audio on NVIDIA
pactl set-default-sink alsa_output.pci-0000_2b_00.1.hdmi-stereo
# (adjust sink name from pactl list sinks short)

# Reset PipeWire config
rm -rf ~/.config/pipewire/*
systemctl --user restart pipewire wireplumber
```

### 5. Bluetooth Not Working

```bash
# Check service
systemctl status bluetooth

# Start if stopped
sudo systemctl start bluetooth
sudo systemctl enable bluetooth

# Install blueman for GUI
sudo pacman -S blueman
blueman-manager &

# Reset Bluetooth
sudo rfkill unblock bluetooth
```

### 6. Keyboard Layout Not Applied

```bash
# Check current layout
hyprctl keyword input:kb_layout
# or
setxkbmap -query  # for XWayland apps

# Apply layout
hyprctl keyword input:kb_layout "us,es"
hyprctl keyword input:kb_variant "intl,"
hyprctl keyword input:kb_options "lv3:ralt_switch"

# Verify in config
grep kb_layout ~/.config/hypr/hyprland.conf
grep kb_layout ~/.config/hypr/dms/*.conf
```

### 7. Slow Performance / High GPU Usage

```bash
# Check GPU usage
nvidia-smi  # NVIDIA
# or
cat /sys/class/drm/card*/device/gpu_busy_percent  # AMD

# Reduce animations
# In hyprland.conf:
# animations { enabled = false }

# Reduce blur
# decoration { blur { passes = 1; size = 3 } }

# Enable VFR
# misc { vfr = true }

# Check for rogue processes
top -o %CPU | head -20
```

### 8. XWayland Apps Look Blurry

```bash
# This happens with fractional scaling
# Option 1: Force integer scaling
# monitor = DP-1, 2560x1440@280, 0x0, 1  # scale = 1 (not 1.5)

# Option 2: Force XWayland scaling
# In hyprland.conf:
# xwayland { force_zero_scaling = true }
# env = GDK_SCALE,2

# Option 3: Per-app scaling
# env = QT_SCALE_FACTOR,1.5
```

### 9. Hyprlock Won't Unlock

```bash
# Check PAM config
cat /etc/pam.d/hyprlock
# Should contain:
# auth include system-auth

# If missing, create it:
# sudo tee /etc/pam.d/hyprlock << 'EOF'
# auth include system-auth
# EOF

# If password not accepted, try:
# Kill hyprlock from TTY (Ctrl+Alt+F2)
killall hyprlock

# Check if password is correct
su - $(whoami)
```

### 10. DMS Shell Not Loading

```bash
# Check DMS service
systemctl --user status dms.service

# View DMS logs
journalctl --user -u dms.service -n 50

# Restart DMS
systemctl --user restart dms.service

# Check Quickshell
which quickshell
quickshell --version

# If DMS is broken, Hyprland still works
# You can use rofi as a fallback launcher:
# rofi -show drun
```

### 11. Monitor Not Detected

```bash
# Check connected outputs
hyprctl monitors all

# Check kernel DRM
journalctl -b -k | grep -i drm | tail -20

# Force scan for new outputs
hyprctl keyword monitor ", preferred, auto, auto"

# For NVIDIA: check nvidia-drm kernel module
lsmod | grep nvidia_drm
# If missing:
sudo modprobe nvidia_drm modeset=1
```

### 12. Cursor Missing or Corrupted

```bash
# NVIDIA: Use software cursors
# In hyprland.conf:
# cursor { no_hardware_cursors = true }

# Check cursor theme
gsettings get org.gnome.desktop.interface cursor-theme
grep CURSOR ~/.config/hypr/dms/cursor.conf

# Reset cursor
hyprctl keyword cursor:no_hardware_cursors true
hyprctl reload
```

---

## Log Locations

| Component | Log Command |
|---|---|
| Hyprland | `journalctl --user -u hyprland -n 50` or `/tmp/hypr/<signature>/hyprland.log` |
| DMS | `journalctl --user -u dms.service -n 50` |
| PipeWire | `journalctl --user -u pipewire -n 50` |
| WirePlumber | `journalctl --user -u wireplumber -n 50` |
| NVIDIA | `journalctl -b -k \| grep nvidia` |
| SDDM | `journalctl -u sddm -n 50` |
| NetworkManager | `journalctl -u NetworkManager -n 50` |
| System boot | `journalctl -b` |
| Previous boot | `journalctl -b -1` |

## Useful Debug Environment Variables

```bash
# Hyprland debug logging
HYPRLAND_LOG_WLR=1 Hyprland

# GTK debugging
GTK_DEBUG=interactive firefox

# Qt debugging
QT_DEBUG_PLUGINS=1 some-qt-app

# Wayland debugging
WAYLAND_DEBUG=1 some-app  # Very verbose!
```
