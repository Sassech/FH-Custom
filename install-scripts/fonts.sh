#!/bin/bash
# Fonts Installation Script (Standalone + Cleanup + Reinstall Safe)

# Colores
RESET="\e[0m"
SKY_BLUE="\e[1;36m"
YELLOW="\e[1;33m"
NOTE="[INFO]"
ERROR="[ERROR]"

# Archivos y directorios
LOG_DIR="$HOME/Install-Logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/install-$(date +%d-%H%M%S)_fonts.log"
MARKER="$LOG_DIR/fonts_installed.marker"
FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

# Lista de fuentes del sistema
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

# Verificación de ejecución previa
if [[ -f "$MARKER" ]]; then
    echo -e "${NOTE} Las fuentes ya se instalaron anteriormente."
    read -rp "¿Deseas reinstalarlas? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        echo "Cancelado por el usuario."
        exit 0
    fi
fi

# Función para verificar e instalar paquetes del sistema
install_package() {
    local package="$1"
    if rpm -q "$package" &>/dev/null; then
        echo "$package ya está instalado." | tee -a "$LOG"
    else
        echo -e "\n${NOTE} Instalando ${SKY_BLUE}$package${RESET}..."
        sudo dnf install -y "$package" &>> "$LOG"
        if [[ $? -eq 0 ]]; then
            echo "$package instalado correctamente." | tee -a "$LOG"
        else
            echo -e "${ERROR} No se pudo instalar ${YELLOW}$package${RESET}" | tee -a "$LOG"
        fi
    fi
}

# Función para instalar fuentes Nerd
install_nerd_font() {
    local font_name="$1"
    local url="$2"
    local file_name="${url##*/}"
    local font_dir="$FONTS_DIR/$font_name"

    echo -e "\n${NOTE} Instalando ${SKY_BLUE}$font_name${RESET}..."

    if [[ -d "$font_dir" ]]; then
        echo "$font_name ya está instalado." | tee -a "$LOG"
        return
    fi

    cd "$FONTS_DIR" || return

    if wget -q "$url" -O "$file_name"; then
        mkdir -p "$font_dir"
        if [[ "$file_name" == *.zip ]]; then
            unzip -q "$file_name" -d "$font_dir"
        elif [[ "$file_name" == *.tar.xz ]]; then
            tar -xf "$file_name" -C "$font_dir"
        else
            echo -e "${ERROR} Formato desconocido: $file_name" | tee -a "$LOG"
            return
        fi
        echo "$font_name instalado correctamente." | tee -a "$LOG"
    else
        echo -e "${ERROR} Error al descargar $font_name" | tee -a "$LOG"
    fi

    rm -f "$file_name"  # Limpieza del archivo comprimido
}

# Instalación de paquetes del sistema
echo -e "\n${NOTE} Instalando fuentes del sistema..."
for pkg in "${fonts[@]}"; do
    install_package "$pkg"
done

# Instalación de fuentes Nerd
install_nerd_font "JetBrainsMonoNerd" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
install_nerd_font "FantasqueSansMonoNerd" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip"
install_nerd_font "VictorMono" "https://rubjo.github.io/victor-mono/VictorMonoAll.zip"

# Instalación de fuentes Microsoft
echo -e "\n${NOTE} Instalando fuentes de ${SKY_BLUE}Microsoft${RESET}..."
sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig &>> "$LOG"

if rpm -q msttcore-fonts-installer &>/dev/null; then
    echo "Microsoft Fonts ya están instaladas." | tee -a "$LOG"
else
    if sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm &>> "$LOG"; then
        echo "Microsoft Fonts instaladas correctamente." | tee -a "$LOG"
    else
        echo -e "${ERROR} No se pudo instalar fuentes de ${YELLOW}Microsoft${RESET}" | tee -a "$LOG"
    fi
fi

# Crear /usr/local/share/fonts si no existe (evita warning de fc-cache)
sudo mkdir -p /usr/local/share/fonts

# Limpieza de symlinks cíclicos
echo -e "\n${NOTE} Eliminando enlaces simbólicos rotos o recursivos en ${FONTS_DIR}..."
find "$FONTS_DIR" -type l ! -e -exec rm -v {} \; | tee -a "$LOG"

# Actualización de la caché de fuentes
echo -e "\n${NOTE} Actualizando la caché de fuentes..."
fc-cache -fv | tee -a "$LOG"

# Marcar instalación exitosa
touch "$MARKER"

echo -e "\n${NOTE} Instalación completada. Log guardado en: $LOG"
