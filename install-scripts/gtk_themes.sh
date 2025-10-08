#!/bin/bash
# GTK Themes & ICONS and  Sourcing from a different Repo #

engine=(
    unzip
    #gtk-engine-murrine
)

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

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_themes.log"


# installing engine needed for gtk themes
for PKG1 in "${engine[@]}"; do
    install_package "$PKG1" "$LOG"
done

# Use local GTK themes and icons directory
echo "$NOTE Extracting ${SKY_BLUE}GTK themes and Icons${RESET}..." 2>&1 | tee -a "$LOG"

cd "$PARENT_DIR/GTK-themes-icons"
chmod +x auto-extract.sh
./auto-extract.sh

echo "$OK Extracted GTK Themes & Icons to ~/.icons & ~/.themes directories" 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}