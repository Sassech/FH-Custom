#!/bin/bash
# Auto-extract GTK themes and icons

# Colors
OK="$(tput setaf 2)[OK]$(tput sgr0)"

# Log file
SLOG="install-$(date +%d-%H%M%S)_themes.log"

# Create directories
mkdir -p ~/.icons ~/.themes

# Extract themes (tar.gz)
echo "Extracting GTK themes to ~/.themes..."
for file in theme/*.tar.gz; do
    echo "  Extracting $(basename "$file")..."
    tar -xzf "$file" -C ~/.themes --overwrite
done
echo "$OK GTK themes extracted"

# Extract icons (zip)
echo "Extracting icon themes to ~/.icons..."
for file in icon/*.zip; do
    echo "  Extracting $(basename "$file")..."
    unzip -o -q "$file" -d ~/.icons
done
echo "$OK Icon themes extracted"

echo "$OK All themes and icons installed successfully!" | tee -a "$SLOG"
