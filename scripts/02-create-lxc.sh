#!/bin/bash
set -e

# ==========================================================
# Script: 02-create-lxc.sh
# Purpose: Download the Ubuntu 22.04 template and create the
#          noc-monitor LXC container.
# Run this ON THE PROXMOX HOST (not inside the LXC).
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"

# ---- Variables (edit as needed) ----
CTID=204
HOSTNAME="noc-monitor"
CORES=2
MEMORY=2048
SWAP=512
DISK_SIZE=30
STORAGE="local-lvm"
TEMPLATE_STORAGE="local"
BRIDGE="vmbr0"
IP_ADDR="10.0.10.204/24"
GATEWAY="10.0.10.1"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Listing available templates..."
pveam available | tee -a "$LOG_FILE"

log "Downloading Ubuntu 22.04 template..."
TEMPLATE=$(pveam available | grep ubuntu-22.04-standard | awk '{print $2}' | tail -n1)

if [ -z "$TEMPLATE" ]; then
    echo "Could not find an Ubuntu 22.04 template. Aborting."
    exit 1
fi

pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"

log "Creating LXC container $CTID ($HOSTNAME)..."
pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" \
    --hostname "$HOSTNAME" \
    --cores "$CORES" \
    --memory "$MEMORY" \
    --swap "$SWAP" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${IP_ADDR},gw=${GATEWAY}" \
    --unprivileged 1

log "Starting container $CTID..."
pct start "$CTID"

log "Container created and started. Use 'pct enter $CTID' to log in."
log "LXC creation complete."
