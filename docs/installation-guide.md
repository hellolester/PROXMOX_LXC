# Installation Guide

This guide walks through building the entire NOC monitoring stack from zero, in order. Each step lists **Purpose**, **Command(s)**, and **Expected Result**.

You can run these steps manually, or use the matching scripts in `scripts/` (e.g. Step 1 = `scripts/01-proxmox-preparation.sh`).

---

## Step 1 — Proxmox Preparation

**Purpose:** Check Proxmox version and switch to the free "no-subscription" repository so `apt update` works without an enterprise license.

**Commands:**

```bash
# Check Proxmox version
pveversion
```

```bash
# Disable enterprise repository
nano /etc/apt/sources.list.d/pve-enterprise.list
```
Comment out (or remove) any line inside this file so it is empty/disabled.

```bash
# Create the no-subscription repository
nano /etc/apt/sources.list.d/pve-no-subscription.list
```
Add this line:
```
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
```

```bash
# Update package lists
apt update
```

**Expected Result:** `apt update` completes without the `401 Unauthorized` enterprise repo error.

---

## Step 2 — Create the Ubuntu LXC

**Purpose:** Create the `noc-monitor` container that will host the entire stack.

**Commands:**

```bash
# List available templates
pveam available

# Download the Ubuntu 22.04 template
pveam download local ubuntu-22.04-standard_22.04-*.tar.zst
```

```bash
# Create the LXC container
pct create 204 local:vztmpl/ubuntu-22.04-standard_22.04-*.tar.zst \
  --hostname noc-monitor \
  --cores 2 \
  --memory 2048 \
  --swap 512 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.10.204/24,gw=10.0.10.1 \
  --unprivileged 1
```

```bash
# Start the container
pct start 204

# Enter the container
pct enter 204
```

**Expected Result:** Container `204` (`noc-monitor`) is running with IP `10.0.10.204`, 2 cores, 2048 MB RAM, 512 MB swap, and a 30 GB disk.

---

## Step 3 — Ubuntu Initial Setup

**Purpose:** Update the system and install baseline utilities.

**Commands:**

```bash
apt update
apt upgrade -y
```

```bash
apt install -y curl wget nano vim net-tools htop unzip git
```

**Expected Result:** System is fully updated and common CLI tools are available.

---

## Step 4 — DNS Configuration

**Purpose:** Fix DNS resolution so package downloads work.

**Problem encountered:**
```
Temporary failure resolving archive.ubuntu.com
```
This means the internet connection itself worked, but DNS lookups were failing.

**Solution — edit resolv.conf:**

```bash
nano /etc/resolv.conf
```

Add:
```
nameserver 10.0.10.1
nameserver 1.1.1.1
nameserver 8.8.8.8
```

**Test:**

```bash
ping 8.8.8.8
ping archive.ubuntu.com
```

**Expected Result:** Both pings succeed, confirming both connectivity and DNS resolution work.

---

## Step 5 — Timezone and Locale

**Purpose:** Set correct timezone and locale for accurate logs and timestamps.

**Commands:**

```bash
# Set timezone
timedatectl set-timezone Asia/Manila
```

```bash
# Install and generate locale
apt install locales -y
locale-gen
update-locale LANG=en_US.UTF-8
```

**Expected Result:** `timedatectl` shows `Asia/Manila`, and `locale` shows `en_US.UTF-8`.

---

## Step 6 — Install Zabbix

**Purpose:** Install Zabbix Server 7.0, Agent, and set up the MariaDB database backend.

**Commands:**

```bash
# Add Zabbix repository (example for Ubuntu 22.04)
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_7.0-1+ubuntu22.04_all.deb
apt update
```

```bash
# Install Zabbix server, frontend, and agent
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```

```bash
# Install MariaDB
apt install -y mariadb-server
systemctl enable --now mariadb
```

```bash
# Secure MariaDB (interactive)
mysql_secure_installation
```

```bash
# Create Zabbix database and user
mysql -uroot -p
```
Inside the MySQL prompt:
```sql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by 'YOUR_PASSWORD';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
quit;
```

```bash
# Import the initial schema and data
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

```bash
# Configure the database password in Zabbix server config
nano /etc/zabbix/zabbix_server.conf
```
Set:
```
DBPassword=YOUR_PASSWORD
```

```bash
# Start and enable services
systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm
```

**Expected Result:** Zabbix web installer is reachable at `http://10.0.10.204:2888/zabbix`. See [troubleshooting.md](troubleshooting.md) if the database import is interrupted.

---

## Step 7 — Zabbix Troubleshooting (Database Import)

**Problem:** Pressing `CTRL+C` during the database import interrupted the process, leaving the database partially imported.

**Error:**
```
ERROR 1317 (70100): Query execution was interrupted
```

**Second error on retry:**
```
ERROR 1050 (42S01): Table 'role' already exists
```

**Solution:** Drop and recreate the database, then re-import cleanly.

```bash
mysql -uroot -p -e "DROP DATABASE zabbix; CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -uroot -p -e "GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

**Expected Result:** Import completes fully without interruption.

---

## Step 8 — Install Grafana

**Purpose:** Install Grafana 12 for dashboards and visualization.

**Commands:**

```bash
# Install dependencies
apt-get install -y apt-transport-https wget gnupg
```

```bash
# Download Grafana
wget https://dl.grafana.com/oss/release/grafana_12.0.0_amd64.deb
```

```bash
# Install Grafana
dpkg -i grafana_12.0.0_amd64.deb
```

```bash
# Enable service
systemctl daemon-reload
systemctl enable grafana-server
```

```bash
# Start service
systemctl start grafana-server
```

```bash
# Check status
systemctl status grafana-server
```

**Expected Result:** Grafana is reachable at `http://10.0.10.204:3000` (default login `admin` / `admin`).

---

## Step 9 — Install Grafana Zabbix Plugin

**Purpose:** Let Grafana pull data directly from Zabbix.

**Commands:**

```bash
grafana-cli plugins install alexanderzobnin-zabbix-app
```

```bash
# Verify installation
grafana-cli plugins ls
```

```bash
# Restart Grafana
systemctl restart grafana-server
```

**Expected Result:** Plugin appears in the plugin list. See Step 10 if it doesn't show up in the Grafana UI.

---

## Step 10 — Grafana Plugin Troubleshooting

**Problem:** Plugin is installed but does not appear as an enabled app in the Grafana UI.

**Cause:** Grafana blocks unsigned community plugins by default.

**Solution:**

```bash
nano /etc/grafana/grafana.ini
```

Add or edit:
```ini
[plugins]
allow_loading_unsigned_plugins = alexanderzobnin-zabbix-app
```

```bash
systemctl restart grafana-server
```

**Expected Result:** The Zabbix plugin appears and can be enabled under **Configuration → Plugins** in Grafana.

---

## Next Steps

- Log in to Zabbix and Grafana and change default passwords.
- Configure the Zabbix data source in Grafana using the Zabbix API.
- Review [checklist.md](checklist.md) to confirm the full build.
- Set up backups per [backup-restore.md](backup-restore.md).
