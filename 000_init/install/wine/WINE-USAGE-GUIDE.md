# Wine Usage Guide

> **Generated:** 2026-06-20  
> **Purpose:** Comprehensive guide for using Wine on Linux, macOS, and Windows (WSL)

---

## Table of Contents

1. [What is Wine?](#what-is-wine)
2. [Quick Start](#quick-start)
3. [Basic Commands](#basic-commands)
4. [Wine Prefix Management](#wine-prefix-management)
5. [Configuration (winecfg)](#configuration-winecfg)
6. [Installing Windows Applications](#installing-windows-applications)
7. [Winetricks](#winetricks)
8. [Common Windows Components](#common-windows-components)
9. [Performance Tuning](#performance-tuning)
10. [Troubleshooting](#troubleshooting)
11. [Application-Specific Tips](#application-specific-tips)
12. [Uninstallation](#uninstallation)
13. [Additional Resources](#additional-resources)

---

## What is Wine?

**Wine** (originally an acronym for "Wine Is Not an Emulator") is a compatibility layer capable of running Windows applications on several POSIX-compliant operating systems, such as Linux, macOS, and BSD.

Unlike a virtual machine or emulator, Wine translates Windows API calls into POSIX calls on-the-fly, eliminating the performance and memory penalties of other methods and allowing you to cleanly integrate Windows applications into your desktop.

### Key Features
- **No Windows License Required** — Runs Windows apps without a Windows installation
- **No Virtual Machine Overhead** — Native performance, no emulation layer
- **Seamless Integration** — Windows apps appear alongside native Linux/macOS apps
- **Active Development** — Regular updates with improved compatibility

---

## Quick Start

### 1. Verify Installation
```bash
wine --version
```
Expected output: `wine-9.0` or similar (version may vary)

### 2. Initialize Wine for the First Time
```bash
winecfg
```
This creates the default Wine prefix at `~/.wine` and opens the configuration GUI.

### 3. Run Your First Windows Application
```bash
wine /path/to/your-application.exe
```

---

## Basic Commands

| Command | Description |
|---------|-------------|
| `wine --version` | Display Wine version |
| `wine program.exe` | Run a Windows program |
| `winecfg` | Open Wine configuration GUI |
| `winefile` | Wine file manager |
| `winetricks` | Helper script for installing libraries |
| `wineserver -k` | Kill all Wine processes |
| `wineserver -p` | Persistent Wine server |
| `wineboot` | Simulate Windows reboot |
| `wineconsole` | Run console applications |
| `regedit` | Wine registry editor |
| `msiexec /i setup.msi` | Install MSI packages |
| `wine uninstaller` | Add/Remove Programs equivalent |

---

## Wine Prefix Management

A **Wine prefix** (also called a "bottle") is a private Windows environment containing:
- A virtual `C:` drive
- Windows registry
- Installed applications
- Configuration files

### Default Prefix Location
```
~/.wine/
```

### Create a New Prefix
```bash
# 64-bit prefix (default)
WINEPREFIX=~/.wine-custom winecfg

# 32-bit prefix
WINEARCH=win32 WINEPREFIX=~/.wine32 winecfg
```

### Use a Specific Prefix
```bash
WINEPREFIX=~/.wine-custom wine application.exe
```

### Delete a Prefix
```bash
rm -rf ~/.wine-custom
```

### List All Prefixes
```bash
find ~ -maxdepth 2 -name ".wine*" -type d
```

### Best Practices
- Use separate prefixes for different applications to avoid conflicts
- Name prefixes descriptively (e.g., `~/.wine-games`, `~/.wine-office`)
- Back up important prefixes before major changes

---

## Configuration (winecfg)

Launch the configuration tool:
```bash
winecfg
```

### Applications Tab
Set the Windows version for specific applications:
- Windows 10 (most compatible)
- Windows 7 (for older apps)
- Windows XP (for legacy software)

### Graphics Tab
- **Emulate a virtual desktop** — Run apps in a contained window
- **Desktop size** — Set virtual desktop resolution
- **Screen resolution** — DPI settings

### Desktop Integration Tab
- Configure file associations
- Set theme and appearance

### Drives Tab
Manage drive mappings:
- `C:` → `~/.wine/drive_c`
- `D:` → `/mnt/data` (example)
- `Z:` → `/` (root filesystem)

### Audio Tab
- Select audio driver (ALSA, PulseAudio, OSS)
- Test sound

### About Tab
- Display Wine version and prefix information

---

## Installing Windows Applications

### Standard EXE Installer
```bash
wine /path/to/installer.exe
```

### MSI Installer
```bash
wine msiexec /i /path/to/installer.msi
```

### Silent Installation
```bash
wine installer.exe /S
wine msiexec /i setup.msi /quiet /norestart
```

### Common Installation Paths
| Windows Path | Linux/macOS Equivalent |
|-------------|----------------------|
| `C:\Program Files` | `~/.wine/drive_c/Program Files` |
| `C:\Program Files (x86)` | `~/.wine/drive_c/Program Files (x86)` |
| `C:\Users\Username` | `~/.wine/drive_c/users/$USER` |
| `C:\Windows` | `~/.wine/drive_c/windows` |

### Uninstalling Applications
```bash
wine uninstaller
```
This opens the "Add/Remove Programs" dialog.

---

## Winetricks

**Winetricks** is a helper script that downloads and installs various redistributable runtime libraries needed to run some programs in Wine.

### Launch GUI
```bash
winetricks
```

### Common Commands
```bash
# Install .NET Framework 4.8
winetricks dotnet48

# Install Visual C++ 2019 Redistributable
winetricks vcrun2019

# Install all Visual C++ runtimes
winetricks vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2019

# Install DirectX via DXVK
winetricks dxvk

# Install Core Fonts
winetricks corefonts

# Install Windows Media Player
winetricks wmp10

# Install Internet Explorer 8
winetricks ie8
```

### List All Available Components
```bash
winetricks list-all
```

### List Installed Components
```bash
winetricks list-installed
```

### Force Reinstall a Component
```bash
winetricks --force dotnet48
```

---

## Common Windows Components

### Essential Components for Most Apps
```bash
winetricks corefonts vcrun2019 dotnet48 dxvk
```

### For Gaming
```bash
winetricks dxvk vcrun2019 corefonts directx9
```

### For Microsoft Office
```bash
winetricks corefonts dotnet48 msxml6 gdiplus
```

### For Adobe Software
```bash
winetricks corefonts vcrun2019 atmlib gdiplus msxml3 msxml6
```

### For Development Tools
```bash
winetricks dotnet48 vcrun2019 msxml6 gdiplus
```

---

## Performance Tuning

### Environment Variables

Add these to your `~/.bashrc` or `~/.zshrc` for persistent settings:

```bash
# Disable debug output (significant performance boost)
export WINEDEBUG=-all

# Enable Esync (requires raised file descriptor limits)
export WINEESYNC=1

# Enable Fsync (Linux kernel 5.16+ with fsync patch)
export WINEFSYNC=1

# Enable large address aware for 32-bit apps
export WINE_LARGE_ADDRESS_AWARE=1

# Disable unused features
export WINEDLLOVERRIDES="mscoree,mshtml="
```

### DXVK (Vulkan-based D3D9/10/11)

DXVK translates Direct3D 9/10/11 calls to Vulkan, dramatically improving performance:

```bash
winetricks dxvk
```

**Requirements:**
- Vulkan-capable GPU
- Proper Vulkan drivers installed

### GPU Driver Recommendations

| GPU | Recommended Driver | Vulkan Support |
|-----|-------------------|----------------|
| NVIDIA | Proprietary `nvidia-driver` | Yes (via `libvulkan1`) |
| AMD | Mesa `radeonsi` | Yes (RADV) |
| Intel | Mesa `iris` | Yes (ANV) |

### CPU Governor (Linux)
For maximum performance while gaming:
```bash
# Set CPU governor to performance
sudo cpupower frequency-set -g performance

# Revert when done
sudo cpupower frequency-set -g ondemand
```

### Gamemode (Linux)
```bash
# Install gamemode
sudo apt install gamemode  # Debian/Ubuntu
sudo dnf install gamemode  # Fedora

# Run app with gamemode
gamemoderun wine game.exe
```

---

## Troubleshooting

### Application Won't Start

1. **Check Compatibility Database**
   Visit [WineHQ AppDB](https://appdb.winehq.org) to see if your app is supported.

2. **Try Different Windows Version**
   ```bash
   winecfg
   # Set Windows version to 7 or 10
   ```

3. **Install Missing Libraries**
   ```bash
   winetricks corefonts vcrun2019
   ```

4. **Check for Missing DLLs**
   ```bash
   WINEDEBUG=+loaddll wine app.exe 2>&1 | grep "failed"
   ```

### Graphics Issues

**Black screen or rendering issues:**
```bash
# Enable virtual desktop
winecfg
# Graphics → Emulate a virtual desktop

# Or use DXVK
winetricks dxvk
```

**NVIDIA-specific issues:**
```bash
# Enable NVIDIA optimizations
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SYNC_TO_VBLANK=0
```

### Audio Issues

```bash
winecfg
# Go to Audio tab
# Select correct driver (usually PulseAudio or ALSA)
# Test sound
```

If audio is choppy:
```bash
export PULSE_LATENCY_MSEC=60
wine app.exe
```

### Font Issues

```bash
winetricks corefonts
# Or install all Windows fonts
winetricks allfonts
```

### Reset Wine Prefix

If everything is broken, start fresh:
```bash
# Backup and remove old prefix
mv ~/.wine ~/.wine-backup

# Create new prefix
winecfg
```

### Debug Output

For detailed debugging:
```bash
# All debug channels
WINEDEBUG=+all wine app.exe 2>&1 | tee wine-debug.log

# Specific channels
WINEDEBUG=+dll,+file wine app.exe

# Common useful channels
WINEDEBUG=+loaddll,+seh,+relay wine app.exe
```

---

## Application-Specific Tips

### Microsoft Office
```bash
winetricks corefonts dotnet48 msxml6 gdiplus riched20
# Install Office via:
wine setup.exe
```

### Steam Games
```bash
winetricks dxvk vcrun2019 corefonts
# Download Steam installer and run:
wine SteamSetup.exe
```

### Adobe Photoshop
```bash
winetricks atmlib gdiplus msxml3 msxml6 vcrun2019 corefonts
```

### AutoCAD
```bash
winetricks dotnet48 vcrun2019 msxml6 corefonts
```

### Games (General)
```bash
winetricks dxvk vcrun2019 corefonts directx9
# Consider using Lutris for game management
```

---

## Uninstallation

To completely remove Wine and restore your system:

```bash
sudo bash uninstall-wine.sh
```

This script will:
1. ✅ Remove all Wine packages
2. ✅ Remove WineHQ repositories
3. ✅ Optionally remove Wine prefixes (with confirmation)
4. ✅ Restore original system configuration from backup
5. ✅ Clean up residual files

### Manual Uninstallation (if script unavailable)

**Debian/Ubuntu:**
```bash
sudo apt remove --purge winehq-stable wine-stable winetricks
sudo apt autoremove
sudo rm -rf ~/.wine
```

**Fedora/RHEL:**
```bash
sudo dnf remove wine winehq-stable winetricks
rm -rf ~/.wine
```

**Arch:**
```bash
sudo pacman -Rns wine winetricks
rm -rf ~/.wine
```

**macOS:**
```bash
brew uninstall --cask wine-stable
brew uninstall winetricks
rm -rf ~/.wine
```

---

## Additional Resources

### Official Resources
- **WineHQ Website:** https://www.winehq.org
- **Application Database:** https://appdb.winehq.org
- **Bug Tracker:** https://bugs.winehq.org
- **Documentation:** https://wiki.winehq.org

### Community Resources
- **Wine Forums:** https://forum.winehq.org
- **Reddit:** r/wine_gaming, r/linux_gaming
- **Lutris (Game Manager):** https://lutris.net
- **Bottles (Modern Wine Manager):** https://usebottles.com
- **Proton (Steam's Wine fork):** https://github.com/ValveSoftware/Proton

### Useful Tools
| Tool | Purpose | Link |
|------|---------|------|
| **Lutris** | Game launcher & manager | https://lutris.net |
| **Bottles** | Modern Wine prefix manager | https://usebottles.com |
| **PlayOnLinux** | Wine prefix manager | https://www.playonlinux.com |
| **Q4Wine** | Qt GUI for Wine | https://q4wine.brezblock.org.ua |
| **Wine-GE** | GloriousEggroll's Wine builds | https://github.com/GloriousEggroll/wine-ge-custom |

---

## Quick Reference Card

```bash
# Essential setup for new prefix
WINEPREFIX=~/.wine-new WINEARCH=win64 winecfg
winetricks corefonts vcrun2019 dxvk

# Run app with optimizations
WINEDEBUG=-all WINEESYNC=1 gamemoderun wine app.exe

# Debug problems
WINEDEBUG=+all wine app.exe 2>&1 | tee debug.log

# Kill stuck Wine processes
wineserver -k

# Backup prefix
tar czvf wine-backup.tar.gz ~/.wine

# Restore prefix
tar xzvf wine-backup.tar.gz -C ~
```

---

> **Note:** Wine compatibility varies by application. Always check the [WineHQ AppDB](https://appdb.winehq.org) for specific application ratings and tips before installing complex software.

---

*This guide was generated alongside the Wine installation script.*  
*For support, visit https://forum.winehq.org*
