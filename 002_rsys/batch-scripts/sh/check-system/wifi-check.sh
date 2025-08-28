#!/bin/bash
echo "🔍 Wi-Fi Health Check"
echo "====================="

# Show driver + firmware for wireless
sudo lshw -C network | grep -A15 "Wireless interface" | grep -E "product|vendor|logical name|driver|firmware"

echo
echo "🔎 Kernel messages (last 5 lines for rtw89):"
sudo dmesg | grep rtw89 | tail -n 5

echo
echo "⚡ Power save state:"
iw dev wlp2s0 get power_save
