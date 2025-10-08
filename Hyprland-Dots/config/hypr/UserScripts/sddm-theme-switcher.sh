#!/bin/bash
# SDDM Theme Switcher with Rofi and Preview

# SDDM Configuration
THEMES_DIR="/usr/share/sddm/themes"
LOCAL_THEMES_DIR="$HOME/Fedora-Hyprland-JaKooLit-Custom/sddm-themes"
SDDM_CONF="/etc/sddm.conf"

# Directory for swaync icons
iDIR="$HOME/.config/swaync/images"

# Rofi configuration
rofi_theme="$HOME/.config/rofi/config-sddm-theme.rasi"

# Monitor details
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details for icon sizing
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

# Calculate icon size based on monitor
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Get current theme
get_current_theme() {
  if [ -f "$SDDM_CONF" ]; then
    grep "^Current=" "$SDDM_CONF" 2>/dev/null | cut -d'=' -f2 | tr -d ' '
  fi
}

# Find preview image for theme
find_preview_image() {
  local theme_name="$1"
  local theme_path="$THEMES_DIR/$theme_name"
  local local_theme_path="$LOCAL_THEMES_DIR/$theme_name"
  
  # Search for preview images in multiple locations
  local preview_candidates=(
    "$theme_path/preview.png"
    "$theme_path/Preview.png"
    "$theme_path/screenshot.png"
    "$theme_path/Screenshot.png"
    "$theme_path/Previews/1.png"
    "$theme_path/previews/1.png"
    "$theme_path/docs/previews/default.png"
    "$theme_path/assets/bg.jpg"
    "$theme_path/assets/bg.png"
    "$theme_path/backgrounds/default.jpg"
    "$theme_path/backgrounds/default.png"
    "$local_theme_path/preview.png"
    "$local_theme_path/Preview.png"
    "$local_theme_path/Previews/1.png"
    "$local_theme_path/docs/previews/default.png"
    "$local_theme_path/assets/bg.jpg"
    "$local_theme_path/backgrounds/default.jpg"
  )
  
  for preview in "${preview_candidates[@]}"; do
    if [ -f "$preview" ]; then
      echo "$preview"
      return 0
    fi
  done
  
  # If no preview found, try to find any image in the theme directory
  local any_image=$(find "$theme_path" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print -quit 2>/dev/null)
  if [ -n "$any_image" ]; then
    echo "$any_image"
    return 0
  fi
  
  # Check local themes directory
  local any_local_image=$(find "$local_theme_path" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print -quit 2>/dev/null)
  if [ -n "$any_local_image" ]; then
    echo "$any_local_image"
    return 0
  fi
  
  # Return empty if nothing found
  echo ""
}

# Create cache directory for theme previews
CACHE_DIR="$HOME/.cache/sddm_theme_previews"
mkdir -p "$CACHE_DIR"

# Generate cached preview if needed
generate_cached_preview() {
  local preview_path="$1"
  local theme_name="$2"
  local cache_file="$CACHE_DIR/${theme_name}.png"
  
  if [ -z "$preview_path" ] || [ ! -f "$preview_path" ]; then
    # Create a placeholder image
    if command -v convert &>/dev/null; then
      convert -size 800x600 xc:black -pointsize 60 -fill white -gravity center \
        -annotate +0+0 "$theme_name" "$cache_file" 2>/dev/null
      echo "$cache_file"
    else
      echo ""
    fi
    return
  fi
  
  # If preview exists but is too large, resize it
  if [ ! -f "$cache_file" ] || [ "$preview_path" -nt "$cache_file" ]; then
    if command -v convert &>/dev/null; then
      convert "$preview_path" -resize 800x600 "$cache_file" 2>/dev/null
      echo "$cache_file"
    else
      echo "$preview_path"
    fi
  else
    echo "$cache_file"
  fi
}

# Rofi command
rofi_command="rofi -i -show -dmenu -config $rofi_theme -theme-str $rofi_override -p '🎨 Select SDDM Theme'"

