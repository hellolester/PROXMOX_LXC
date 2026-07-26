# Backup and Restore

## What Gets Backed Up

| Item | Location |
|---|---|
| Zabbix database | MariaDB `zabbix` database |
| Zabbix server config | `/etc/zabbix/zabbix_server.conf` |
| Grafana configuration | `/etc/grafana/` |

Backups are stored in:
```
/backup/YYYY-MM-DD/
```

---

## Running a Backup

Use the provided script:

```bash
bash scripts/backup.sh
```

This will:
1. Create a dated folder under `/backup/`.
2. Dump the Zabbix MariaDB database to a `.sql.gz` file.
3. Copy the Zabbix server config file.
4. Copy the entire Grafana config directory.

---

## Manual Backup (if needed)

**Backup the Zabbix database:**
```bash
mysqldump -uzabbix -p zabbix | gzip > /backup/$(date +%F)/zabbix-db.sql.gz
```

**Backup Zabbix config:**
```bash
cp /etc/zabbix/zabbix_server.conf /backup/$(date +%F)/
```

**Backup Grafana config:**
```bash
cp -r /etc/grafana /backup/$(date +%F)/grafana-config
```

---

## Restoring from a Backup

**Restore the Zabbix database:**
```bash
zcat /backup/YYYY-MM-DD/zabbix-db.sql.gz | mysql -uzabbix -p zabbix
```

**Restore Zabbix config:**
```bash
cp /backup/YYYY-MM-DD/zabbix_server.conf /etc/zabbix/zabbix_server.conf
systemctl restart zabbix-server
```

**Restore Grafana config:**
```bash
cp -r /backup/YYYY-MM-DD/grafana-config/* /etc/grafana/
systemctl restart grafana-server
```

---

## Recommended Backup Schedule

- **Monthly:** Full backup using `scripts/backup.sh`.
- **Before any upgrade or major change:** Manual backup + Proxmox container snapshot.
- **Test restores periodically** to confirm backups are valid.
