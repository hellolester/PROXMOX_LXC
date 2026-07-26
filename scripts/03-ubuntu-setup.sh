#!/bin/bash
set -e

# ==========================================================
# Script: 03-ubuntu-setup.sh
# Purpose: Update the system, install base tools, fix DNS,
#          and configure timezone/locale.
# Run this INSIDE the noc-monitor LXC container.
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
TIMEZONE="Asia/Manila"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Updating system..."
apt update 2>&1 | tee -a "$LOG_FILE"
apt upgrade -y 2>&1 | tee -a "$LOG_FILE"

log "Installing base tools..."
apt install -y curl wget nano vim net-tools htop unzip git 2>&1 | tee -a "$LOG_FILE"

log "Checking DNS resolution..."
if ! ping -c 1 archive.ubuntu.com &> /dev/null; then
    log "DNS resolution failed. Configuring /etc/resolv.conf..."
    cat > /etc/resolv.conf <<EOF
nameserver 10.0.10.1
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    log "DNS configuration written."
else
    log "DNS resolution already working."
fi

log "Testing connectivity..."
ping -c 2 8.8.8.8 | tee -a "$LOG_FILE"
ping -c 2 archive.ubuntu.com | tee -a "$LOG_FILE"

log "Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

log "Configuring locale..."
apt install -y locales 2>&1 | tee -a "$LOG_FILE"
locale-gen
update-locale LANG=en_US.UTF-8

log "Ubuntu initial setup complete."
