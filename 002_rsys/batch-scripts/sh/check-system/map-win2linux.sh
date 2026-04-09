#!/usr/bin/env bash

echo "[+] Detecting external drives..."

mapfile -t DEVICES < <(lsblk -dpno NAME,TRAN | awk '$2=="usb"{print $1}')

if [ ${#DEVICES[@]} -eq 0 ]; then
  echo "[✗] No external USB drives found"
  exit 1
fi

echo "[+] Found devices:"
for i in "${!DEVICES[@]}"; do
  echo "  [$i] ${DEVICES[$i]}"
done

read -p "[?] Select device index: " IDX
DEVICE="${DEVICES[$IDX]}"

if [ -z "$DEVICE" ]; then
  echo "[✗] Invalid selection"
  exit 1
fi

# pick first partition if exists
PARTITION=$(lsblk -ln "$DEVICE" | awk 'NR==2{print $1}')
[ -n "$PARTITION" ] && DEVICE="/dev/$PARTITION"

MOUNT_POINT="/mnt/$(basename "$DEVICE")"

echo "[+] Using device: $DEVICE"
echo "[+] Mount point: $MOUNT_POINT"

sudo mkdir -p "$MOUNT_POINT"

# check if already mounted
if mount | grep -q "$DEVICE"; then
  echo "[!] Device already mounted. Skipping ntfsfix."
else
  FS_TYPE=$(lsblk -no FSTYPE "$DEVICE")

  if [[ "$FS_TYPE" == "ntfs" ]]; then
    if ! command -v ntfs-3g >/dev/null 2>&1; then
      echo "[+] Installing ntfs-3g..."
      sudo apt update -y && sudo apt install -y ntfs-3g
    fi

    echo "[+] Fixing NTFS..."
    sudo ntfsfix "$DEVICE"

    echo "[+] Mounting NTFS..."
    sudo mount -t ntfs-3g "$DEVICE" "$MOUNT_POINT"
  else
    echo "[+] Mounting ($FS_TYPE)..."
    sudo mount "$DEVICE" "$MOUNT_POINT"
  fi
fi

echo "[✓] Done. Mounted at $MOUNT_POINT"