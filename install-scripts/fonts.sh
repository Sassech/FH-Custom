#!/bin/bash
# FONTS Installation Script

fonts=(
  adobe-source-code-pro-fonts
  fira-code-fonts
  fontawesome-fonts-all
  google-droid-sans-fonts
  google-noto-sans-cjk-fonts
  google-noto-color-emoji-fonts
  google-noto-emoji-fonts
  jetbrains-mono-fonts
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

# Source global functions
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh" || { echo "Failed to source Global_functions.sh"; exit 1; }

LOG="Install-Logs/install-$(date +%d-%H%M%S)_fonts.log"
FONTS_DIR="$HOME/.local/share/fonts"

# Function to download and install nerd font
install_nerd_font() {
    local font_name="$1"
    local download_url="$2"
    local font_dir="$FONTS_DIR/$font_name"
    local file_name="${download_url##*/}"
    
    printf "\n%s - Installing ${SKY_BLUE}$font_name${RESET}...\n" "${NOTE}"
    
    # Download font
    if wget -q "$download_url" -O "$file_name"; then
        rm -rf "$font_dir"
        mkdir -p "$font_dir"
        
        # Extract based on file type
        if [[ "$file_name" == *.zip ]]; then
            unzip -o -q "$file_name" -d "$font_dir"
        elif [[ "$file_name" == *.tar.xz ]]; then
            tar -xJf "$file_name" -C "$font_dir"
        fi
        
        rm -f "$file_name"
        echo "$font_name installed successfully" | tee -a "$LOG"
    else
        echo -e "\n${ERROR} Failed to download ${YELLOW}$font_name${RESET}\n" | tee -a "$LOG"
    fi
}

# Install system fonts
printf "\n%s - Installing system ${SKY_BLUE}fonts${RESET}...\n" "${NOTE}"
for PKG1 in "${fonts[@]}"; do
    install_package "$PKG1" "$LOG"
done

# Install Nerd Fonts
install_nerd_font "JetBrainsMonoNerd" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
install_nerd_font "FantasqueSansMonoNerd" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip"
install_nerd_font "VictorMono" "https://rubjo.github.io/victor-mono/VictorMonoAll.zip"

# Install Microsoft Fonts
printf "\n%s - Installing ${SKY_BLUE}Microsoft Fonts${RESET}...\n" "${NOTE}"
sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig 2>&1 | tee -a "$LOG"

if sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm 2>&1 | tee -a "$LOG"; then
    echo "Microsoft Fonts installed successfully" | tee -a "$LOG"
else
    echo -e "\n${ERROR} Failed to install ${YELLOW}Microsoft Fonts${RESET}\n" | tee -a "$LOG"
fi

# Update font cache
printf "\n%s - Updating font cache...\n" "${NOTE}"
fc-cache -v 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}