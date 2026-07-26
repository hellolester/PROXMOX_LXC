# Troubleshooting

Common problems encountered while building this stack, and how to fix them.

---

## 1. Proxmox Subscription Error

**Error:**
```
401 Unauthorized
```
This happens when `apt update` tries to use the enterprise repository without a paid subscription.

**Solution:**
Disable the enterprise repo and use the free no-subscription repo instead.

```bash
nano /etc/apt/sources.list.d/pve-enterprise.list
```
Comment out or remove its contents, then create:
```bash
nano /etc/apt/sources.list.d/pve-no-subscription.list
```
With:
```
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
```
Then:
```bash
apt update
```

---

## 2. DNS Failure

**Error:**
```
Temporary failure resolving archive.ubuntu.com
```

**Cause:** Internet connectivity works, but the container cannot resolve domain names.

**Solution:**
```bash
nano /etc/resolv.conf
```
Add:
```
nameserver 10.0.10.1
nameserver 1.1.1.1
nameserver 8.8.8.8
```
Test with:
```bash
ping 8.8.8.8
ping archive.ubuntu.com
```

---

## 3. Zabbix Database Import Interrupted

**Error:**
```
ERROR 1317 (70100): Query execution was interrupted
```
Caused by pressing `CTRL+C` during the long-running database import.

**Follow-up error on retry:**
```
ERROR 1050 (42S01): Table 'role' already exists
```
This happens because the database was left in a partially-imported state.

**Solution:** Drop and recreate the database, then re-import from scratch — do not interrupt the import this time.

```bash
mysql -uroot -p -e "DROP DATABASE zabbix; CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -uroot -p -e "GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

---

## 4. Grafana Zabbix Plugin Missing

**Problem:** Plugin installs successfully but does not appear in the Grafana UI.

**Cause:** The plugin is unsigned, and Grafana blocks unsigned plugins by default.

**Solution:**
```bash
nano /etc/grafana/grafana.ini
```
Add:
```ini
[plugins]
allow_loading_unsigned_plugins = alexanderzobnin-zabbix-app
```
Then restart:
```bash
systemctl restart grafana-server
```

---

## Quick Reference Table

| Symptom | Likely Cause | Fix |
|---|---|---|
| `401 Unauthorized` on `apt update` | Enterprise repo enabled without subscription | Switch to no-subscription repo |
| `Temporary failure resolving archive.ubuntu.com` | Missing/broken DNS config | Add DNS servers to `/etc/resolv.conf` |
| `ERROR 1317` during DB import | Import interrupted (CTRL+C) | Recreate database, re-import fully |
| `ERROR 1050 Table 'role' already exists` | Partial import left old tables | Drop database, recreate, re-import |
| Grafana plugin not visible | Unsigned plugin blocked | Allow unsigned plugin in `grafana.ini` |
