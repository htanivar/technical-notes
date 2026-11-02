#!/bin/bash

# Check if the output of 'id -u' is not equal to 0
if [ "$(id -u)" -ne 0 ]; then
    echo "🚨 This script must be run with root privileges (e.g., using 'sudo')." >&2
    exit 1
fi

# The rest of your script
echo "Root privileges detected. Continuing script execution..."


# --- Configuration ---
SWAP_FILE="/swapfile"
SWAPPINESS_VALUE="10" # Lower value (10) makes the system use swap less aggressively

# --- Function to Calculate Recommended Swap Size ---
calculate_swap_size() {
    # Get total system memory (RAM) in KB
    local TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

    # Convert RAM to GB, rounding up for comparison
    local TOTAL_RAM_GB=$(echo "scale=0; ($TOTAL_RAM_KB / 1024 / 1024) + 0.5" | bc)

    local RECOMMENDED_SIZE_GB

    # Swap Size Guidelines:
    if [ "$TOTAL_RAM_GB" -le 2 ]; then
        # If RAM is 2 GB or less, swap should be 2 times RAM
        RECOMMENDED_SIZE_GB=$((TOTAL_RAM_GB * 2))
    elif [ "$TOTAL_RAM_GB" -le 8 ]; then
        # If RAM is 2 GB to 8 GB, swap should be equal to RAM
        RECOMMENDED_SIZE_GB=$TOTAL_RAM_GB
    else
        # If RAM is 8 GB or more, swap should be 4 GB (or 0.5 times RAM, whichever is less)
        # We will conservatively set it to 4GB for VM use to conserve disk space,
        # as modern systems rarely need huge swap files.
        RECOMMENDED_SIZE_GB=4
    fi

    # Convert GB to the "G" format for fallocate
    echo "${RECOMMENDED_SIZE_GB}G"
}

# --- Start Script ---

echo "--- Starting Automated Swap File Configuration ---"

# 1. Determine the required swap size
SWAP_SIZE=$(calculate_swap_size)
echo "System RAM detected. Recommended swap size is: **$SWAP_SIZE**"

# 2. Check for existing swap space
echo "Current swap status:"
sudo swapon --show

# 3. Check if the swap file already exists and stop if it is already active
if [ -f "$SWAP_FILE" ] && sudo swapon -s | grep -q "$SWAP_FILE"; then
    echo "The file $SWAP_FILE already exists and is active. Exiting."
    exit 0
fi

# 4. Create the swap file
echo "Creating swap file ($SWAP_SIZE) at $SWAP_FILE..."
if ! sudo fallocate -l $SWAP_SIZE $SWAP_FILE; then
    echo "fallocate failed. Trying dd..."
    # Convert size (e.g., '4G') to block size (1M) and count
    SIZE_NUM=$(echo $SWAP_SIZE | sed 's/G//')
    BLOCK_COUNT=$((SIZE_NUM * 1024))
    sudo dd if=/dev/zero of=$SWAP_FILE bs=1M count=$BLOCK_COUNT
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create swap file using fallocate and dd. Exiting."
        exit 1
    fi
fi
echo "Swap file created successfully."

# 5. Set correct permissions
echo "Setting secure permissions (600)..."
sudo chmod 600 $SWAP_FILE

# 6. Set up the Linux swap area
echo "Setting up $SWAP_FILE as a swap area..."
sudo mkswap $SWAP_FILE

# 7. Enable the swap file
echo "Enabling the new swap file..."
sudo swapon $SWAP_FILE

# 8. Make the swap file permanent (add to /etc/fstab)
echo "Adding $SWAP_FILE entry to /etc/fstab for persistence..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "Entry added to /etc/fstab."
else
    echo "Entry for $SWAP_FILE already exists in /etc/fstab."
fi

# 9. Adjust swappiness (optional but recommended)
echo "Setting swappiness to $SWAPPINESS_VALUE (less aggressive swapping)..."
sudo sysctl vm.swappiness=$SWAPPINESS_VALUE
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=$SWAPPINESS_VALUE" | sudo tee -a /etc/sysctl.conf
else
    sudo sed -i "/vm.swappiness/c\vm.swappiness=$SWAPPINESS_VALUE" /etc/sysctl.conf
fi
echo "vm.swappiness configured permanently."

# 10. Verification
echo "--- Verification ---"
echo "New swap status:"
sudo swapon --show
echo "Free memory and swap:"
free -h
echo "Current swappiness value:"
cat /proc/sys/vm/swappiness
echo "--- Swap Configuration Complete ---"