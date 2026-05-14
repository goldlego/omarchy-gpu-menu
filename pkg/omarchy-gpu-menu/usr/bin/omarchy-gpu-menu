#!/bin/bash

# Runs a block of commands as root. Prompts via terminal (sudo) or GUI (pkexec) exactly once.
run_as_root() {
    local cmds="$1"
    if sudo -n true 2>/dev/null || [ -t 0 ]; then
        # Running in terminal or sudo is already cached
        sudo bash -c "$cmds"
    elif command -v pkexec >/dev/null 2>&1; then
        # Running via GUI/Keybind, prompt once for the whole block
        pkexec bash -c "$cmds"
    else
        notify-send "GPU Menu Error" "Requires sudo privileges. Run from terminal or install polkit."
        exit 1
    fi
}

# GPU modes cached in these locations
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-gpu-menu"
STATE_FILE="$STATE_DIR/supported_modes.txt"

# Ensure supergfxctl is installed and running
if omarchy-cmd-missing supergfxctl; then
    run_as_root "omarchy-pkg-add supergfxctl && systemctl enable --now supergfxd"
fi

if omarchy-cmd-missing wofi; then
    omarchy-pkg-add wofi
fi

mkdir -p "$STATE_DIR"

# Get current mode
CURRENT_MODE=$(supergfxctl -g)

# 1. BIOS/MUX Requirement Logic:
if [ "$CURRENT_MODE" == "AsusMuxDgpu" ]; then
    ALL_MODES="Hybrid"
else
    VISIBLE_MODES=$(supergfxctl -s | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ')

    if [ -f "$STATE_FILE" ]; then
        SAVED_MODES=$(cat "$STATE_FILE")
    else
        SAVED_MODES=""
    fi

    ALL_MODES=$(printf "%s\n%s\n" "$VISIBLE_MODES" "$SAVED_MODES" | awk 'NF' | sort -u)
fi

if [ "$CURRENT_MODE" != "AsusMuxDgpu" ]; then
    echo "$ALL_MODES" > "$STATE_FILE"
fi

# Define paths with fallbacks
if [ -f "./config/gpu-menu.conf" ]; then
    CONF_PATH="./config/gpu-menu.conf"
    STYLE_PATH="./config/gpu-style.css"
else
    CONF_PATH="/etc/omarchy/wofi/gpu-menu.conf"
    STYLE_PATH="/etc/omarchy/wofi/gpu-style.css"
fi

# Pipe the list into Wofi
CHOSEN=$(echo "$ALL_MODES" | wofi --show dmenu \
    --conf "$CONF_PATH" \
    --style "$STYLE_PATH" \
    --prompt "GPU (Current: $CURRENT_MODE)" \
    --insensitive)

# Apply the chosen mode
if [ -n "$CHOSEN" ]; then
    if [ "$CHOSEN" == "$CURRENT_MODE" ]; then
        notify-send "GPU Mode" "Already in $CHOSEN mode."
        exit 0
    fi

    notify-send "GPU Mode" "Preparing switch to $CHOSEN..."

    OMARCHY_PATH="${OMARCHY_PATH:-/etc/omarchy}"

    case "$CHOSEN" in
        "Integrated")
            # Batch all root commands into one string
            run_as_root "
                sed -i 's/\"mode\": \".*\"/\"mode\": \"Integrated\"/' /etc/supergfxd.conf
                sed -i 's/\"vfio_enable\": false/\"vfio_enable\": true/' /etc/supergfxd.conf
                mkdir -p /usr/lib/systemd/system-sleep
                cp -p \"$OMARCHY_PATH/default/systemd/system-sleep/force-igpu\" /usr/lib/systemd/system-sleep/
                mkdir -p /etc/systemd/system/supergfxd.service.d
                cp -p \"$OMARCHY_PATH/default/systemd/system/supergfxd.service.d/delay-start.conf\" /etc/systemd/system/supergfxd.service.d/
            "
            notify-send "GPU Mode" "Rebooting to safely apply Integrated mode..."
            sleep 1
            omarchy-system-reboot
            ;;

        "Hybrid")
            # Batch all root commands into one string
            run_as_root "
                sed -i 's/\"mode\": \".*\"/\"mode\": \"Hybrid\"/' /etc/supergfxd.conf
                sed -i 's/\"vfio_enable\": true/\"vfio_enable\": false/' /etc/supergfxd.conf
                rm -f /usr/lib/systemd/system-sleep/force-igpu
                rm -f /etc/systemd/system/supergfxd.service.d/delay-start.conf
            "
            notify-send "GPU Mode" "Rebooting to safely apply Hybrid mode..."
            sleep 1
            omarchy-system-reboot
            ;;

        "AsusMuxDgpu")
            # supergfxctl handles DBus automatically, no root needed here!
            supergfxctl -m "AsusMuxDgpu"
            notify-send "GPU Mode" "Hardware MUX activated. Rebooting..."
            sleep 1
            omarchy-system-reboot
            ;;

        "Vfio")
            supergfxctl -m "Vfio"
            notify-send "GPU Mode" "Switched to Vfio. Please log out to apply cleanly."
            ;;

        *)
            supergfxctl -m "$CHOSEN"
            notify-send "GPU Mode" "Switched to $CHOSEN. Logout may be required."
            ;;
    esac
fi
