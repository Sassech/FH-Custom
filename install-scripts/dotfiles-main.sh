#!/bin/bash
# Hyprland-Dots - Using local modified dotfiles #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi


printf "${NOTE} Installing ${SKY_BLUE}Hyprland Dots${RESET} (using local customized version)....\n"

# Check if Hyprland-Dots directory exists locally
printf "${OK} Using local Hyprland-Dots with your customizations...\n"
cd Hyprland-Dots || { echo "${ERROR} Failed to enter Hyprland-Dots directory"; exit 1; }
chmod +x copy.sh
./copy.sh 

printf "\n%.0s" {1..2}