#!/bin/bash
# Post-Installation Script for Fedora Hyprland
# Optional components and configurations

clear

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
YELLOW="$(tput setaf 3)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

LOG="Install-Logs/post-install-$(date +%d-%H%M%S).log"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR} This script should ${WARN}NOT${RESET} be executed as root! Exiting..." | tee -a "$LOG"
    exit 1
fi

# Install whiptail if not present
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} Installing whiptail..." | tee -a "$LOG"
    sudo dnf install -y newt
fi

clear

# Welcome message
whiptail --title "Fedora Post-Installation Setup" --msgbox \
"Welcome to the Fedora Post-Installation Setup!\n\n\
This script will help you install optional components:\n\n\
• System firmware and drivers\n\
• Media codecs and hardware acceleration\n\
• Development tools\n\
• Applications\n\
• Performance optimizations\n\n\
Press OK to continue..." 18 70

# Create checklist for optional components
COMPONENTS=$(whiptail --title "Select Components to Install" --checklist \
"Choose what you want to install (Space to select, Enter to confirm):" 20 80 12 \
"codecs" "Video/audio codecs (ffmpeg, GStreamer)" OFF \
"hw_accel" "Hardware video acceleration (VA-API)" OFF \
"baobab" "Disk Usage Analyzer" OFF \
"mpv" "Media Player" OFF \
"steam" "Steam gaming platform" OFF \
"vscode" "Visual Studio Code" OFF \
"git" "Git version control" OFF \
"nodejs" "Node.js + NPM (global config)" OFF \
"java" "Java 17 (Adoptium Temurin)" OFF \
"podman" "Podman and podman-compose" OFF \
"discord" "Discord" OFF \
"mysql_workbench" "MySQL Workbench" OFF \
"teams" "Teams for Linux (unofficial)" OFF \
"docker" "Docker Engine" OFF \
"unity" "Unity Hub + .NET SDK (game engine)" OFF \
"protonvpn" "ProtonVPN" OFF \
3>&1 1>&2 2>&3)

# Check if user cancelled
if [ $? -ne 0 ]; then
    echo "${INFO} Installation cancelled by user." | tee -a "$LOG"
    exit 0
fi

# Performance optimizations checklist
OPTIMIZATIONS=$(whiptail --title "Performance Optimizations" --checklist \
"Select performance optimizations to apply:" 8 70 0 \
3>&1 1>&2 2>&3)

clear

echo "${INFO} Starting post-installation setup..." | tee -a "$LOG"
printf "\n%.0s" {1..1}

# ============================================
# MANDATORY INSTALLATIONS
# ============================================

# 1. WiFi Firmware and NetworkManager
echo "${INFO} Installing WiFi firmware and NetworkManager-wifi..." | tee -a "$LOG"
sudo dnf install -y linux-firmware 2>&1 | tee -a "$LOG"
echo "${INFO} Reloading iwlwifi module..." | tee -a "$LOG"
sudo modprobe -r iwlwifi 2>&1 | tee -a "$LOG"
sudo modprobe iwlwifi 2>&1 | tee -a "$LOG"
sudo dnf install -y NetworkManager-wifi 2>&1 | tee -a "$LOG"
sudo dnf install -y wpa_supplicant 2>&1 | tee -a "$LOG"
echo "${INFO} Restarting NetworkManager..." | tee -a "$LOG"
sudo systemctl restart NetworkManager 2>&1 | tee -a "$LOG"
echo "${OK} WiFi firmware and NetworkManager-wifi installed!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 2. RPM Fusion repositories
echo "${INFO} Installing RPM Fusion repositories..." | tee -a "$LOG"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$LOG"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$LOG"
sudo dnf group upgrade core -y 2>&1 | tee -a "$LOG"
echo "${OK} RPM Fusion repositories installed!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 3. Firmware updates
echo "${INFO} Updating system firmware..." | tee -a "$LOG"
sudo fwupdmgr refresh --force 2>&1 | tee -a "$LOG"
sudo fwupdmgr get-updates 2>&1 | tee -a "$LOG"
sudo fwupdmgr update -y 2>&1 | tee -a "$LOG"
echo "${OK} Firmware update completed!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 4. Brave browser
echo "${INFO} Installing Brave browser..." | tee -a "$LOG"
sudo dnf install dnf-plugins-core -y 2>&1 | tee -a "$LOG"
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>&1 | tee -a "$LOG"
sudo dnf install brave-browser -y 2>&1 | tee -a "$LOG"
echo "${OK} Brave browser installed!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 5. OnlyOffice
echo "${INFO} Installing OnlyOffice..." | tee -a "$LOG"
sudo dnf install -y https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm 2>&1 | tee -a "$LOG"
echo "${OK} OnlyOffice installed!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 6. Disable NetworkManager-wait-online (faster boot)
echo "${INFO} Disabling NetworkManager-wait-online..." | tee -a "$LOG"
sudo systemctl disable NetworkManager-wait-online.service 2>&1 | tee -a "$LOG"
echo "${OK} NetworkManager-wait-online disabled!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 7. TLP for better battery life
echo "${INFO} Installing TLP for better battery life..." | tee -a "$LOG"
# Add TLP repository
sudo dnf install -y https://repo.linrunner.de/fedora/tlp/repos/releases/tlp-release.fc$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$LOG"
# Install TLP
sudo dnf install -y tlp tlp-rdw 2>&1 | tee -a "$LOG"
# Remove conflicting services
sudo dnf remove -y tuned tuned-ppd 2>&1 | tee -a "$LOG"
# Enable TLP
sudo systemctl enable tlp.service 2>&1 | tee -a "$LOG"
# Mask conflicting services
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>&1 | tee -a "$LOG"
# Copy TLP config if exists in sw directory
if [ -f "sw/etc/tlp.conf" ]; then
    echo "${INFO} Copying TLP configuration..." | tee -a "$LOG"
    sudo cp sw/etc/tlp.conf /etc/tlp.conf 2>&1 | tee -a "$LOG"
    echo "${OK} TLP configuration copied!" | tee -a "$LOG"
