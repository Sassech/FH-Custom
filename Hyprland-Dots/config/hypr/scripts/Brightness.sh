#!/bin/bash
# #
# Enhanced Script for Monitor backlights using brightnessctl
# Supports Intel backlight with improved error handling

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1500
step=10  # INCREASE/DECREASE BY THIS VALUE
min_brightness=5  # Minimum brightness to prevent screen going completely dark

# Get current brightness as an integer (without %)
get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

# Determine the icon based on brightness level
get_icon_path() {
    local brightness=$1
    local level
    
    # Map brightness to available icon levels (20, 40, 60, 80, 100)
    if (( brightness <= 10 )); then
        level=20
    elif (( brightness <= 30 )); then
        level=20
    elif (( brightness <= 50 )); then
        level=40
    elif (( brightness <= 70 )); then
        level=60
    elif (( brightness <= 90 )); then
        level=80
    else
        level=100
    fi
    
    # Check if icon exists, fallback to a default if not
    local icon_path="$iDIR/brightness-${level}.png"
    if [[ -f "$icon_path" ]]; then
        echo "$icon_path"
    else
        echo "$iDIR/brightness-60.png"  # Fallback icon
    fi
}

# Send notification
send_notification() {
    local brightness=$1
    local icon_path=$2

    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "$icon_path" \
        "Screen" "Brightness: ${brightness}%"
}

# Change brightness and notify
change_brightness() {
    local delta=$1
    local current new icon

    current=$(get_brightness)
    new=$((current + delta))

    # Clamp between min_brightness and 100
    (( new < min_brightness )) && new=$min_brightness
    (( new > 100 )) && new=100

    # Only change if different from current
    if (( new != current )); then
        brightnessctl set "${new}%" >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            icon=$(get_icon_path "$new")
            send_notification "$new" "$icon"
        else
            notify-send -u critical "Brightness Error" "Failed to change brightness"
        fi
    fi
}

# Set specific brightness level
set_brightness() {
    local target=$1
    (( target < min_brightness )) && target=$min_brightness
    (( target > 100 )) && target=100
    
    brightnessctl set "${target}%" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        icon=$(get_icon_path "$target")
        send_notification "$target" "$icon"
    fi
}

# Main
case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    "--set")
        if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
            set_brightness "$2"
        else
            echo "Usage: $0 --set <brightness_percentage>"
            exit 1
        fi
        ;;
    "--max")
        set_brightness 100
        ;;
    "--min")
        set_brightness "$min_brightness"
        ;;
    "--mid")
        set_brightness 50
        ;;
    "--info")
        current=$(get_brightness)
        echo "Current brightness: ${current}%"
        echo "Available devices:"
        brightnessctl --list | grep -E "(backlight|intel_backlight)"
        ;;
    *)
        echo "Enhanced Brightness Control Script"
        echo "Usage: $0 [--get|--inc|--dec|--set <value>|--max|--min|--mid|--info]"
        echo "  --get    : Get current brightness percentage"
        echo "  --inc    : Increase brightness by $step%"
        echo "  --dec    : Decrease brightness by $step%"
        echo "  --set N  : Set brightness to N%"
        echo "  --max    : Set to maximum brightness (100%)"
        echo "  --min    : Set to minimum brightness (${min_brightness}%)"
        echo "  --mid    : Set to medium brightness (50%)"
        echo "  --info   : Show current brightness and available devices"
        ;;
esac