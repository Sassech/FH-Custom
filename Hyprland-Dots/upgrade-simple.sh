#!/bin/bash
# 
# for Semi-Manual upgrading your system.
# NOTE: requires rsync 

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

printf "\n%.0s" {1..1}  

echo "${WARNING}A T T E N T I O N !${RESET}"
echo "${SKY_BLUE}This script is meant to manually upgrade your Dots${RESET}"
echo "${YELLOW}NOTE that you should edit this script and assign an Directory or Files exclusion${RESET}"
printf "\n%.0s" {1..1}
echo "${MAGENTA}If you are not sure what you are doing,ran the ${SKY_BLUE}copy.sh${RESET} ${MAGENTA}instead${RESET}"
printf "\n%.0s" {1..1}
read -p "${CAT} - Would you like to proceed (y/n): ${RESET}" proceed

if [ "$proceed" != "y" ]; then
    printf "\n%.0s" {1..1}
    echo "${INFO} Installation aborted. ${SKY_BLUE}No changes in your system.${RESET} ${YELLOW}Goodbye!${RESET}"
    printf "\n%.0s" {1..1}
    exit 1
fi

# Create Directory for Upgrade Logs
if [ ! -d Upgrade-Logs ]; then
    mkdir Upgrade-Logs
fi

LOG="Upgrade-Logs/upgrade-$(date +%d-%H%M%S)_upgrade_dotfiles.log"

# Create a single backup directory with timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_MAIN_DIR="$HOME/.config/backup-before-upgrade-${BACKUP_TIMESTAMP}"
echo "${NOTE} Main backup directory will be: ${BACKUP_MAIN_DIR}" 2>&1 | tee -a "$LOG"

# source and target versions
source_dir="config"
target_dir="$HOME/.config"

# Specify all directories to backup and copy
declare -A directories=(
    ["config/btop"]="$HOME/.config/btop"
    ["config/cava"]="$HOME/.config/cava"
    ["config/fastfetch"]="$HOME/.config/fastfetch"
    ["config/hypr"]="$HOME/.config/hypr"
    ["config/kitty"]="$HOME/.config/kitty"
    ["config/Kvantum"]="$HOME/.config/Kvantum"
    ["config/micro"]="$HOME/.config/micro"
    ["config/mpd"]="$HOME/.config/mpd"
    ["config/qt5ct"]="$HOME/.config/qt5ct"
    ["config/qt6ct"]="$HOME/.config/qt6ct"
    ["config/quickshell"]="$HOME/.config/quickshell"
    ["config/rmpc"]="$HOME/.config/rmpc"
    ["config/rofi"]="$HOME/.config/rofi"
    ["config/swaync"]="$HOME/.config/swaync"
    ["config/wallust"]="$HOME/.config/wallust"
    ["config/waybar"]="$HOME/.config/waybar"
    ["config/wlogout"]="$HOME/.config/wlogout"
)

# Specify root files and wallpapers to copy
declare -A root_items=(

)

# Function to create backup and copy new files
backup_and_copy() {
    local source_dir="$1"
    local target_dir="$2"
    local target_base=$(basename "$target_dir")
    local backup_subdir="${BACKUP_MAIN_DIR}/${target_base}"

    # Create main backup directory if it doesn't exist
    if [ ! -d "$BACKUP_MAIN_DIR" ]; then
        mkdir -p "$BACKUP_MAIN_DIR"
    fi

    # Check if target directory exists and backup
    if [ -d "$target_dir" ]; then
        mv "$target_dir" "$backup_subdir" 2>&1 | tee -a "$LOG"
    fi
    
    # Copy new files from source to target (without exclusions)
    mkdir -p "$target_dir"
    rsync -a "$source_dir/" "$target_dir/" 2>&1 | tee -a "$LOG"
    echo "$OK $target_base copied successfully" 2>&1 | tee -a "$LOG"
}

# Loop through directories and backup/copy
echo "$INFO Starting backup and copy process..." 2>&1 | tee -a "$LOG"
printf "\n%.0s" {1..1}

for source_directory in "${!directories[@]}"; do
    target_directory="${directories[$source_directory]}"
    backup_and_copy "$source_directory" "$target_directory"
done

printf "\n%.0s" {1..1}
echo "$OK All config directories updated successfully!" 2>&1 | tee -a "$LOG"

# Copy root files and wallpapers
echo "$INFO Copying root files and wallpapers..." 2>&1 | tee -a "$LOG"

for source_item in "${!root_items[@]}"; do
    target_item="${root_items[$source_item]}"
    item_base=$(basename "$target_item")
    
    # Backup if exists
    if [ -e "$target_item" ]; then
        backup_location="${BACKUP_MAIN_DIR}/$(basename "$target_item")"
        if [ -d "$target_item" ]; then
            rsync -a "$target_item/" "$backup_location/" 2>&1 | tee -a "$LOG"
        else
            cp "$target_item" "$backup_location" 2>&1 | tee -a "$LOG"
        fi
    fi
    
    # Copy new files
    if [ -d "$source_item" ]; then
        mkdir -p "$target_item"
        rsync -a "$source_item/" "$target_item/" 2>&1 | tee -a "$LOG"
    else
        cp "$source_item" "$target_item" 2>&1 | tee -a "$LOG"
    fi
    echo "$OK $item_base copied successfully" 2>&1 | tee -a "$LOG"
done

printf "\n%.0s" {1..1}
echo "$OK All root files updated successfully!" 2>&1 | tee -a "$LOG"

# Set some files as executable
chmod +x "$HOME/.config/hypr/scripts/"* 2>&1 | tee -a "$LOG"
chmod +x "$HOME/.config/hypr/UserScripts/"* 2>&1 | tee -a "$LOG"
chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>&1 | tee -a "$LOG"
echo "$OK Permissions set successfully" 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..3}
echo "$(tput bold)$(tput setaf 3)ATTENTION!!!! VERY IMPORTANT NOTICE!!!! $(tput sgr0)" 
echo "$(tput bold)$(tput setaf 7)If you updated waybar directory, and you have your own waybar layout and styles $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)Copy those files from the backup: ${BACKUP_MAIN_DIR}/waybar/ $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)All your backups are in: ${BACKUP_MAIN_DIR} $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)Make sure to set your waybar and style before logout or reboot $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)SUPER CTRL B for Waybar Styles and SUPER ALT B for Waybar Layout $(tput sgr0)"
printf "\n%.0s" {1..3}
