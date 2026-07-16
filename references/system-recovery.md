# System Recovery Reference

## Overview

Recovery procedures for when the desktop is broken, unresponsive, or
misconfigured. Covers everything from minor config issues to unbootable
systems.

## Recovery Levels

| Level | Symptom | Recovery Method |
|---|---|---|
| 1 - Minor | Visual glitch, wrong setting | Reload config |
| 2 - Moderate | Waybar crashed, notifications gone | Restart component |
| 3 - Serious | Hyprland config broken, desktop glitching | Restore backup |
| 4 - Critical | Desktop won't start, black screen | TTY recovery |
| 5 - Severe | System won't boot | Boot media recovery |

---

## Level 1: Reload Config

```bash
# Reload Hyprland config
hyprctl reload

# Restart Waybar
killall waybar; waybar & disown

# Restart DMS
systemctl --user restart dms.service

# Restart audio
systemctl --user restart pipewire.service wireplumber.service
```

---

## Level 2: Restart Component

```bash
# If Waybar is missing
killall -9 waybar 2>/dev/null; sleep 1; waybar & disown

# If notifications stopped
killall -9 mako 2>/dev/null; mako & disown
# or
makoctl reload

# If DMS shell is broken
systemctl --user restart dms.service

# If clipboard stopped working
# DMS manages clipboard; restart DMS
systemctl --user restart dms.service

# If audio is broken
systemctl --user restart pipewire.service
systemctl --user restart wireplumber.service
# Verify
pactl info
```

---

## Level 3: Restore Backup

When a config change broke something and you need to roll back:

```bash
# List available backups
scripts/backup.sh --list ~/.config/hypr/hyprland.conf

# Preview what would be restored
scripts/restore.sh --preview ~/.config/hypr/hyprland.conf

# Restore most recent backup
scripts/restore.sh ~/.config/hypr/hyprland.conf

# Restore specific backup
scripts/restore.sh ~/.config/hypr/hyprland.conf 2026-07-02_13-45-30

# Reload after restore
hyprctl reload
```

For Waybar:
```bash
scripts/restore.sh ~/.config/waybar/config.jsonc
killall waybar; waybar & disown
```

---

## Level 4: TTY Recovery

When the desktop is unresponsive but the system is running:

### Step 1: Switch to TTY

Press `Ctrl+Alt+F2` (or F3, F4, etc.) to switch to a text console.

### Step 2: Log In

Enter your username and password.

### Step 3: Fix the Configuration

```bash
# Go to config directory
cd ~/.config/hypr

# Check what changed
diff .backups/hyprland.conf.$(ls -t .backups/ | head -1 | sed 's/hyprland.conf.//') hyprland.conf

# Restore from backup
cp .backups/hyprland.conf.$(ls -t .backups/hyprland.conf.* | head -1 | sed 's|.*/hyprland.conf.||') hyprland.conf

# Or use a known-good minimal config
cat > /tmp/hyprland-safe.conf << 'EOF'
monitor = , preferred, auto, auto
input {
    kb_layout = us
}
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    layout = dwindle
}
decoration {
    rounding = 10
}
bind = SUPER, T, exec, kitty
bind = SUPER, Q, killactive
bind = SUPER SHIFT, E, exit
exec-once = waybar
EOF

cp /tmp/hyprland-safe.conf ~/.config/hypr/hyprland.conf
```

### Step 4: Return to Desktop

```bash
# Option A: Reload if Hyprland is still running
hyprctl reload

# Option B: Restart the display manager
sudo systemctl restart sddm.service
# (This will start a new Hyprland session)
```

Press `Ctrl+Alt+F1` (or F7) to return to the graphical session.

---

## Level 5: Boot Media Recovery

When the system won't boot at all:

### Step 1: Boot from Live USB

Boot from a CachyOS or Arch Linux live USB.

### Step 2: Mount the Root Filesystem

```bash
# Find your partition
lsblk

# Mount root
sudo mount /dev/sdXn /mnt

# If separate /boot partition
sudo mount /dev/sdXm /mnt/boot

# Mount necessary filesystems
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /dev /mnt/dev
```

### Step 3: Chroot

```bash
sudo chroot /mnt /bin/bash
```

### Step 4: Fix the Issue

```bash
# Rebuild initramfs (common fix for NVIDIA issues after kernel update)
mkinitcpio -P

# Reinstall bootloader (systemd-boot)
bootctl install

# Fix pacman
pacman -Syu

# Fix NVIDIA packages
pacman -S nvidia-dkms nvidia-utils

# Fix broken packages
pacman -Qkk 2>&1 | grep -v '0 altered'
pacman -S $(pacman -Qkk 2>&1 | grep 'altered' | awk '{print $2}' | sort -u)
```

### Step 5: Unmount and Reboot

```bash
exit  # Exit chroot
sudo umount -R /mnt
sudo reboot
```

---

## Common Recovery Scenarios

### Black Screen After NVIDIA Driver Update

```bash
# From TTY (Ctrl+Alt+F2):
sudo mkinitcpio -P
sudo reboot

# If still black, check driver
lsmod | grep nvidia
dmesg | grep -i nvidia

# Reinstall NVIDIA packages
sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils
sudo mkinitcpio -P
```

### Hyprland Crashes on Startup

```bash
# From TTY:
# Check Hyprland logs
journalctl --user -u hyprland -n 50

# Start Hyprland manually to see errors
Hyprland 2>&1 | tee /tmp/hyprland.log

# Use minimal config
cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.broken
cat > ~/.config/hypr/hyprland.conf << 'EOF'
monitor = , preferred, auto, auto
bind = SUPER, T, exec, kitty
bind = SUPER SHIFT, E, exit
EOF

# Start Hyprland
Hyprland
# If it works, gradually add back settings from the broken config
```

### Broken Package Database

```bash
# Remove lock file
sudo rm /var/lib/pacman/db.lck

# Force refresh
sudo pacman -Syy

# If database is corrupted
sudo pacman -Syu --overwrite '*'

# Nuclear option: rebuild database
# (WARNING: only if other methods fail)
sudo pacman -Dk
sudo pacman -Dkk
```

### Login Loop (DM starts but session fails)

```bash
# From TTY:
# Check Xsession errors (if any)
cat ~/.local/share/xorg/Xorg.0.log 2>/dev/null | tail -30

# Check Hyprland errors
journalctl --user -u hyprland -b -n 50

# Check DMS errors
journalctl --user -u dms.service -b -n 30

# Try starting without DMS
# Edit hyprland.conf to comment out DMS exec-once lines
nano ~/.config/hypr/hyprland.conf
# Comment: # exec-once = systemctl --user start hyprland-session.target

# Restart DM
sudo systemctl restart sddm
```

### Audio Completely Gone

```bash
# Restart audio stack
systemctl --user restart pipewire.service
systemctl --user restart pipewire-pulse.service
systemctl --user restart wireplumber.service

# Check devices
pactl list sinks short
wpctl status

# If no devices found, check ALSA
aplay -l
# If ALSA works, PipeWire config might be wrong

# Reset PipeWire config
rm -rf ~/.config/pipewire/*
systemctl --user restart pipewire.service wireplumber.service
```

---

## Emergency Contacts

- **CachyOS Forum:** https://discuss.cachyos.org
- **CachyOS Wiki:** https://wiki.cachyos.org
- **Hyprland Wiki:** https://wiki.hyprland.org
- **Hyprland Discord:** discord.gg/hyprland
- **Arch Wiki:** https://wiki.archlinux.org
