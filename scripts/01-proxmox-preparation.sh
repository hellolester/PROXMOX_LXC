#!/bin/bash
set -e

# ==========================================================
# Script: 01-proxmox-preparation.sh
# Purpose: Disable the Proxmox enterprise repo and enable the
#          free no-subscription repo, then update apt.
# Run this ON THE PROXMOX HOST (not inside the LXC).
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
ENTERPRISE_LIST="/etc/apt/sources.list.d/pve-enterprise.list"
NOSUB_LIST="/etc/apt/sources.list.d/pve-no-subscription.list"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Starting Proxmox preparation..."

log "Checking Proxmox version..."
pveversion | tee -a "$LOG_FILE"

# Disable enterprise repository if it exists
if [ -f "$ENTERPRISE_LIST" ]; then
    log "Disabling enterprise repository: $ENTERPRISE_LIST"
    sed -i 's/^deb/#deb/' "$ENTERPRISE_LIST"
else
    log "Enterprise repository file not found, skipping."
fi

# Create no-subscription repository if it doesn't exist
if [ ! -f "$NOSUB_LIST" ]; then
    log "Creating no-subscription repository: $NOSUB_LIST"
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > "$NOSUB_LIST"
else
    log "No-subscription repository already exists, skipping creation."
fi

log "Running apt update..."
apt update 2>&1 | tee -a "$LOG_FILE"

log "Proxmox preparation complete."
