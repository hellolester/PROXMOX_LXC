#!/bin/bash
set -e

# ==========================================================
# Script: 04-install-zabbix.sh
# Purpose: Install Zabbix Server 7.0, Agent, MariaDB, Nginx,
#          PHP-FPM, create the database, and import the schema.
# Run this INSIDE the noc-monitor LXC container.
# ==========================================================

LOG_FILE="/var/log/noc-monitor-setup.log"
ZABBIX_REPO_DEB="zabbix-release_7.0-1+ubuntu22.04_all.deb"
ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/${ZABBIX_REPO_DEB}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Prompt for a database password instead of hardcoding one
read -s -p "Enter a password to create for the Zabbix DB user: " DB_PASSWORD
echo
if [ -z "$DB_PASSWORD" ]; then
    echo "Password cannot be empty. Aborting."
    exit 1
fi

log "Adding Zabbix repository..."
cd /tmp
wget -q "$ZABBIX_REPO_URL" -O "$ZABBIX_REPO_DEB"
dpkg -i "$ZABBIX_REPO_DEB"
apt update 2>&1 | tee -a "$LOG_FILE"

log "Installing Zabbix server, frontend, agent, and Nginx/PHP-FPM support..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent 2>&1 | tee -a "$LOG_FILE"

log "Installing MariaDB..."
apt install -y mariadb-server 2>&1 | tee -a "$LOG_FILE"
systemctl enable --now mariadb

log "Creating Zabbix database and user..."
mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS zabbix character set utf8mb4 collate utf8mb4_bin;
CREATE USER IF NOT EXISTS zabbix@localhost IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

log "Importing Zabbix database schema (this can take a few minutes, do NOT interrupt)..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"${DB_PASSWORD}" zabbix

log "Configuring Zabbix server DB password..."
sed -i "s/^# DBPassword=.*/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
if ! grep -q "^DBPassword=" /etc/zabbix/zabbix_server.conf; then
    echo "DBPassword=${DB_PASSWORD}" >> /etc/zabbix/zabbix_server.conf
fi

log "Configuring Zabbix frontend to listen on port 2888..."
sed -i "s/listen\s*80;/listen 2888;/" /etc/zabbix/nginx.conf || true

log "Starting and enabling services..."
systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm

log "Zabbix installation complete. Visit http://<container-ip>:2888/zabbix to finish setup."
