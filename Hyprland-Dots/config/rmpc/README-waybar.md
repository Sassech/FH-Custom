# waybar-rmpc

Script para exponer la información de rmpc/mpd al formato JSON que espera Waybar (similar a `playerctl -F`).

Ubicación

- `Hyprland-Dots/config/rmpc/waybar-rmpc` (ejecutable)

Uso en waybar

- En tu sección de módulos, añade un módulo custom que ejecute el script en modo `exec`:

Ejemplo (waybar config.json):
{
"modules-left": ["custom/rmpc"],
"custom/rmpc": {
"exec": "/home/sassech/FH-Custom/Hyprland-Dots/config/rmpc/waybar-rmpc",
"return-type": "json",

```markdown
# waybar-rmpc

Script para exponer la información de rmpc/mpd al formato JSON que espera Waybar (similar a `playerctl -F`).

Ubicación

- `Hyprland-Dots/config/rmpc/waybar-rmpc` (ejecutable)

Uso en waybar

- En tu sección de módulos, añade un módulo custom que ejecute el script en modo `exec`:

Ejemplo (waybar config.json):
{
"modules-left": ["custom/rmpc"],
"custom/rmpc": {
"exec": "/home/sassech/FH-Custom/Hyprland-Dots/config/rmpc/waybar-rmpc",
"return-type": "json",
"interval": 0
}
}

Notas

- El script usa `mpc` para comunicarse con MPD. Asegúrate de tener `mpc` instalado y que MPD esté corriendo y accesible.
- El script bloquea usando `mpc idle` y emite un JSON por línea cada vez que cambia la canción/estado.
- Si `mpc` no está disponible, el script sale con código 0 y no producirá salida.

Formato emitido

- {"text": "Artist Title", "tooltip": "mpd : Title", "alt": "Status", "class": "Status"}

Contribuciones

- Si usas rmpc con una configuración distinta (por ejemplo FIFO de rmpc), puedes adaptar el uso de `mpc` o reemplazar por `rmpc --format` si la herramienta soporta imprimir metadata en línea.

Configuración avanzada

- Personalizar formato: exporta `WAYBAR_RMPC_FORMAT`. Los placeholders soportados: `{artist}`, `{title}`, `{icon}`.
  - Ejemplo: `export WAYBAR_RMPC_FORMAT="{icon} {artist} — {title}"`
- Iconos: exporta `WAYBAR_RMPC_ICONS` con tres iconos separados por comas: `PLAY,PAUSE,STOP`.
  - Ejemplo: `export WAYBAR_RMPC_ICONS="▶,⏸,■"`

Acciones (on-click)

El script acepta una acción como argumento y la ejecuta contra `mpc`. Esto permite enlazar clicks de waybar:

- play-pause / toggle -> alterna reproducción
- next -> siguiente pista
- prev / previous -> anterior pista
- stop -> detener

Ejemplo de uso en `waybar` con on-click (config.json):

"custom/rmpc": {
"exec": "/home/sassech/FH-Custom/Hyprland-Dots/config/rmpc/waybar-rmpc",
"return-type": "json",
"interval": 0,
"format": "{text}",
"on-click": "/home/sassech/FH-Custom/Hyprland-Dots/config/rmpc/waybar-rmpc play-pause"
}

Con esto, al hacer click sobre el módulo, Waybar ejecutará el script con el argumento `play-pause` que llamará a `mpc toggle`.
```
