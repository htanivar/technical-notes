#!/usr/bin/env bash

set -e

# Must be run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Install OpenSSH if missing (Debian-based)
if ! command -v sshd >/dev/null 2>&1; then
    if command -v apt >/dev/null 2>&1; then
        apt update -y
        apt install -y openssh-server
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y openssh-server
    elif command -v yum >/dev/null 2>&1; then
        yum install -y openssh-server
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm openssh
    elif command -v apk >/dev/null 2>&1; then
        apk add openssh
    else
        echo "Unsupported package manager. Install OpenSSH manually."
        exit 1
    fi
fi

# Restart & enable SSH (handles common init systems)

if command -v systemctl >/dev/null 2>&1; then
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

elif command -v service >/dev/null 2>&1; then
    service ssh restart 2>/dev/null || service sshd restart 2>/dev/null || true
    if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d ssh defaults 2>/dev/null || true
    elif command -v chkconfig >/dev/null 2>&1; then
        chkconfig sshd on 2>/dev/null || true
    fi

elif command -v rc-service >/dev/null 2>&1; then
    rc-service sshd restart
    rc-update add sshd default 2>/dev/null || true

elif [ -x /etc/init.d/ssh ]; then
    /etc/init.d/ssh restart

elif [ -x /etc/init.d/sshd ]; then
    /etc/init.d/sshd restart

else
    echo "Could not determine init system. Start SSH manually."
    exit 1
fi

echo "SSH is installed, enabled, and running."