# Build menu with themes and previews
menu() {
  local current_theme=$(get_current_theme)
  
  if [ ! -d "$THEMES_DIR" ]; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "SDDM themes directory not found"
    exit 1
  fi
  
  # Get all theme directories
  local themes=()
  while IFS= read -r theme_dir; do
    if [ -d "$theme_dir" ]; then
      theme_name=$(basename "$theme_dir")
      themes+=("$theme_name")
    fi
  done < <(find "$THEMES_DIR" -maxdepth 1 -type d ! -path "$THEMES_DIR")
  
  # Sort themes
  IFS=$'\n' sorted_themes=($(sort <<<"${themes[*]}"))
  unset IFS
  
  # Output themes with preview icons
  for theme_name in "${sorted_themes[@]}"; do
    local preview_image=$(find_preview_image "$theme_name")
    local cached_preview=$(generate_cached_preview "$preview_image" "$theme_name")
    
    # Mark current theme
    if [ "$theme_name" = "$current_theme" ]; then
      local display_name="✓ $theme_name (current)"
    else
      local display_name="  $theme_name"
    fi
    
    # Output in rofi format with icon
    if [ -n "$cached_preview" ] && [ -f "$cached_preview" ]; then
      printf "%s\x00icon\x1f%s\n" "$display_name" "$cached_preview"
    else
      printf "%s\n" "$display_name"
    fi
  done
}

# Apply selected theme
apply_theme() {
  local selected_theme="$1"
  
  # Remove the checkmark and "(current)" text if present
  selected_theme=$(echo "$selected_theme" | sed 's/^✓ //; s/ (current)$//' | xargs)
  
  if [ -z "$selected_theme" ]; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "No theme selected"
    exit 1
  fi
  
  # Check if theme exists
  if [ ! -d "$THEMES_DIR/$selected_theme" ]; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Theme not found: $selected_theme"
    exit 1
  fi
  
  # Backup current configuration
  local backup_file="$SDDM_CONF.backup-$(date +%Y%m%d-%H%M%S)"
  sudo cp "$SDDM_CONF" "$backup_file" 2>/dev/null
  
  # Update theme in sddm.conf
  if grep -q '^\[Theme\]' "$SDDM_CONF"; then
    # Theme section exists, update Current= line
    if grep -q '^\s*Current=' "$SDDM_CONF"; then
      sudo sed -i "/^\[Theme\]/,/^\[/{s/^\s*Current=.*/Current=$selected_theme/}" "$SDDM_CONF"
    else
      # Add Current= line under [Theme]
      sudo sed -i "/^\[Theme\]/a Current=$selected_theme" "$SDDM_CONF"
    fi
  else
    # Theme section doesn't exist, add it
    echo -e "\n[Theme]\nCurrent=$selected_theme" | sudo tee -a "$SDDM_CONF" > /dev/null
  fi
  
  # Notify success
  notify-send -i "$iDIR/check.png" "SDDM Theme Changed" "Theme set to: $selected_theme\n\nChanges will apply on next login"
  
  # Ask if user wants to restart SDDM
  if command -v yad &>/dev/null; then
    if yad --question \
      --text="SDDM theme changed to: $selected_theme\n\nDo you want to restart SDDM now?\n<b>Warning: This will log you out!</b>" \
      --title="Restart SDDM?" \
      --button="Yes:0" \
      --button="No:1" \
      --width=400; then
      sudo systemctl restart sddm
    fi
  fi
}

# Main function
main() {
  # Check for required commands
  if ! command -v rofi &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "rofi not found"
    exit 1
  fi
  
  if ! command -v jq &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "jq not found"
    exit 1
  fi
  
  # Show menu and get selection
  choice=$(menu | $rofi_command)
  
  if [[ -z "$choice" ]]; then
    exit 0
  fi
  
  # Apply selected theme
  apply_theme "$choice"
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
  sleep 0.1
fi

main
