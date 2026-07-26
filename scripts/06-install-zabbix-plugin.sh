#!/bin/bash
set -e

# ==========================================================
# Script: 06-install-zabbix-plugin.sh
# Purpose: Install the Grafana Zabbix plugin, allow it to load
#          as an unsigned plugin, and restart Grafana.
# Run this INSIDE the noc-monitor LXC container.
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
PLUGIN_ID="alexanderzobnin-zabbix-app"
GRAFANA_INI="/etc/grafana/grafana.ini"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

log "Installing Grafana Zabbix plugin ($PLUGIN_ID)..."
grafana-cli plugins install "$PLUGIN_ID" 2>&1 | tee -a "$LOG_FILE"

log "Verifying plugin installation..."
grafana-cli plugins ls | tee -a "$LOG_FILE"

log "Allowing unsigned plugin in grafana.ini..."
if grep -q "^\[plugins\]" "$GRAFANA_INI"; then
    # [plugins] section exists, ensure allow_loading_unsigned_plugins is set
    if grep -q "^allow_loading_unsigned_plugins" "$GRAFANA_INI"; then
        sed -i "s/^allow_loading_unsigned_plugins.*/allow_loading_unsigned_plugins = ${PLUGIN_ID}/" "$GRAFANA_INI"
    else
        sed -i "/^\[plugins\]/a allow_loading_unsigned_plugins = ${PLUGIN_ID}" "$GRAFANA_INI"
    fi
else
    # [plugins] section doesn't exist, add it
    cat >> "$GRAFANA_INI" <<EOF

[plugins]
allow_loading_unsigned_plugins = ${PLUGIN_ID}
EOF
fi

log "Restarting Grafana..."
systemctl restart grafana-server

log "Grafana Zabbix plugin installation complete."
