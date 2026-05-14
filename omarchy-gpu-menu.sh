#!/bin/bash

# --- Sudo Pre-Check ---
# Prime the sudo cache upfront so background commands don't hang.
# If running without a terminal (e.g., from a keybind), use a graphical prompt.
# if ! sudo -n true 2>/dev/null; then
#     if [ -t 0 ]; then
#         # Running in a terminal
#         sudo -v || exit 1
#     elif command -v pkexec >/dev/null 2>&1; then
#         # Running via GUI/Shortcut
#         pkexec true || exit 1
#     else
#         notify-send "GPU Menu Error" "Requires sudo privileges. Run from terminal or install polkit."
#         exit 1
#     fi
# fi
# ----------------------

# GPU modes cached in these locations
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-gpu-menu"
STATE_FILE="$STATE_DIR/supported_modes.txt"

# Ensure supergfxctl is installed and running
if omarchy-cmd-missing supergfxctl; then
    omarchy-pkg-add supergfxctl
    sudo systemctl enable --now supergfxd
fi

mkdir -p "$STATE_DIR"

# Get current mode
CURRENT_MODE=$(supergfxctl -g)

# 1. BIOS/MUX Requirement Logic:
if [ "$CURRENT_MODE" == "AsusMuxDgpu" ]; then
    # Armoury Crate behavior: If in Ultimate/MUX mode, force switch to Hybrid only
    ALL_MODES="Hybrid"
else
    # Fetch all supported modes dynamically (Integrated, Hybrid, Vfio, Compute, etc.)
    VISIBLE_MODES=$(supergfxctl -s | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ')

    if [ -f "$STATE_FILE" ]; then
        SAVED_MODES=$(cat "$STATE_FILE")
    else
        SAVED_MODES=""
    fi

    # Merge visible and saved modes, remove duplicates and empty lines
    ALL_MODES=$(printf "%s\n%s\n" "$VISIBLE_MODES" "$SAVED_MODES" | awk 'NF' | sort -u)
fi

# Save the list back to cache (unless we restricted it due to MuxDgpu)
if [ "$CURRENT_MODE" != "AsusMuxDgpu" ]; then
    echo "$ALL_MODES" > "$STATE_FILE"
fi

# Pipe the list into Rofi
CHOSEN=$(echo "$ALL_MODES" | rofi -dmenu -i -p "GPU (Current: $CURRENT_MODE)")

# Apply the chosen mode
if [ -n "$CHOSEN" ]; then
    if [ "$CHOSEN" == "$CURRENT_MODE" ]; then
        notify-send "GPU Mode" "Already in $CHOSEN mode."
        exit 0
    fi

    notify-send "GPU Mode" "Preparing switch to $CHOSEN..."

    # Ensure OMARCHY_PATH is set for the sleep/delay configs
    OMARCHY_PATH="${OMARCHY_PATH:-/etc/omarchy}"

    case "$CHOSEN" in
        "Integrated")
            # Safe Switch: Edit config, enable VFIO, apply sleep fixes, then reboot
            sudo sed -i 's/"mode": ".*"/"mode": "Integrated"/' /etc/supergfxd.conf
            sudo sed -i 's/"vfio_enable": false/"vfio_enable": true/' /etc/supergfxd.conf
            
            sudo mkdir -p /usr/lib/systemd/system-sleep
            sudo cp -p "$OMARCHY_PATH/default/systemd/system-sleep/force-igpu" /usr/lib/systemd/system-sleep/
            sudo mkdir -p /etc/systemd/system/supergfxd.service.d
            sudo cp -p "$OMARCHY_PATH/default/systemd/system/supergfxd.service.d/delay-start.conf" /etc/systemd/system/supergfxd.service.d/
            
            notify-send "GPU Mode" "Rebooting to safely apply Integrated mode..."
            sleep 1
            omarchy-system-reboot
            ;;
            
        "Hybrid")
            # Safe Switch: Edit config, disable VFIO, remove sleep fixes, then reboot
            sudo sed -i 's/"mode": ".*"/"mode": "Hybrid"/' /etc/supergfxd.conf
            sudo sed -i 's/"vfio_enable": true/"vfio_enable": false/' /etc/supergfxd.conf
            
            sudo rm -f /usr/lib/systemd/system-sleep/force-igpu
            sudo rm -f /etc/systemd/system/supergfxd.service.d/delay-start.conf
            
            notify-send "GPU Mode" "Rebooting to safely apply Hybrid mode..."
            sleep 1
            omarchy-system-reboot
            ;;
            
        "AsusMuxDgpu")
            # Hardware MUX switch requires ACPI call and a strict reboot
            supergfxctl -m "AsusMuxDgpu"
            notify-send "GPU Mode" "Hardware MUX activated. Rebooting..."
            sleep 1
            omarchy-system-reboot
            ;;
            
        "Vfio")
            # VFIO binding for passthrough. Usually requires a logout to kill X11/Wayland tasks on the dGPU
            supergfxctl -m "Vfio"
            notify-send "GPU Mode" "Switched to Vfio. Please log out to apply cleanly."
            ;;

        *)
            # Fallback for any other modes (Compute, etc.)
            supergfxctl -m "$CHOSEN"
            notify-send "GPU Mode" "Switched to $CHOSEN. Logout may be required."
            ;;
    esac
fi
