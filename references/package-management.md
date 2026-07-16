# Package Management Reference

## Overview

CachyOS is based on Arch Linux and uses pacman as the primary package manager.
For AUR (Arch User Repository) packages, CachyOS ships with paru by default.

## pacman — Official Package Manager

### Basic Operations

```bash
# Search for a package
pacman -Ss <keyword>

# Show package info (from repos)
pacman -Si <package>

# Show package info (installed)
pacman -Qi <package>

# Install a package
sudo pacman -S <package>

# Install multiple packages
sudo pacman -S package1 package2 package3

# Remove a package
sudo pacman -R <package>

# Remove package + orphaned dependencies
sudo pacman -Rns <package>

# Update system (sync + upgrade)
sudo pacman -Syu

# Force refresh and update
sudo pacman -Syyu

# List all installed packages
pacman -Q

# List explicitly installed packages
pacman -Qe

# List orphaned packages (unused dependencies)
pacman -Qdt

# Find which package owns a file
pacman -Qo /path/to/file

# List files installed by a package
pacman -Ql <package>

# Download package without installing
sudo pacman -Sw <package>

# Clean package cache (interactive)
sudo pacman -Sc

# Clean all package cache
sudo pacman -Scc
```

### Important Flags

| Flag | Description |
|---|---|
| `-S` | Sync (install/update) |
| `-R` | Remove |
| `-Q` | Query (installed packages) |
| `-U` | Upgrade from file |
| `-D` | Database operations |
| `-F` | File database operations |
| `-s` | Search |
| `-i` | Info |
| `-y` | Refresh package database |
| `-u` | Upgrade |
| `-n` | Remove config files (with -R) |
| `-s` | Remove unneeded deps (with -R) |

### pacman.conf

Main config: `/etc/pacman.conf`

Key settings:
```ini
[options]
Color                    # Colorized output
ParallelDownloads = 5    # Parallel downloads
ILoveCandy               # Easter egg progress bar

# CachyOS repositories (before Arch repos for priority)
[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist
```

## paru — AUR Helper (Recommended)

paru is the default AUR helper on CachyOS. It wraps pacman and adds
AUR support.

### Basic Operations

```bash
# Search repos + AUR
paru -Ss <keyword>

# Search AUR only
paru -Ss --aur <keyword>

# Install from AUR
paru -S <package>

# Update everything (repos + AUR)
paru -Syu

# Show AUR package info
paru -Si <aur-package>

# Clean build cache
paru -Sc

# Review and manage installed AUR packages
paru -Qm

# Edit PKGBUILD before building
paru -S <package> --review
```

### paru Configuration

Config: `~/.config/paru/paru.conf` or `/etc/paru.conf`

```ini
[options]
BottomUp          # Show results bottom-up
SudoLoop          # Keep sudo alive during long builds
CleanAfter        # Clean build files after install
Provides          # Check for provides
DevelSuffixes = -git -svn -bzr -hg -nightly
RemoveMake        # Remove make deps after build
```

## yay — Alternative AUR Helper

If paru is not available, yay is the most common alternative:

```bash
# Same syntax as paru
yay -Ss <keyword>
yay -S <package>
yay -Syu
```

## makepkg — Building from Source

For manual AUR package building:

```bash
# Clone AUR package
git clone https://aur.archlinux.org/<package>.git
cd <package>

# Review PKGBUILD
cat PKGBUILD

# Build and install
makepkg -si

# Build without installing
makepkg -s

# Skip integrity checks (NOT recommended)
makepkg -si --skipintechk
```

## CachyOS-Specific Repositories

CachyOS maintains optimized repositories:

| Repository | Description |
|---|---|
| `cachyos` | Main CachyOS packages |
| `cachyos-extra` | Additional CachyOS packages |
| `cachyos-v3` | x86-64-v3 optimized packages |
| `cachyos-v4` | x86-64-v4 optimized packages |

Check current repos:
```bash
grep -E '^\[[a-zA-Z0-9_-]+\]' /etc/pacman.conf
```

CachyOS repos take priority over Arch repos for packages they provide,
meaning you get optimized builds automatically.

## Safety Rules

1. **Never remove base packages:** `pacman -Rns base`, `linux`, `systemd`, etc.
2. **Always review AUR PKGBUILDs** before building
3. **Run `pacman -Syu` before installing** new packages to avoid partial upgrades
4. **Never run `pacman -Sy <package>`** (partial upgrade = broken system)
5. **Keep the package cache** — use `paccache -rk3` to keep last 3 versions
6. **Check AUR package health** before installing:
   - Last updated (within 6 months)
   - Votes (>10 preferred)
   - Not flagged as out-of-date
   - Not orphaned
7. **Use `pacman -Rns`** instead of `-R` to remove orphaned deps and configs

## Downgrading Packages

If an update breaks something:

```bash
# Downgrade from cache
sudo pacman -U /var/cache/pacman/pkg/<package>-<old-version>.pkg.tar.zst

# Or use the 'downgrade' tool
sudo pacman -S downgrade
sudo downgrade <package>
```

## Handling Keyring Issues

```bash
# Refresh keys
sudo pacman-key --init
sudo pacman-key --populate archlinux cachyos

# If keys are corrupted
sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux cachyos
```

## System Maintenance

```bash
# Remove orphaned packages
sudo pacman -Rns $(pacman -Qdtq)

# Clean package cache (keep 3 versions)
sudo paccache -rk3

# Check for broken packages
pacman -Qkk 2>&1 | grep -v ' 0 altered'

# Find large packages
pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4,$5,name}' | sort -hr | head -20
```
