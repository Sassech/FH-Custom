#!/bin/bash
# /* ---- 💫 Simplified upgrade.sh 💫 ---- */  #
# Simplified version for updating local customized configs
# NOTE: requires rsync - FULL REPLACEMENT MODE

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

clear

echo "${SKY_BLUE}This script FULLY updates your Hyprland configs from local files${RESET}"
echo "${YELLOW}ALL current configs will be backed up and replaced${RESET}"
echo "${ERROR}WARNING: This will replace ALL configuration files without exclusions${RESET}"
printf "\n%.0s" {1..1}
read -p "${CAT} Proceed with FULL replacement? (y/n): ${RESET}" proceed

if [ "$proceed" != "y" ]; then
    echo "${NOTE} Update cancelled. No changes made.${RESET}"
    exit 0
fi

# Create centralized backup directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/.config/hyprland-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Create logs directory
mkdir -p Upgrade-Logs
LOG="Upgrade-Logs/upgrade-$TIMESTAMP.log"

# Directories to update (NO EXCLUSIONS)
declare -A directories=(
    ["config/hypr/"]="$HOME/.config/hypr/"
    ["config/kitty/"]="$HOME/.config/kitty/"
    ["config/waybar/"]="$HOME/.config/waybar/"
    ["config/fastfetch/"]="$HOME/.config/fastfetch/"
    ["config/rofi/"]="$HOME/.config/rofi/"
    ["config/swaync/"]="$HOME/.config/swaync/"
    ["config/wlogout/"]="$HOME/.config/wlogout/"
)

# Function to create centralized backup
backup_config() {
    local target="$1"
    local config_name=$(basename "$target")
    local backup_path="$BACKUP_DIR/$config_name"
    
    if [ -d "$target" ]; then
        echo "${NOTE} Backing up $config_name to centralized backup..." | tee -a "$LOG"
        rsync -a --quiet "$target/" "$backup_path/"
        echo "${OK} Backed up: $config_name" | tee -a "$LOG"
    fi
}

# Function to fully replace directory
replace_config() {
    local source="$1"
    local target="$2"
    local config_name=$(basename "$target")
    
    # Check if source exists
    if [ ! -d "$source" ]; then
        echo "${ERROR} Source not found: $source" | tee -a "$LOG"
        return 1
    fi
    
    echo ""
    echo "${SKY_BLUE}Processing: $config_name${RESET}"
    
    # Create backup first
    backup_config "$target"
    
    # Remove existing directory completely
    if [ -d "$target" ]; then
        echo "${NOTE} Removing existing $config_name..." | tee -a "$LOG"
        rm -rf "$target"
    fi
    
    # Create fresh directory and copy new config
    echo "${NOTE} Installing new $config_name..." | tee -a "$LOG"
    mkdir -p "$target"
    rsync -av "$source" "$target" >> "$LOG" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "${OK} Successfully replaced $config_name" | tee -a "$LOG"
    else
        echo "${ERROR} Failed to replace $config_name" | tee -a "$LOG"
        return 1
    fi
}

# Main replacement loop
echo ""
echo "${SKY_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${SKY_BLUE}Starting FULL replacement process...${RESET}"
echo "${SKY_BLUE}Backup location: $BACKUP_DIR${RESET}"
echo "${SKY_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Process all directories
success_count=0
total_count=${#directories[@]}

for source in "${!directories[@]}"; do
    if replace_config "$source" "${directories[$source]}"; then
        ((success_count++))
    fi
done

# Set executable permissions on scripts
echo ""
echo "${NOTE} Setting executable permissions on scripts..." | tee -a "$LOG"
if [ -d "$HOME/.config/hypr/scripts" ]; then
    chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null
    echo "${OK} Hypr scripts permissions set" | tee -a "$LOG"
fi
if [ -d "$HOME/.config/hypr/UserScripts" ]; then
    chmod +x "$HOME/.config/hypr/UserScripts/"* 2>/dev/null
    echo "${OK} User scripts permissions set" | tee -a "$LOG"
fi

# Final summary
echo ""
echo "${SKY_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
if [ $success_count -eq $total_count ]; then
    echo "${OK} FULL replacement completed successfully! ($success_count/$total_count)" | tee -a "$LOG"
else
    echo "${YELLOW} Replacement completed with warnings ($success_count/$total_count)" | tee -a "$LOG"
fi
echo "${SKY_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "${OK} Centralized backup: ${SKY_BLUE}$BACKUP_DIR${RESET}"
echo "${OK} Update log: ${SKY_BLUE}$LOG${RESET}"
echo ""
echo "${YELLOW}All previous configurations backed up in one location${RESET}"
echo "${YELLOW}All new configurations installed without exclusions${RESET}"
echo ""
echo "${NOTE} Restart Hyprland to apply all changes: SUPER + SHIFT + R${RESET}"
printf "\n%.0s" {1..1}
