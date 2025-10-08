#!/bin/bash
# =========================================================
# Setup DNS-over-HTTPS with Cloudflare (cloudflared)
# Applies to all current and future WiFi connections
# =========================================================

set -euo pipefail

LOG="$HOME/cloudflared-setup-$(date +%d-%H%M%S).log"
echo "[INFO] Logging to $LOG"

# -------------------------------
# 1️⃣ Install Cloudflared
# -------------------------------
echo "[INFO] Checking Cloudflare repository..." | tee -a "$LOG"
if ! sudo dnf repolist | grep -q 'cloudflare'; then
    echo "[INFO] Adding Cloudflare repository..." | tee -a "$LOG"
    sudo dnf config-manager addrepo --from-repofile=https://pkg.cloudflare.com/cloudflared.repo | tee -a "$LOG"
else
    echo "[INFO] Cloudflare repository already exists, skipping..." | tee -a "$LOG"
fi

echo "[INFO] Installing cloudflared..." | tee -a "$LOG"
sudo dnf install -y cloudflared &>> "$LOG"


# -------------------------------
# 2️⃣ Create systemd service
# -------------------------------
echo "[INFO] Creating cloudflared systemd service..." | tee -a "$LOG"
sudo tee /etc/systemd/system/cloudflared.service > /dev/null <<'EOF'
[Unit]
Description=Cloudflared DNS-over-HTTPS proxy
After=network.target

[Service]
ExecStart=/usr/bin/cloudflared proxy-dns --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query
Restart=on-failure
User=nobody
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared

# -------------------------------
# 3️⃣ Configure systemd-resolved
# -------------------------------
echo "[INFO] Configuring systemd-resolved..." | tee -a "$LOG"
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/dns-over-https.conf > /dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1
FallbackDNS=1.1.1.1
DNSSEC=yes
Cache=yes
EOF

# -------------------------------
# 4️⃣ Force DNS 127.0.0.1 for all existing WiFi
# -------------------------------
echo "[INFO] Forcing DNS 127.0.0.1 on all WiFi connections..." | tee -a "$LOG"

# Obtener todas las conexiones WiFi guardadas
wifi_conns=$(nmcli -t -f NAME,TYPE connection show | grep ':wifi' | cut -d: -f1)

for con in $wifi_conns; do
    echo " -> Configuring $con" | tee -a "$LOG"
    sudo nmcli connection modify "$con" ipv4.ignore-auto-dns yes
    sudo nmcli connection modify "$con" ipv4.dns "127.0.0.1"
    sudo nmcli connection modify "$con" ipv6.ignore-auto-dns yes
    sudo nmcli connection modify "$con" ipv6.dns "127.0.0.1"

    # Reconectar solo si la conexión está activa
    if nmcli -t -f NAME connection show --active | grep -q "^$con$"; then
        sudo nmcli connection up "$con"
    fi
done


# -------------------------------
# 5️⃣ Force DNS for all future WiFi connections
# -------------------------------
echo "[INFO] Configuring all future WiFi connections..." | tee -a "$LOG"
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/force-doh.conf > /dev/null <<'EOF'
[connection]
ipv4.ignore-auto-dns=true
ipv4.dns=127.0.0.1
ipv6.ignore-auto-dns=true
ipv6.dns=127.0.0.1
EOF
sudo systemctl restart NetworkManager

# -------------------------------
# 6️⃣ Ensure /etc/resolv.conf points to systemd stub
# -------------------------------
echo "[INFO] Updating /etc/resolv.conf..." | tee -a "$LOG"
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# -------------------------------
# 7️⃣ Restart services
# -------------------------------
echo "[INFO] Restarting services..." | tee -a "$LOG"
sudo systemctl restart cloudflared
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager

# -------------------------------
# 8️⃣ Verification
# -------------------------------
echo "[INFO] DNS status:" | tee -a "$LOG"
resolvectl status | tee -a "$LOG"

echo "[INFO] Testing DNS-over-HTTPS with Cloudflare..." | tee -a "$LOG"
dig +short whoami.cloudflare @127.0.0.1 | tee -a "$LOG"

echo "[DONE] DNS-over-HTTPS setup complete! 🎉" | tee -a "$LOG"
