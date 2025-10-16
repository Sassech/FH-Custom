#!/bin/bash
# Random logo selector for fastfetch
# Selects a random character logo and updates config.jsonc

CONFIG_DIR="$HOME/.config/fastfetch"
CONFIG_FILE="$CONFIG_DIR/config.jsonc"
LOGO_DIR="$CONFIG_DIR/logo"

# Array of logos with their corresponding character names
declare -A LOGOS=(
    ["john_arknights.png"]="Wiš'adel"
    ["john_endfield.png"]="Perlica"
    ["john_genshin.png"]="Lumine"
    ["john_starrail.png"]="Firefly"
    ["john_wuthering.png"]="Rover"
    ["john_zenless.png"]="Belle"
    ["arknights.png"]="Doctor"
    ["endfield.png"]="Endministrator"
    ["wuthering.png"]="Yangyang"
)

# Get array of available logos
AVAILABLE_LOGOS=()
for logo in "${!LOGOS[@]}"; do
    if [ -f "$LOGO_DIR/$logo" ]; then
        AVAILABLE_LOGOS+=("$logo")
    fi
done

# Check if there are available logos
if [ ${#AVAILABLE_LOGOS[@]} -eq 0 ]; then
    echo "No logos found in $LOGO_DIR"
    exit 1
fi

# Select random logo
RANDOM_INDEX=$((RANDOM % ${#AVAILABLE_LOGOS[@]}))
SELECTED_LOGO="${AVAILABLE_LOGOS[$RANDOM_INDEX]}"
SELECTED_NAME="${LOGOS[$SELECTED_LOGO]}"

# Generate config with selected logo
cat > "$CONFIG_FILE" << EOF
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "kitty-direct",
    "source": "~/.config/fastfetch/logo/$SELECTED_LOGO",
    "padding": {
      "top": 1,
      "left": 2
    }
  },
  "display": {
    "separator": " ✦ ",
    "color": {
      "title": "#FFD700"
    }
  },
  "modules": [
    /* ======= BARRA DE COLORES ARRIBA ======= */
    {
      "type": "colors",
      "paddingLeft": 0,
      "symbol": "circle"
    },

    "break",
    "title",

    /* ======= SECCIÓN 1: INFORMACIÓN DEL SISTEMA ======= */
    {
      "type": "os",
      "key": "🖥  OS      ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
    {
      "type": "kernel",
      "key": "🔧 Kernel  ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FFFF",
      "format": "{1} {2}"
    },
    {
      "type": "wm",
      "key": "🪟 WM      ",
      "keyColor": "#FFFFFF",
      "valueColor": "#FF00FF"
    },
    {
      "type": "shell",
      "key": "💻 Term    ",
      "keyColor": "#FFFFFF",
      "valueColor": "#FFFF00"
    },
    {
      "type": "packages",
      "key": "📦 Packages",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
/*
    {
      "type": "uptime",
      "format": "{2}h {3}m",
      "key": "⏱ Uptime   ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FFFF"
    },
    {
      "type": "command",
      "key": "📅 OS Age  ",
      "text": "birth_install=$(stat -c %W /); current=$(date +%s); days_difference=$(( (current - birth_install) / 86400 )); echo $days_difference days",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
*/
    "break",

    /* ======= SECCIÓN 2: HARDWARE ======= */
    {
      "type": "cpu",
      "key": "⚙️ CPU     ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
    {
      "type": "gpu",
      "key": "🎮 GPU     ",
      "keyColor": "#FFFFFF",
      "valueColor": "#FF00FF"
    },
    {
      "type": "memory",
      "key": "🧠 RAM     ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FFFF"
    },
    {
      "type": "disk",
      "key": "💾 Disk    ",
      "keyColor": "#FFFFFF",
      "valueColor": "#FFFF00"
    },

    "break",

    /* ======= SECCIÓN 3: BATERÍA Y LOCALIZACIÓN ======= */
/*
    {
      "type": "battery",
      "key": "🔋 Battery ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
    {
      "type": "command",
      "key": "☀️ Weather ",
      "text": "curl -s wttr.in/?format=1",
      "keyColor": "#FFFFFF",
      "valueColor": "#FF00FF"
    },*/

    "break",

    /* ======= SECCIÓN 4: RED / IP ======= */
    {
      "type": "wifi",
      "key": "📡 WiFi    ",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
/*
    {
      "type": "command",
      "key": "🌐 IP      ",
      "text": "hostname -I | awk '{print $1}'",
      "keyColor": "#FFFFFF",
      "valueColor": "#00FF00"
    },
*/
    "break",

    /* ======= SECCIÓN 6: BARRA DE COLORES ABAJO ======= */
    {
      "type": "command",
      "key": "★           ",
      "text": "echo '$SELECTED_NAME'",
      "keyColor": "#FFD700",
      "valueColor": "#FFFFFF"
    },
    {
      "type": "colors",
      "paddingLeft": 0,
      "symbol": "circle"
    }
  ]
}
EOF

# Optional: Show which character was selected
# echo "Selected: $SELECTED_NAME ($SELECTED_LOGO)"
