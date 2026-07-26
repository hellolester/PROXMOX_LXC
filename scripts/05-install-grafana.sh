#!/bin/bash
set -e

# ==========================================================
# Script: 05-install-grafana.sh
# Purpose: Download and install Grafana 12, then enable and
#          start the service.
# Run this INSIDE the noc-monitor LXC container.
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
GRAFANA_VERSION="12.0.0"
GRAFANA_DEB="grafana_${GRAFANA_VERSION}_amd64.deb"
GRAFANA_URL="https://dl.grafana.com/oss/release/${GRAFANA_DEB}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Installing dependencies..."
apt-get install -y apt-transport-https wget gnupg 2>&1 | tee -a "$LOG_FILE"

log "Downloading Grafana ${GRAFANA_VERSION}..."
cd /tmp
wget -q "$GRAFANA_URL" -O "$GRAFANA_DEB"

log "Installing Grafana..."
dpkg -i "$GRAFANA_DEB"

log "Reloading systemd and enabling Grafana service..."
systemctl daemon-reload
systemctl enable grafana-server

log "Starting Grafana service..."
systemctl start grafana-server

log "Checking Grafana status..."
systemctl status grafana-server --no-pager | tee -a "$LOG_FILE"

log "Grafana installation complete. Visit http://<container-ip>:3000 (default login: admin/admin)."
