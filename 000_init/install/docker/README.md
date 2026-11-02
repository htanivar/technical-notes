# Multi-Flavour Linux Docker Installer & Diagnostics Suite

Self-sufficient scripts to prepare, install, verify, diagnose, self-heal, and uninstall Docker across major Linux distributions.

## Supported Linux Distributions & Architectures

- **Debian / Ubuntu Family (`apt`)**: Ubuntu, Debian, Linux Mint (Ubuntu & LMDE), Pop!\_OS, Kali Linux, Raspberry Pi OS / Raspbian, Armbian, Zorin, Elementary, Proxmox, Deepin
  - Automatically configures Official Docker CE (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`) and transparently falls back to native distro packages (`docker.io`) if an unreleased codename or architecture is encountered.
- **RHEL / Fedora / Amazon Linux Family (`dnf` / `yum`)**: Fedora, RHEL, CentOS Stream, Rocky Linux, AlmaLinux, Oracle Linux, Amazon Linux 2 / 2023
- **Arch Family (`pacman`)**: Arch Linux, Manjaro, EndeavourOS, Garuda
- **SUSE Family (`zypper`)**: openSUSE Leap, Tumbleweed, SLES
- **Alpine (`apk`)**: Alpine Linux (OpenRC & container modes)
- **Architectures**: `x86_64` (`amd64`), `aarch64` (`arm64`), `armv7l`/`armv6l` (`armhf`), `s390x`, `ppc64le`, `riscv64`

---

## Scripts Overview

| Script | Purpose |
| :--- | :--- |
| `docker-ctl.sh` | Unified CLI wrapper (`all`, `pre`, `install`, `status`, `diagnose`, `repair`, `uninstall`, `unpre`, `purge`) |
| `pre.sh` | Probes OS/arch, installs prerequisites, sets up GPG keys/repos, caches packages + dependencies to `/var/cache/docker-install`, configures `docker` group, and writes `/var/lib/docker-install/state.env` |
| `install_docker.sh` | Installs Docker from cached packages (automatically runs `pre.sh` if not yet run), resolves conflicting packages, starts services, and performs self-healing startup recovery |
| `status.sh` | Displays comprehensive status (OS, binaries, services, socket permissions, daemon runtime, containers/images) in human-readable or `--json` format |
| `diagnose.sh` | Runs a 12-point diagnostic check across kernel modules, cgroups, package conflicts, repos, binaries, `daemon.json`, systemd journals, socket permissions, `iptables`, and disk space. Supports `--fix` for automated repair |
| `uninstall_docker.sh` | Stops services and removes Docker packages (`--purge-data` to also delete `/var/lib/docker` and `/var/lib/containerd`) |
| `unpre.sh` | Reverts `pre.sh` changes (removes repo files, GPG keys, cached packages, state files, and group membership) |
| `common.sh` | Shared library for OS/arch/init detection, logging, state persistence, and self-healing service startup |

---

## Quick Start

### 1. One-Command Install (Standalone or via `docker-ctl.sh`)
```bash
sudo ./install_docker.sh
# or
sudo ./docker-ctl.sh all
```

### 2. Two-Step Prepare (Download/Cache) + Install
```bash
sudo ./pre.sh
sudo ./install_docker.sh --verify-container
```

### 3. Check Status
```bash
./status.sh
./status.sh --json
```

### 4. Diagnose & Auto-Repair
```bash
./diagnose.sh
sudo ./diagnose.sh --fix
# or
sudo ./docker-ctl.sh repair
```

### 5. Uninstall & Clean Up
```bash
sudo ./uninstall_docker.sh
sudo ./unpre.sh
# or full wipe including images/volumes:
sudo ./docker-ctl.sh purge
```

