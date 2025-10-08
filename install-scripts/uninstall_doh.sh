#!/bin/bash
# =========================================================
# Uninstall DNS-over-HTTPS (cloudflared) and revert DNS
# =========================================================

set -euo pipefail

LOG="$HOME/cloudflared-uninstall-$(date +%d-%H%M%S).log"
echo "[INFO] Logging to $LOG"

# -------------------------------
# 1️⃣ Stop and disable cloudflared
# -------------------------------
echo "[INFO] Stopping and disabling cloudflared service..." | tee -a "$LOG"
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
sudo rm -f /etc/systemd/system/cloudflared.service
sudo systemctl daemon-reload

# -------------------------------
# 2️⃣ Remove cloudflared package
# -------------------------------
echo "[INFO] Removing cloudflared package..." | tee -a "$LOG"
sudo dnf remove -y cloudflared  &>> "$LOG"

# -------------------------------
# 3️⃣ Remove systemd-resolved override
# -------------------------------
echo "[INFO] Removing systemd-resolved DNS-over-HTTPS config..." | tee -a "$LOG"
sudo rm -f /etc/systemd/resolved.conf.d/dns-over-https.conf

# -------------------------------
# 4️⃣ Revert /etc/resolv.conf
# -------------------------------
echo "[INFO] Reverting /etc/resolv.conf to default..." | tee -a "$LOG"
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# -------------------------------
# 5️⃣ Revert all WiFi connections to use auto DNS
# -------------------------------
echo "[INFO] Reverting DNS settings for all WiFi connections..." | tee -a "$LOG"
wifi_conns=$(nmcli -t -f NAME,TYPE connection show | grep ':wifi' | cut -d: -f1)

for con in $wifi_conns; do
    echo " -> Reverting $con" | tee -a "$LOG"
    sudo nmcli connection modify "$con" ipv4.ignore-auto-dns no
    sudo nmcli connection modify "$con" ipv4.dns ""
    sudo nmcli connection modify "$con" ipv6.ignore-auto-dns no
    sudo nmcli connection modify "$con" ipv6.dns ""
    
    # Reconectar solo si está activa
    if nmcli -t -f NAME connection show --active | grep -q "^$con$"; then
        sudo nmcli connection up "$con"
    fi
done

# -------------------------------
# 6️⃣ Remove future WiFi override
# -------------------------------
echo "[INFO] Removing future WiFi DNS override..." | tee -a "$LOG"
sudo rm -f /etc/NetworkManager/conf.d/force-doh.conf
sudo systemctl restart NetworkManager

# -------------------------------
# 7️⃣ Restart systemd-resolved
# -------------------------------
echo "[INFO] Restarting systemd-resolved..." | tee -a "$LOG"
sudo systemctl restart systemd-resolved

# -------------------------------
# 8️⃣ Verification
# -------------------------------
echo "[INFO] DNS status:" | tee -a "$LOG"
resolvectl status | tee -a "$LOG"

echo "[DONE] Cloudflared and DNS-over-HTTPS uninstalled. DNS reverted. 🎉" | tee -a "$LOG"
