#!/bin/bash
# SDDM themes - Install all local themes

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1

# Source global functions
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh" || exit 1

# Setup
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm_theme.log"
SDDM_THEMES_DIR="$PARENT_DIR/sddm-themes"
SDDM_CONF="/etc/sddm.conf"

printf "${INFO} Installing ${SKY_BLUE}SDDM themes${RESET}\n\n"

# Create destination directories
sudo mkdir -p /usr/share/sddm/themes /usr/share/sddm/faces

# Install themes
installed=0
themes=()
declare -A install_map

for theme_dir in "$SDDM_THEMES_DIR"/*; do
  theme_name=$(basename "$theme_dir")

  # Determine install directory name. If theme provides install.sh with a target path,
  # prefer that target (e.g. some themes expect to be installed into 'silent' instead of their repo folder name).
  install_name="$theme_name"
  if [ -f "$theme_dir/install.sh" ]; then
    # Try to extract first occurrence of /usr/share/sddm/themes/<name>
    target=$(grep -oP '/usr/share/sddm/themes/[^"'"'"'"'"'"' ]+' "$theme_dir/install.sh" | head -n1 || true)
    if [ -n "$target" ]; then
      install_name=$(basename "$target")
    fi
  fi

  themes+=("$install_name")
  install_map["$theme_name"]="$install_name"

  printf "${NOTE} Installing: ${YELLOW}$theme_name -> /usr/share/sddm/themes/$install_name${RESET}\n"

  sudo rm -rf "/usr/share/sddm/themes/$install_name"
  sudo cp -r "$theme_dir" "/usr/share/sddm/themes/$install_name" &>> "$LOG"

  echo "${OK} - Installed successfully"
  ((installed++))

  # Copy faces (avatars) into the global faces directory (not inside themes)
  if [ -d "$theme_dir/faces" ]; then
    # Only copy files if there are any to avoid cp errors
    shopt -s nullglob
    face_files=("$theme_dir/faces"/*)
    if [ ${#face_files[@]} -gt 0 ]; then
      sudo cp -r "$theme_dir/faces"/* /usr/share/sddm/faces/ &>> "$LOG" || true
      echo "${OK} - Faces copied for $install_name" &>> "$LOG"
    else
      echo "[NOTE] No face files in $theme_dir/faces" &>> "$LOG"
    fi
    shopt -u nullglob
  else
    echo "[NOTE] No faces directory for theme $theme_name" &>> "$LOG"
  fi
  echo
done

printf "${OK} Installed ${MAGENTA}$installed${RESET} themes\n\n"

# Set default theme
default_theme="SilentSDDM-Rei"
[[ ! " ${themes[@]} " =~ " ${default_theme} " ]] && default_theme="${themes[0]}"

printf "${INFO} Setting default: ${YELLOW}$default_theme${RESET}\n"

# Backup and configure SDDM
[ -f "$SDDM_CONF" ] && sudo cp "$SDDM_CONF" "$SDDM_CONF.bak" &>> "$LOG" || sudo touch "$SDDM_CONF"

# Configure theme
if grep -q '^\[Theme\]' "$SDDM_CONF"; then
  sudo sed -i "/^\[Theme\]/,/^\[/{s/Current=.*/Current=$default_theme/}" "$SDDM_CONF"
  grep -q 'Current=' "$SDDM_CONF" || sudo sed -i "/^\[Theme\]/a Current=$default_theme" "$SDDM_CONF"
else
  echo -e "\n[Theme]\nCurrent=$default_theme" | sudo tee -a "$SDDM_CONF" > /dev/null
fi

# Configure virtual keyboard
if grep -q '^\[General\]' "$SDDM_CONF"; then
  grep -q 'InputMethod=' "$SDDM_CONF" && \
    sudo sed -i '/^\[General\]/,/^\[/{s/InputMethod=.*/InputMethod=qtvirtualkeyboard/}' "$SDDM_CONF" || \
    sudo sed -i '/^\[General\]/a InputMethod=qtvirtualkeyboard' "$SDDM_CONF"
else
  echo -e "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$SDDM_CONF" > /dev/null
fi

echo "${OK} - Configuration updated" | tee -a "$LOG"

# Install fonts (always present)
echo
printf "${NOTE} Installing ${YELLOW}JetBrains Mono Nerd Font${RESET}\n"

sudo cp -r "$HOME/.local/share/fonts/JetBrainsMonoNerd" /usr/local/share/fonts/ &>> "$LOG"
echo "${OK} - Fonts installed"
fc-cache -fv &>> "$LOG"

echo
echo "${OK} - ${MAGENTA}Installation complete!${RESET}"
echo "${INFO} - Default theme: ${YELLOW}$default_theme${RESET}"
echo "${INFO} - Change theme: ${SKY_BLUE}SUPER+SHIFT+D${RESET}"
echo
