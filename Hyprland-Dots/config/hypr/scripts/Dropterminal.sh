#!/bin/bash
# #
# Dropdown Terminal 
# Usage: ./Dropdown.sh [-d] <terminal_command>
# Example: ./Dropdown.sh foot
#          ./Dropdown.sh -d foot (with debug output)
#          ./Dropdown.sh "kitty -e zsh"
#          ./Dropdown.sh "alacritty --working-directory /home/user"

DEBUG=false
SPECIAL_WS="special:scratchpad"
ADDR_FILE="/tmp/dropdown_terminal_addr"

# Dropdown size and position configuration (percentages)
WIDTH_PERCENT=50  # Width as percentage of screen width
HEIGHT_PERCENT=50 # Height as percentage of screen height
X_PERCENT=25      # X position as percentage from left (25% centers a 50% width window)
Y_PERCENT=5       # Y position as percentage from top

# Animation settings
ANIMATION_DURATION=100  # milliseconds
SLIDE_STEPS=5
SLIDE_DELAY=5  # milliseconds between steps

# Parse arguments
if [ "$1" = "-d" ]; then
    DEBUG=true
    shift
fi

TERMINAL_CMD="$1"

# Debug echo function
debug_echo() {
    if [ "$DEBUG" = true ]; then
        echo "$@"
    fi
}

# Validate input
if [ -z "$TERMINAL_CMD" ]; then
    echo "Missing terminal command. Usage: $0 [-d] <terminal_command>"
    echo "Examples:"
    echo "  $0 foot"
    echo "  $0 -d foot (with debug output)"
    echo "  $0 'kitty -e zsh'"
    echo "  $0 'alacritty --working-directory /home/user'"
    echo ""
    echo "Edit the script to modify size and position:"
    echo "  WIDTH_PERCENT  - Width as percentage of screen (default: 50)"
    echo "  HEIGHT_PERCENT - Height as percentage of screen (default: 50)"
    echo "  X_PERCENT      - X position from left as percentage (default: 25)"
    echo "  Y_PERCENT      - Y position from top as percentage (default: 5)"
    exit 1
fi

# Function to get window geometry
get_window_geometry() {
    local addr="$1"
    hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"'
}

# Function to animate window slide down (show)
animate_slide_down() {
    local addr="$1"
    local target_x="$2"
    local target_y="$3"
    local width="$4"
    local height="$5"
    
    debug_echo "Animating slide down for window $addr to position $target_x,$target_y"
    
    # Verify window still exists before animating
    if ! hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1; then
        debug_echo "Window $addr no longer exists, skipping animation"
        return 1
    fi
    
    # Start position (above screen, but not too far to avoid issues)
    local start_y=$((target_y - height - 20))
    
    # Ensure start position is not negative
    if [ $start_y -lt 0 ]; then
        start_y=0
    fi
    
    # Calculate step size
    local step_y=$(((target_y - start_y) / SLIDE_STEPS))
    
    # Move window to start position instantly
    hyprctl dispatch movewindowpixel "exact $target_x $start_y,address:$addr" >/dev/null 2>&1
    sleep 0.02
    
    # Smoother animation with smaller delays
    for i in $(seq 1 $SLIDE_STEPS); do
        local current_y=$((start_y + (step_y * i)))
        hyprctl dispatch movewindowpixel "exact $target_x $current_y,address:$addr" >/dev/null 2>&1
        sleep 0.02
    done
    
    # Ensure final position is exact
    hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$addr" >/dev/null 2>&1
}

# Function to animate window slide up (hide)
animate_slide_up() {
    local addr="$1"
    local start_x="$2"
    local start_y="$3"
    local width="$4"
    local height="$5"
    
    debug_echo "Animating slide up for window $addr from position $start_x,$start_y"
    
    # End position (above screen)
    local end_y=$((start_y - height - 50))
    
    # Calculate step size
    local step_y=$(((start_y - end_y) / SLIDE_STEPS))
    
    # Animate slide up
    for i in $(seq 1 $SLIDE_STEPS); do
        local current_y=$((start_y - (step_y * i)))
        hyprctl dispatch movewindowpixel "exact $start_x $current_y,address:$addr" >/dev/null 2>&1
        sleep 0.03
    done
    
    debug_echo "Slide up animation completed"
}

