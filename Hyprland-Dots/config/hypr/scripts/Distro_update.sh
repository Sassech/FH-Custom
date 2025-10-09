#!/bin/bash
# #
# Simple bash script to check and will try to update your system

# Local Paths
iDIR="$HOME/.config/swaync/images"

# Detect a terminal to run updates in (prefer kitty), but accept others
TERM_CMD=$(command -v kitty || command -v alacritty || command -v gnome-terminal || command -v konsole || command -v xterm || true)
if [ -z "$TERM_CMD" ]; then
  notify-send -i "$iDIR/error.png" "Need Terminal:" "No supported terminal (kitty, alacritty, gnome-terminal, konsole, xterm) found. Please install one."
  exit 1
fi

# Helper: run a command string inside preferred terminal (synchronously when possible)
run_in_term_or_fallback() {
  local cmd="$1"
  local tb
  tb=$(basename "$TERM_CMD")
  if [ "$tb" = "kitty" ]; then
    # kitty: keep old behaviour, allow complex shell commands
    "$TERM_CMD" -T update bash -lc "$cmd"
  elif [ "$tb" = "gnome-terminal" ]; then
    # newer gnome-terminal supports --wait; try to use it so we block until finished
    if "$TERM_CMD" --help 2>&1 | grep -q -- "--wait"; then
      "$TERM_CMD" --wait -- bash -lc "$cmd"
    else
      "$TERM_CMD" -- bash -lc "$cmd"
    fi
  else
    # alacritty, konsole, xterm typically accept -e
    "$TERM_CMD" -e bash -lc "$cmd"
  fi
}

# Detect distribution and update accordingly
if command -v paru &> /dev/null || command -v yay &> /dev/null; then
  # Arch-based
  if command -v paru &> /dev/null; then
    run_in_term_or_fallback 'paru -Syu'
    notify-send -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  else
    run_in_term_or_fallback 'yay -Syu'
    notify-send -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  fi
elif command -v dnf &> /dev/null; then
  # Fedora-based
  run_in_term_or_fallback 'sudo dnf update --refresh -y'
  notify-send -i "$iDIR/ja.png" -u low 'Fedora system' 'has been updated.'
elif command -v apt &> /dev/null; then
  # Debian-based (Debian, Ubuntu, etc.)
  run_in_term_or_fallback 'sudo apt update && sudo apt upgrade -y'
  notify-send -i "$iDIR/ja.png" -u low 'Debian/Ubuntu system' 'has been updated.'
elif command -v zypper &> /dev/null; then
  # openSUSE-based
  run_in_term_or_fallback 'sudo zypper dup -y'
  notify-send -i "$iDIR/ja.png" -u low 'openSUSE system' 'has been updated.'
else
  # Unsupported distro
  notify-send -i "$iDIR/error.png" -u critical "Unsupported system" "This script does not support your distribution."
  exit 1
fi
