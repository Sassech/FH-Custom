#!/bin/bash
# 

clear

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

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# install whiptails if detected not installed. Necessary for this version
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} - whiptail is not installed. Installing..." | tee -a "$LOG"
    sudo dnf install -y newt
    printf "\n%.0s" {1..1}
fi

clear

# Ask if the user wants to proceed
if ! whiptail --title "Proceed with Installation?" \
    --yesno "Would you like to proceed?" 7 50; then
    echo -e "\n"
    echo "❌ ${INFO} You 🫵 chose ${YELLOW}NOT${RESET} to proceed. ${YELLOW}Exiting...${RESET}" | tee -a "$LOG"
    echo -e "\n"
    exit 1
fi

echo "👌 ${OK} 🇵🇭 ${MAGENTA}KooL..${RESET} ${SKY_BLUE}lets continue with the installation...${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# install pciutils if detected not installed. Necessary for detecting GPU
if ! rpm -q pciutils > /dev/null; then
    echo "pciutils is not installed. Installing..." | tee -a "$LOG"
    sudo dnf install -y pciutils
    printf "\n%.0s" {1..1}
fi

# Path to the install-scripts directory
script_directory=install-scripts

# Function to execute a script if it exists and make it executable
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            env "$script_path"
        else
            echo "Failed to make script '$script' executable." | tee -a "$LOG"
        fi
    else
        echo "Script '$script' not found in '$script_directory'." | tee -a "$LOG"
    fi
}

#################
## Default values for the options (will be overwritten by preset file if available)
gtk_themes="OFF"
bluetooth="OFF"
thunar="OFF"
sddm="OFF"
sddm_theme="OFF"
xdph="OFF"
zsh="OFF"
dots="ON"
input_group="OFF"
nvidia="OFF"

# Function to load preset file
load_preset() {
    if [ -f "$1" ]; then
        echo "✅ Loading preset: $1"
        source "$1"
    else
        echo "⚠️ Preset file not found: $1. Using default values."
    fi
}

# Check if --preset argument is passed
if [[ "$1" == "--preset" && -n "$2" ]]; then
    load_preset "$2"
fi