# Function to get monitor info for centering
get_monitor_info() {
    hyprctl monitors -j | jq -r '.[0] | "\(.x) \(.y) \(.width) \(.height)"'
}

# Function to calculate dropdown position
calculate_dropdown_position() {
    local monitor_info=$(get_monitor_info)
    local mon_x=$(echo $monitor_info | cut -d' ' -f1)
    local mon_y=$(echo $monitor_info | cut -d' ' -f2)
    local mon_width=$(echo $monitor_info | cut -d' ' -f3)
    local mon_height=$(echo $monitor_info | cut -d' ' -f4)
    
    # Calculate position and size based on percentages
    local width=$((mon_width * WIDTH_PERCENT / 100))
    local height=$((mon_height * HEIGHT_PERCENT / 100))
    local x=$((mon_x + (mon_width * X_PERCENT / 100)))
    local y=$((mon_y + (mon_height * Y_PERCENT / 100)))
    
    echo "$x $y $width $height"
}

# Get the current workspace
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Function to get stored terminal address
get_terminal_address() {
    if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then
        cat "$ADDR_FILE"
    fi
}

# Function to check if terminal exists and is actually a terminal
terminal_exists() {
    local addr=$(get_terminal_address)
    if [ -n "$addr" ]; then
        # Check if window exists and verify it's actually a terminal window
        if hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and (.class | test("kitty|foot|alacritty|wezterm|gnome-terminal"; "i")))' >/dev/null 2>&1; then
            return 0
        else
            # Clean up invalid address file
            debug_echo "Cleaning up invalid terminal address: $addr"
            rm -f "$ADDR_FILE"
            return 1
        fi
    else
        return 1
    fi
}

# Function to check if terminal is in special workspace
terminal_in_special() {
    local addr=$(get_terminal_address)
    if [ -n "$addr" ]; then
        hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "special:scratchpad")' >/dev/null 2>&1
    else
        return 1
    fi
}

