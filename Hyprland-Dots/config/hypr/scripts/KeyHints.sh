#!/bin/bash
# #

# GK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Check if rofi or yad is running and kill them if they are
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Launch yad with calculated width and height
GDK_BACKEND=$BACKEND yad \
    --center \
    --title="Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Command: \
    --timeout-indicator=bottom \
"ESC" "close this app" "" " = " "SUPER KEY (Windows Key Button)" "(SUPER KEY)" \
" SHIFT K" "Searchable Keybinds" "(Search all Keybinds via rofi)" \
" SHIFT E" "Hyprland Settings Menu" "" \
"" "" "" \
" T" "Terminal" "(kitty)" \
" SHIFT T" "Terminal Desplegable" " Q to close" \
" B" "Navegador" "(Default browser)" \
" A" "Lanzador Aplicaciones" "(rofi-wayland)" \
" E" "Gestor de Archivos" "(Thunar)" \
" S" "Google Search Rofi" "(rofi)" \
" Q" "Cerrar Ventana Actual" "(not kill)" \
" Shift Q " "Forzar Cerrar Ventana Actuak" "(kill)" \
" ALT mouse scroll up/down   " "Zoom Escritorio" "Desktop Magnifier" \
" Alt V" "Clipboard Manager" "(cliphist)" \
" W" "Sleccionar Wallpaper" "(Wallpaper Menu)" \
" CTRL ALT B" "Mostrar/Esconder Waybar" "waybar" \
" CTRL B" "Seleccionar Estilo Waybar" "(waybar styles)" \
" ALT B" "Seleccionar Disposición Waybar" "(waybar layout)" \
" ALT R" "Reload Waybar swaync Rofi" "CHECK NOTIFICATION FIRST!!!" \
" SHIFT N" "Launch Notification Panel" "swaync Notification Center" \
" Shift S" "screenshot region" "(grim + slurp)" \
"ALT Print" "Screenshot active window" "active window only" \
"CTRL ALT P" "power-menu" "(wlogout)" \
"CTRL L" "screen lock" "(hyprlock)" \
"CTRL ALT Del" "Hyprland Exit" "(NOTE: Hyprland Will exit immediately)" \
" SHIFT F" "Fullscreen" "Toggles to full screen" \
" CTL F" "Fake Fullscreen" "Toggles to fake full screen" \
" ALT L" "Toggle Dwindle | Master Layout" "Hyprland Layout" \
" SPACEBAR" "Toggle float" "single window" \
" ALT SPACEBAR" "Toggle all windows to float" "all windows" \
" ALT O" "Toggle Blur" "normal or less blur" \
" CTRL O" "Toggle Opaque ON or OFF" "on active window only" \
" Shift A" "Animations Menu" "Choose Animations via rofi" \
" CTRL R" "Rofi Themes Menu" "Choose Rofi Themes via rofi" \
" CTRL Shift R" "Rofi Themes Menu v2" "Choose Rofi Themes via Theme Selector (modified)" \
" SHIFT G" "Gamemode! All animations OFF or ON" "toggle" \
" ALT E" "Rofi Emoticons" "Emoticon" \
" H" "Launch this Quick Cheat Sheet" "" \
"" "" "" \
"More tips:" "https://github.com/JaKooLit/Hyprland-Dots/wiki" ""\