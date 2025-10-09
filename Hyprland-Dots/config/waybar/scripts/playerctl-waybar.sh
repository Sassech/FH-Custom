#!/usr/bin/env bash
# Script mejorado para mostrar información de reproducción en Waybar
# Prioriza MPD sobre otros reproductores

# Monitorea cambios en playerctl y emite JSON
playerctl -F metadata --format '{"text": "{{artist}} - {{title}}", "tooltip": "{{playerName}}: {{title}}", "alt": "{{status}}", "class": "{{lc(status)}}"}' 2>/dev/null || echo '{"text": "", "tooltip": "No media", "class": "stopped"}'