# Function to wait for window to appear with better detection
wait_for_terminal() {
    local max_attempts=20
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local newest_terminal=$(hyprctl clients -j | jq -r '[.[] | select(.class | test("kitty|foot|alacritty|wezterm|gnome-terminal"; "i"))] | sort_by(.focusHistoryID) | .[-1] | .address')
        
        if [ -n "$newest_terminal" ] && [ "$newest_terminal" != "null" ]; then
            echo "$newest_terminal"
            return 0
        fi
        
        sleep 0.05
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Function to spawn terminal and capture its address
spawn_terminal() {
    debug_echo "Creating new dropdown terminal with command: $TERMINAL_CMD"
    
    # Calculate dropdown position for later use
    pos_info=$(calculate_dropdown_position)
    target_x=$(echo $pos_info | cut -d' ' -f1)
    target_y=$(echo $pos_info | cut -d' ' -f2)
    width=$(echo $pos_info | cut -d' ' -f3)
    height=$(echo $pos_info | cut -d' ' -f4)
    
    debug_echo "Target position: ${target_x}x${target_y}, size: ${width}x${height}"
    
    # Launch terminal directly in special workspace to avoid visible spawn
    hyprctl dispatch exec "[float; size $width $height; workspace special:scratchpad silent] $TERMINAL_CMD" >/dev/null 2>&1
    
    # Wait for terminal to appear with improved detection
    new_addr=$(wait_for_terminal)
    
    if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
        # Store the address
        echo "$new_addr" > "$ADDR_FILE"
        debug_echo "Terminal created with address: $new_addr"
        
        # Ensure window is properly configured before animation
        hyprctl dispatch resizewindowpixel "exact $width $height,address:$new_addr" >/dev/null 2>&1
        sleep 0.1
        
        # Move to current workspace and show with animation
        hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$new_addr" >/dev/null 2>&1
        sleep 0.05
        hyprctl dispatch pin "address:$new_addr" >/dev/null 2>&1
        animate_slide_down "$new_addr" "$target_x" "$target_y" "$width" "$height"
        
        return 0
    fi
    
    debug_echo "Failed to create or detect terminal"
    return 1
}

# Main logic with better error handling
if terminal_exists; then
    TERMINAL_ADDR=$(get_terminal_address)
    debug_echo "Found existing terminal: $TERMINAL_ADDR"

    if terminal_in_special; then
        debug_echo "Bringing terminal from scratchpad with slide down animation"
        
        # Calculate target position
        pos_info=$(calculate_dropdown_position)
        target_x=$(echo $pos_info | cut -d' ' -f1)
        target_y=$(echo $pos_info | cut -d' ' -f2)
        width=$(echo $pos_info | cut -d' ' -f3)
        height=$(echo $pos_info | cut -d' ' -f4)
        
        # Sequence commands with proper delays to avoid conflicts
        hyprctl dispatch resizewindowpixel "exact $width $height,address:$TERMINAL_ADDR" >/dev/null 2>&1
        sleep 0.05
        hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$TERMINAL_ADDR" >/dev/null 2>&1
        sleep 0.05
        hyprctl dispatch pin "address:$TERMINAL_ADDR" >/dev/null 2>&1
        sleep 0.05
        
        # Animate and focus
        if animate_slide_down "$TERMINAL_ADDR" "$target_x" "$target_y" "$width" "$height"; then
            hyprctl dispatch focuswindow "address:$TERMINAL_ADDR" >/dev/null 2>&1
        else
            debug_echo "Animation failed, attempting direct focus"
            hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$TERMINAL_ADDR" >/dev/null 2>&1
            hyprctl dispatch focuswindow "address:$TERMINAL_ADDR" >/dev/null 2>&1
        fi
    else
        debug_echo "Hiding terminal to scratchpad with slide up animation"
        
        # Get current geometry for animation
        geometry=$(get_window_geometry "$TERMINAL_ADDR")
        if [ -n "$geometry" ]; then
            curr_x=$(echo $geometry | cut -d' ' -f1)
            curr_y=$(echo $geometry | cut -d' ' -f2)
            curr_width=$(echo $geometry | cut -d' ' -f3)
            curr_height=$(echo $geometry | cut -d' ' -f4)
            
            debug_echo "Current geometry: ${curr_x},${curr_y} ${curr_width}x${curr_height}"
            
            # Animate slide up first
            animate_slide_up "$TERMINAL_ADDR" "$curr_x" "$curr_y" "$curr_width" "$curr_height"
            
            # Sequence commands properly
            sleep 0.05
            hyprctl dispatch pin "address:$TERMINAL_ADDR" >/dev/null 2>&1  # Unpin (toggle)
            sleep 0.05
            hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR" >/dev/null 2>&1
        else
            debug_echo "Could not get window geometry, moving to scratchpad without animation"
            hyprctl dispatch pin "address:$TERMINAL_ADDR" >/dev/null 2>&1
            sleep 0.05
            hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR" >/dev/null 2>&1
        fi
    fi
else
    debug_echo "No existing terminal found, creating new one"
    if spawn_terminal; then
        TERMINAL_ADDR=$(get_terminal_address)
        if [ -n "$TERMINAL_ADDR" ]; then
            sleep 0.1
            hyprctl dispatch focuswindow "address:$TERMINAL_ADDR" >/dev/null 2>&1
        else
            debug_echo "Failed to get terminal address after spawning"
        fi
    else
        debug_echo "Failed to spawn new terminal"
    fi
fi