fi
echo "${OK} TLP installed and configured!" | tee -a "$LOG"
printf "\n%.0s" {1..1}

# 8. Change hostname
NEW_HOSTNAME=$(whiptail --inputbox "Enter new hostname for this computer:" 8 60 "fedora-hyprland" 3>&1 1>&2 2>&3)
if [ -n "$NEW_HOSTNAME" ]; then
    echo "${INFO} Changing hostname to ${NEW_HOSTNAME}..." | tee -a "$LOG"
    sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>&1 | tee -a "$LOG"
    echo "${OK} Hostname changed to ${NEW_HOSTNAME}!" | tee -a "$LOG"
fi
printf "\n%.0s" {1..1}

echo "${OK} Mandatory installations completed!" | tee -a "$LOG"
printf "\n%.0s" {1..2}

# ============================================
# OPTIONAL INSTALLATIONS
# ============================================

# Process selected components
for component in $COMPONENTS; do
    component=$(echo $component | tr -d '"')
    
    case $component in
        codecs)
            echo "${INFO} Installing media codecs..." | tee -a "$LOG"
            sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing 2>&1 | tee -a "$LOG"
            sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 \
                gstreamer1-libav lame\* --exclude=gstreamer1-plugins-bad-free-devel 2>&1 | tee -a "$LOG"
            sudo dnf group install -y multimedia 2>&1 | tee -a "$LOG"
            sudo dnf group install -y sound-and-video 2>&1 | tee -a "$LOG"
            echo "${OK} Media codecs installed!" | tee -a "$LOG"
            ;;
            
        hw_accel)
            echo "${INFO} Installing hardware acceleration..." | tee -a "$LOG"
            sudo dnf install -y ffmpeg-libs libva libva-utils 2>&1 | tee -a "$LOG"
            
            # Check if NVIDIA
            if lspci | grep -i "nvidia" &> /dev/null; then
                if whiptail --title "NVIDIA Detected" --yesno \
                    "NVIDIA GPU detected. Install NVIDIA VA-API driver?" 8 60; then
                    sudo dnf install -y nvidia-vaapi-driver 2>&1 | tee -a "$LOG"
                fi
            fi
            echo "${OK} Hardware acceleration installed!" | tee -a "$LOG"
            ;;

        baobab)
            echo "${INFO} Installing Disk Usage Analyzer (Baobab)..." | tee -a "$LOG"
            sudo dnf install -y baobab 2>&1 | tee -a "$LOG"
            echo "${OK} Disk Usage Analyzer (Baobab) installed!" | tee -a "$LOG"
            ;;

        mpv)
            echo "${INFO} Installing Media Player (MPV)..." | tee -a "$LOG"
            sudo dnf install -y mpv 2>&1 | tee -a "$LOG"
            echo "${OK} Media Player (MPV) installed!" | tee -a "$LOG"
            ;;

        steam)
            echo "${INFO} Installing Steam..." | tee -a "$LOG"
            sudo dnf install -y steam 2>&1 | tee -a "$LOG"
            echo "${OK} Steam installed!" | tee -a "$LOG"
            ;;
            
        vscode)
            echo "${INFO} Installing Visual Studio Code..." | tee -a "$LOG"
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>&1 | tee -a "$LOG"
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' 2>&1 | tee -a "$LOG"
            sudo dnf install -y code 2>&1 | tee -a "$LOG"
            echo "${OK} VS Code installed!" | tee -a "$LOG"
            ;;
            
        git)
            echo "${INFO} Installing Git..." | tee -a "$LOG"
            sudo dnf install -y git 2>&1 | tee -a "$LOG"
            echo "${OK} Git installed!" | tee -a "$LOG"
            ;;
            
        nodejs)
            echo "${INFO} Installing Node.js..." | tee -a "$LOG"
            sudo dnf install -y nodejs --exclude=nodejs-docs 2>&1 | tee -a "$LOG"
            echo "${OK} Node.js installed!" | tee -a "$LOG"
            
            # Configure NPM global packages in user home (no sudo needed)
            echo "${INFO} Configuring NPM for global packages..." | tee -a "$LOG"
            mkdir -p ~/.npm-global 2>&1 | tee -a "$LOG"
            npm config set prefix '~/.npm-global' 2>&1 | tee -a "$LOG"
            
            # Add to PATH in bash if .bashrc exists
            if [ -f ~/.bashrc ]; then
                if ! grep -q "\.npm-global/bin" ~/.bashrc; then
                    echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.bashrc
                    echo "${OK} Added NPM global path to ~/.bashrc" | tee -a "$LOG"
                else
                    echo "${NOTE} NPM global path already in ~/.bashrc" | tee -a "$LOG"
                fi
            fi
            
            # Add to PATH in zsh if .zshrc exists
            if [ -f ~/.zshrc ]; then
                if ! grep -q "\.npm-global/bin" ~/.zshrc; then
                    echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.zshrc
                    echo "${OK} Added NPM global path to ~/.zshrc" | tee -a "$LOG"
                else
                    echo "${NOTE} NPM global path already in ~/.zshrc" | tee -a "$LOG"
                fi
            fi
            
            # Add to PATH in fish if config.fish exists
            if [ -f ~/.config/fish/config.fish ]; then
                if ! grep -q "\.npm-global/bin" ~/.config/fish/config.fish; then
                    fish -c "set -U fish_user_paths \$HOME/.npm-global/bin \$fish_user_paths" 2>&1 | tee -a "$LOG"
                    echo "${OK} Added NPM global path to fish" | tee -a "$LOG"
                else
                    echo "${NOTE} NPM global path already in fish config" | tee -a "$LOG"
                fi
            fi
            
            echo "${OK} NPM configured! Global packages will install to ~/.npm-global" | tee -a "$LOG"
            echo "${NOTE} You may need to restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc)" | tee -a "$LOG"
            ;;
            
        java)
            echo "${INFO} Installing Java 17 (Adoptium)..." | tee -a "$LOG"
            sudo rpm --import https://packages.adoptium.net/artifactory/api/gpg/key/public 2>&1 | tee -a "$LOG"
            sudo tee /etc/yum.repos.d/adoptium.repo <<EOF 2>&1 | tee -a "$LOG"
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
            sudo dnf install -y temurin-17-jdk 2>&1 | tee -a "$LOG"
            echo "${OK} Java 17 installed!" | tee -a "$LOG"
            ;;
            
        discord)
            echo "${INFO} Installing Discord..." | tee -a "$LOG"
            sudo dnf install -y discord 2>&1 | tee -a "$LOG"
            echo "${OK} Discord installed!" | tee -a "$LOG"
            ;;
            
        mysql_workbench)
            echo "${INFO} Installing MySQL Workbench..." | tee -a "$LOG"
            # Download MySQL Workbench
            wget -P /tmp/ https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.42-1.fc40.x86_64.rpm 2>&1 | tee -a "$LOG"
            sudo dnf install -y /tmp/mysql-workbench-community-8.0.42-1.fc40.x86_64.rpm --setopt=install_weak_deps=False 2>&1 | tee -a "$LOG"
            
            # Fix libssh compatibility
            if [ -f /usr/lib64/mysql-workbench/libssh.so.4 ]; then
                sudo mv /usr/lib64/mysql-workbench/libssh.so.4 /usr/lib64/mysql-workbench/libssh.so.4.bak 2>&1 | tee -a "$LOG"
                echo "${OK} MySQL Workbench libssh fixed!" | tee -a "$LOG"
            fi
            
            # Remove unnecessary proj-data packages (geographic data not needed)
            echo "${INFO} Removing unnecessary proj-data packages..." | tee -a "$LOG"
            sudo dnf remove -y proj-data-ar proj-data-at proj-data-au proj-data-be proj-data-br \
                proj-data-ca proj-data-ch proj-data-cz proj-data-de proj-data-dk \
                proj-data-fi proj-data-fr proj-data-hu proj-data-is proj-data-jp \
                proj-data-lv proj-data-nc proj-data-nl proj-data-no proj-data-nz \
                proj-data-pl proj-data-pt proj-data-se proj-data-si proj-data-sk \
                proj-data-uk proj-data-us proj-data-za proj-data-eur 2>&1 | tee -a "$LOG"
            echo "${OK} Unnecessary proj-data packages removed!" | tee -a "$LOG"
            
            rm -f /tmp/mysql-workbench-community-8.0.42-1.fc40.x86_64.rpm
            echo "${OK} MySQL Workbench installed!" | tee -a "$LOG"
            ;;
            
        teams)
            echo "${INFO} Installing Teams for Linux..." | tee -a "$LOG"
            curl -1sLf -o /tmp/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc 2>&1 | tee -a "$LOG"
            sudo rpm --import /tmp/teams-for-linux.asc 2>&1 | tee -a "$LOG"
            sudo curl -1sLf -o /etc/yum.repos.d/teams-for-linux.repo https://repo.teamsforlinux.de/rpm/teams-for-linux.repo 2>&1 | tee -a "$LOG"
            sudo dnf -y install teams-for-linux 2>&1 | tee -a "$LOG"
            rm -f /tmp/teams-for-linux.asc
            echo "${OK} Teams for Linux installed!" | tee -a "$LOG"
            ;;

        podman)
            echo "${INFO} Installing Podman..." | tee -a "$LOG"
            sudo dnf install -y podman podman-compose podman-docker 2>&1 | tee -a "$LOG"
            echo "${OK} Podman installed!" | tee -a "$LOG"
            ;;
            
        docker)
            echo "${INFO} Installing Docker Engine..." | tee -a "$LOG"
            sudo dnf -y install dnf-plugins-core 2>&1 | tee -a "$LOG"
            sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>&1 | tee -a "$LOG"
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee -a "$LOG"
            sudo systemctl enable --now docker 2>&1 | tee -a "$LOG"
            
            # Add user to docker group
            sudo usermod -aG docker $USER 2>&1 | tee -a "$LOG"
            echo "${OK} Docker installed! You may need to log out and back in for group changes." | tee -a "$LOG"
            ;;
            
        unity)
            echo "${INFO} Installing Unity Hub and .NET SDK..." | tee -a "$LOG"
            
            # Create Unity Hub repository
            sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo' 2>&1 | tee -a "$LOG"
            
            # Verify cache
            sudo dnf check-update 2>&1 | tee -a "$LOG"
            
            # Install Unity Hub
            sudo dnf install -y unityhub 2>&1 | tee -a "$LOG"
            echo "${OK} Unity Hub installed!" | tee -a "$LOG"
            
            # Install .NET SDK 9.0 (required for Unity)
            echo "${INFO} Installing .NET SDK 9.0..." | tee -a "$LOG"
            sudo dnf install -y dotnet-sdk-9.0 2>&1 | tee -a "$LOG"
            echo "${OK} .NET SDK 9.0 installed!" | tee -a "$LOG"
            
            # Show installed SDKs and runtimes
            echo "${INFO} Installed .NET SDKs:" | tee -a "$LOG"
            dotnet --list-sdks 2>&1 | tee -a "$LOG"
            echo "${INFO} Installed .NET runtimes:" | tee -a "$LOG"
            dotnet --list-runtimes 2>&1 | tee -a "$LOG"
            ;;
            
        protonvpn)
            echo "${INFO} Installing ProtonVPN..." | tee -a "$LOG"
            wget -P /tmp/ "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm" 2>&1 | tee -a "$LOG"
            sudo dnf install -y /tmp/protonvpn-stable-release-1.0.3-1.noarch.rpm 2>&1 | tee -a "$LOG"
            sudo dnf check-update --refresh 2>&1 | tee -a "$LOG"
            sudo dnf install -y proton-vpn-gnome-desktop 2>&1 | tee -a "$LOG"
            sudo dnf install -y libappindicator-gtk3 gnome-shell-extension-appindicator gnome-extensions-app 2>&1 | tee -a "$LOG"
            rm -f /tmp/protonvpn-stable-release-1.0.3-1.noarch.rpm
            echo "${OK} ProtonVPN installed!" | tee -a "$LOG"
            ;;
    esac
    printf "\n%.0s" {1..1}
done

clear

echo "${OK} Post-installation setup completed!" | tee -a "$LOG"
printf "\n%.0s" {1..2}

# Show summary
whiptail --title "Installation Complete" --msgbox \
"Post-installation setup completed!\n\n\
Check ${LOG} for detailed logs.\n\n\
Some changes may require a reboot to take effect.\n\n\
Installed components are ready to use!" 14 60

# Ask for reboot
if whiptail --title "Reboot System" --yesno \
    "Some changes may require a reboot.\n\nWould you like to reboot now?" 10 60; then
    echo "${INFO} Rebooting system..." | tee -a "$LOG"
    sudo systemctl reboot
else
    echo "${OK} You can reboot later with: sudo systemctl reboot" | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
