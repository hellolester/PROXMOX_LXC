#!/bin/bash
set -e

# ==========================================================
# Script: backup.sh
# Purpose: Back up the Zabbix database, Zabbix server config,
#          and Grafana config to /backup/YYYY-MM-DD/
# Run this INSIDE the noc-monitor LXC container.
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
BACKUP_ROOT="/backup"
DATE_DIR="$(date +%F)"
BACKUP_DIR="${BACKUP_ROOT}/${DATE_DIR}"

ZABBIX_DB_USER="zabbix"
ZABBIX_SERVER_CONF="/etc/zabbix/zabbix_server.conf"
GRAFANA_CONF_DIR="/etc/grafana"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

read -s -p "Enter the Zabbix DB user (${ZABBIX_DB_USER}) password: " DB_PASSWORD
echo

log "Backing up Zabbix database..."
mysqldump -u"${ZABBIX_DB_USER}" -p"${DB_PASSWORD}" zabbix | gzip > "${BACKUP_DIR}/zabbix-db.sql.gz"

log "Backing up Zabbix server config..."
if [ -f "$ZABBIX_SERVER_CONF" ]; then
    cp "$ZABBIX_SERVER_CONF" "${BACKUP_DIR}/zabbix_server.conf"
else
    log "WARNING: $ZABBIX_SERVER_CONF not found, skipping."
fi

log "Backing up Grafana configuration..."
if [ -d "$GRAFANA_CONF_DIR" ]; then
    cp -r "$GRAFANA_CONF_DIR" "${BACKUP_DIR}/grafana-config"
else
    log "WARNING: $GRAFANA_CONF_DIR not found, skipping."
fi

log "Backup complete. Files stored in: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tee -a "$LOG_FILE"