# List of services to check for active login managers
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Function to check if any login services are active
check_services_running() {
    active_services=()  # Array to store active services
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            active_services+=("$svc")  
        fi
    done

    if [ ${#active_services[@]} -gt 0 ]; then
        return 0  
    else
        return 1  
    fi
}

if check_services_running; then
    active_list=$(printf "%s\n" "${active_services[@]}")

    # Display the active login manager(s) in the whiptail message box
    whiptail --title "Active non-SDDM login manager(s) detected" \
        --msgbox "The following login manager(s) are active:\n\n$active_list\n\nIf you want to install SDDM and SDDM theme, stop and disable the active services above, reboot before running this script\n\nYour option to install SDDM and SDDM theme has now been removed\n\n- Ja " 23 80
fi

# Check if NVIDIA GPU is detected and ask user
nvidia_install="no"
if lspci | grep -i "nvidia" &> /dev/null; then
    if whiptail --title "NVIDIA GPU Detected" --yesno \
        "NVIDIA GPU detected in your system.\n\nThe script will install:\n- akmod-nvidia\n- xorg-x11-drv-nvidia-cuda\n- and other NVIDIA packages\n\nDo you want to configure NVIDIA drivers?" 14 70; then
        nvidia_install="yes"
        echo "${INFO} NVIDIA configuration will be installed." | tee -a "$LOG"
    else
        echo "${INFO} Skipping NVIDIA configuration." | tee -a "$LOG"
    fi
fi

# Check and configure timezone
if command -v timedatectl >/dev/null 2>&1; then
    current_tz=$(timedatectl show --property=Timezone --value)
    printf "\n%.0s" {1..1}
    
    if whiptail --title "Timezone Configuration" --yesno \
        "Your current timezone is: $current_tz\n\nWould you like to change it?" 10 60; then
        
        # Get new timezone from user
        new_tz=$(whiptail --inputbox "Enter your timezone.\n\nExamples:\n• America/Mexico_City\n• America/Argentina/Buenos_Aires\n• Europe/Madrid\n• Europe/London\n• Asia/Tokyo\n\nTo see all available timezones, run:\ntimedatectl list-timezones" 18 70 "$current_tz" 3>&1 1>&2 2>&3)
        
        if [ -n "$new_tz" ]; then
            # Validate timezone
            if timedatectl list-timezones | grep -q "^${new_tz}$"; then
                sudo timedatectl set-timezone "$new_tz"
                echo "${OK} Timezone set to: ${MAGENTA}${new_tz}${RESET}" | tee -a "$LOG"
                whiptail --title "Success" --msgbox "Timezone successfully changed to:\n\n$new_tz" 9 60
            else
                echo "${ERROR} Invalid timezone: ${new_tz}. Keeping ${current_tz}" | tee -a "$LOG"
                whiptail --title "Error" --msgbox "Invalid timezone entered.\n\nKeeping current timezone: $current_tz\n\nTo change it later, run:\nsudo timedatectl set-timezone <timezone>" 12 60
            fi
        else
            echo "${INFO} Timezone configuration cancelled. Keeping ${current_tz}" | tee -a "$LOG"
        fi
    else
        echo "${INFO} Keeping current timezone: ${current_tz}" | tee -a "$LOG"
    fi
else
    echo "${WARN} timedatectl not found. Cannot configure timezone." | tee -a "$LOG"
fi

# Set all options to install automatically
selected_options="gtk_themes bluetooth thunar xdph zsh dots"

# Add nvidia to the list if user accepted
if [ "$nvidia_install" == "yes" ]; then
    selected_options="nvidia $selected_options"
fi

# Add input_group if user is not in the group
if ! groups "$(whoami)" | grep -q '\binput\b'; then
    selected_options="input_group $selected_options"
    echo "${INFO} Adding user to input group for Waybar functionality." | tee -a "$LOG"
fi

# Add SDDM options if no active login manager is found
if ! check_services_running; then
    selected_options="sddm sddm_theme $selected_options"
    echo "${INFO} SDDM login manager will be installed." | tee -a "$LOG"
fi

# Show what will be installed
whiptail --title "Installation Summary" --msgbox "The following components will be installed:\n\n- Hyprland and dependencies\n- GTK themes\n- Bluetooth support\n- Thunar file manager\n- XDG Desktop Portal\n- Zsh with Oh-My-Zsh\n- Customized dotfiles\n- SDDM login manager (if applicable)\n- NVIDIA drivers (if selected)\n- Input group configuration (if needed)\n\nPress OK to continue..." 20 70

echo "👌 ${OK} Proceeding with ${SKY_BLUE}Hyprland Installation...${RESET}" | tee -a "$LOG"

printf "\n%.0s" {1..1}

echo "${INFO} Adding ${SKY_BLUE}some COPR repos...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "copr.sh"

echo "${INFO} Installing ${SKY_BLUE}necessary dependencies...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "00-hypr-pkgs.sh"

echo "${INFO} Installing ${SKY_BLUE}necessary fonts...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh"

echo "${INFO} Installing ${SKY_BLUE}Hyprland...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "hyprland.sh"

echo "${INFO} Installing ${SKY_BLUE}Battery Monitor...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "battery-monitor.sh"

echo "${INFO} Installing ${SKY_BLUE}Temperature Monitor...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "temp-monitor.sh"

echo "${INFO} Installing ${SKY_BLUE}Disk Space Monitor...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "disk-monitor.sh"

# echo "${INFO} Setting up ${SKY_BLUE}DNS-over-HTTPS with Cloudflare...${RESET}" | tee -a "$LOG"
# sleep 1
# execute_script "setup_doh.sh"

# Convert selected options into an array (splitting by spaces)
IFS=' ' read -r -a options <<< "$selected_options"

# Loop through selected options
for option in "${options[@]}"; do
    case "$option" in
        sddm)
            if check_services_running; then
                active_list=$(printf "%s\n" "${active_services[@]}")
                whiptail --title "Error" --msgbox "One of the following login services is running:\n$active_list\n\nPlease stop & disable it or DO not choose SDDM." 12 60
                exec "$0"  
            else
                echo "${INFO} Installing and configuring ${SKY_BLUE}SDDM...${RESET}" | tee -a "$LOG"
                execute_script "sddm.sh"
            fi
            ;;
        nvidia)
            echo "${INFO} Configuring ${SKY_BLUE}nvidia stuff${RESET}" | tee -a "$LOG"
            execute_script "nvidia.sh"
            ;;
        gtk_themes)
            echo "${INFO} Installing ${SKY_BLUE}GTK themes...${RESET}" | tee -a "$LOG"
            execute_script "gtk_themes.sh"
            ;;
        input_group)
            echo "${INFO} Adding user into ${SKY_BLUE}input group...${RESET}" | tee -a "$LOG"
            execute_script "InputGroup.sh"
            ;;
        xdph)
            echo "${INFO} Installing ${SKY_BLUE}xdg-desktop-portal-hyprland...${RESET}" | tee -a "$LOG"
            execute_script "xdph.sh"
            ;;
        bluetooth)
            echo "${INFO} Configuring ${SKY_BLUE}Bluetooth...${RESET}" | tee -a "$LOG"
            execute_script "bluetooth.sh"
            ;;
        thunar)
            echo "${INFO} Installing ${SKY_BLUE}Thunar file manager...${RESET}" | tee -a "$LOG"
            execute_script "thunar.sh"
            execute_script "thunar_default.sh"
            ;;
        sddm_theme)
            echo "${INFO} Downloading & Installing ${SKY_BLUE}Additional SDDM theme...${RESET}" | tee -a "$LOG"
            execute_script "sddm_theme.sh"
            ;;
        zsh)
            echo "${INFO} Installing ${SKY_BLUE}zsh with Oh-My-Zsh...${RESET}" | tee -a "$LOG"
            execute_script "zsh.sh"
            ;;
        dots)
            echo "${INFO} Installing ${SKY_BLUE}customized Hyprland dotfiles...${RESET}" | tee -a "$LOG"
            execute_script "dotfiles-main.sh"
            ;;
        *)
            echo "Unknown option: $option" | tee -a "$LOG"
            ;;
    esac
