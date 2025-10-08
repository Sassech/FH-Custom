#!/bin/bash
# start_mpd_cava.sh
# Script para iniciar MPD + Cava de usuario limpio en Fedora
# ----------------------------------------

# 1️⃣ Variables
MPD_CONF="$HOME/.config/mpd/mpd.conf"
FIFO_PATH="/run/user/$UID/mpd.fifo"

echo "🔹 Limpieza de procesos antiguos y sockets..."
# Matar cualquier proceso MPD, rmpc o Cava residual
pkill -9 mpd rmpc cava 2>/dev/null

# Limpiar restos de PID y FIFO
rm -f ~/.config/mpd/pid
rm -f /tmp/mpd.fifo
rm -f "$FIFO_PATH"

# Verificar que puerto 6600 esté libre
if ss -tulpn | grep -q 6600; then
    echo "⚠ Puerto 6600 ocupado, liberando..."
    sudo fuser -k 6600/tcp
fi

echo "🔹 Iniciando MPD..."
# Arrancar MPD en modo no-daemon
mpd --no-daemon "$MPD_CONF" &

# Esperar un segundo para que se cree la FIFO
sleep 1

# Verificar FIFO
if [ -p "$FIFO_PATH" ]; then
    echo "✅ FIFO creada en $FIFO_PATH"
else
    echo "❌ No se creó la FIFO. Revisa mpd.conf"
    exit 1
fi

# Comprobar que MPD está corriendo
if pgrep -x mpd >/dev/null; then
    echo "✅ MPD corriendo (PID $(pgrep -x mpd))"
else
    echo "❌ MPD no arrancó correctamente"
    exit 1
fi

# 2️⃣ Reproducir música (opcional)
echo "🔹 Reproduciendo música..."
mpc update
mpc play

# 3️⃣ Lanzar Cava
echo "🔹 Iniciando visualizador Cava..."
cava &
