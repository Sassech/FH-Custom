#!/usr/bin/env bash
# Versión corta: asume `kitty` por defecto, conserva logging y comprobaciones básicas.

LOGFILE="/tmp/rmpcLauncher.log"
echo "rmpcLauncher start: $(date -Iseconds)" >> "$LOGFILE"

# Asegura PATH común de usuario
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Comprueba rmpc
RPATH="$(command -v rmpc 2>/dev/null || true)"
if [ -z "$RPATH" ]; then
	echo "rmpc no encontrado en PATH" >> "$LOGFILE"
	exit 127
fi

echo "rmpc found: $RPATH" >> "$LOGFILE"

# Si hay TTY, ejecuta directamente
if [ -t 1 ]; then
	"$RPATH" >> "$LOGFILE" 2>&1 &
	echo "Launched directly, pid=$!" >> "$LOGFILE"
	exit 0
fi

# Preferir kitty; si no existe, usar el primer emulador disponible
TERMS=(kitty alacritty gnome-terminal konsole xterm)
TERM_CMD=""
for t in "${TERMS[@]}"; do
	if command -v "$t" >/dev/null 2>&1; then
		TERM_CMD="$t"
		break
	fi
done

if [ -z "$TERM_CMD" ]; then
	echo "No terminal found to launch rmpc" >> "$LOGFILE"
	exit 1
fi

echo "Launching via $TERM_CMD" >> "$LOGFILE"
case "$TERM_CMD" in
	gnome-terminal)
		"$TERM_CMD" -- "$RPATH" >> "$LOGFILE" 2>&1 &
		;;
	konsole)
		"$TERM_CMD" -e "$RPATH" >> "$LOGFILE" 2>&1 &
		;;
	*)
		"$TERM_CMD" -e "$RPATH" >> "$LOGFILE" 2>&1 &
		;;
esac

echo "Launched, pid=$!" >> "$LOGFILE"
exit 0