done

# Perform cleanup
printf "\n${OK} Performing some clean up.\n"
files_to_delete=("JetBrainsMono.tar.xz" "VictorMonoAll.zip" "FantasqueSansMono.zip")
for file in "${files_to_delete[@]}"; do
    if [ -e "$file" ]; then
        echo "$file found. Deleting..." | tee -a "$LOG"
        rm "$file"
        echo "$file deleted successfully." | tee -a "$LOG"
    fi
done

clear


printf "\n%.0s" {1..1}

# Check if hyprland or hyprland-git is installed
if rpm -q hyprland &> /dev/null || rpm -q hyprland-git &> /dev/null; then
    printf "\n ${OK} 👌 Hyprland is installed. However, some essential packages may not be installed. Please see above!"
    printf "\n${CAT} Ignore this message if it states ${YELLOW}All essential packages${RESET} are installed as per above\n"
    sleep 2
    printf "\n%.0s" {1..2}

    printf "${SKY_BLUE}Thank you${RESET} 🫰 for using 🇵🇭 ${MAGENTA}KooL's Hyprland Dots${RESET}. ${YELLOW}Enjoy and Have a good day!${RESET}"
    printf "\n%.0s" {1..2}

    printf "\n${NOTE} You can start Hyprland by typing ${SKY_BLUE}Hyprland${RESET} (IF SDDM is not installed) (note the capital H!).\n"
    printf "\n${NOTE} However, it is ${YELLOW}highly recommended to reboot${RESET} your system.\n\n"

    while true; do
        echo -n "${CAT} Would you like to reboot now? (y/n): "
        read HYP
        HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

        if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
            echo "${INFO} Rebooting now..."
            systemctl reboot 
            break
        elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
            echo "👌 ${OK} You chose NOT to reboot"
            printf "\n%.0s" {1..1}
            # Check if NVIDIA GPU is present
            if lspci | grep -i "nvidia" &> /dev/null; then
                echo "${INFO} HOWEVER ${YELLOW}NVIDIA GPU${RESET} detected. Reminder that you must REBOOT your SYSTEM..."
                printf "\n%.0s" {1..1}
            fi
            break
        else
            echo "${WARN} Invalid response. Please answer with 'y' or 'n'."
        fi
    done
else
    # Print error message if neither package is installed
    printf "\n${WARN} Hyprland is NOT installed. Please check 00_CHECK-time_installed.log and other files in the Install-Logs/ directory..."
    printf "\n%.0s" {1..3}
    exit 1
fi

printf "\n%.0s" {1..2}