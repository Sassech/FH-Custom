#!/bin/bash
# ZSH and oh-my-zsh #

zsh=(
  lsd
  fzf
  mercurial
  zsh 
  util-linux
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh.log"

# Check if the log file already exists, if yes, append a counter to make it unique
COUNTER=1
while [ -f "$LOG" ]; do
  LOG="Install-Logs/install-$(date +%d-%H%M%S)_${COUNTER}_zsh.log"
  ((COUNTER++))
done

# Installing zsh packages
printf "${NOTE} Installing core zsh packages...${RESET}\n"
for ZSHP in "${zsh[@]}"; do
  install_package "$ZSHP"
done

printf "\n%.0s" {1..1}

# Install Oh My Zsh, plugins, and set zsh as default shell
if command -v zsh >/dev/null; then
  printf "${NOTE} Installing ${SKY_BLUE}Oh My Zsh and plugins${RESET} ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then  
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended  	       
  else
    echo "${INFO} Directory .oh-my-zsh already exists. Skipping re-installation." 2>&1 | tee -a "$LOG"
  fi
  
  # Install plugins and themes directly (minimal installation - always install)
  printf "${NOTE} Installing zsh-autosuggestions plugin...\n"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>&1 | tee -a "$LOG" || echo "${INFO} zsh-autosuggestions already installed." 2>&1 | tee -a "$LOG"

  printf "${NOTE} Installing zsh-syntax-highlighting plugin...\n"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>&1 | tee -a "$LOG" || echo "${INFO} zsh-syntax-highlighting already installed." 2>&1 | tee -a "$LOG"

  printf "${NOTE} Installing Powerlevel10k theme...\n"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>&1 | tee -a "$LOG" || echo "${INFO} Powerlevel10k already installed." 2>&1 | tee -a "$LOG"

  # Copy configuration files directly (always overwrite)
  printf "${NOTE} Installing zsh configuration files...\n"
  cp -f 'assets/.zshrc' ~/
  cp -f 'assets/.zprofile' ~/
  cp -f 'assets/.p10k.zsh' ~/
  echo "${OK} Configuration files installed successfully." 2>&1 | tee -a "$LOG"

  # Check if the current shell is zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "${NOTE} Changing default shell to ${MAGENTA}zsh${RESET}..."
    printf "\n%.0s" {1..2}

    # Loop to ensure the chsh command succeeds
    while ! chsh -s "$(command -v zsh)"; do
      echo "${ERROR} Authentication failed. Please enter the correct password." 2>&1 | tee -a "$LOG"
      sleep 1
    done

    printf "${INFO} Shell changed successfully to ${MAGENTA}zsh${RESET}" 2>&1 | tee -a "$LOG"
  else
    echo "${NOTE} Your shell is already set to ${MAGENTA}zsh${RESET}."
  fi

fi

# copy additional oh-my-zsh themes from assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
    cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >> "$LOG" 2>&1
fi

printf "\n%.0s" {1..2}