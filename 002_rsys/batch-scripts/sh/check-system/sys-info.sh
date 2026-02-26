#!/bin/bash

echo "===== VPS Hardware Information ====="
echo

echo "---- OS Information ----"
cat /etc/os-release
echo

echo "---- Kernel ----"
uname -a
echo

echo "---- CPU Information ----"
lscpu
echo

echo "---- Memory Information ----"
free -h
echo

echo "---- Disk Information ----"
lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT
echo

echo "---- Disk Usage ----"
df -h
echo

echo "---- Network Interfaces ----"
ip -br addr
echo

echo "---- Virtualization ----"
systemd-detect-virt
echo

echo "---- Uptime ----"
uptime
echo

echo "===== End of Report ====="