# Maintenance

Routine tasks to keep the NOC monitoring stack healthy.

---

## Daily

| Task | Command |
|---|---|
| Check services are running | `systemctl status zabbix-server zabbix-agent nginx php8.1-fpm mariadb grafana-server` |
| Check active alerts | Log in to Zabbix → **Monitoring → Problems** |
| Check disk usage | `df -h` |

---

## Weekly

| Task | Command |
|---|---|
| Update packages | `apt update && apt upgrade -y` |
| Review Zabbix server logs | `tail -n 100 /var/log/zabbix/zabbix_server.log` |
| Review Grafana logs | `journalctl -u grafana-server --since "7 days ago"` |
| Review Nginx logs | `tail -n 100 /var/log/nginx/error.log` |

---

## Monthly

| Task | Command / Reference |
|---|---|
| Backup the database and configs | Run `scripts/backup.sh` (see [backup-restore.md](backup-restore.md)) |
| Test restoring from a backup | See "Restore" section in [backup-restore.md](backup-restore.md) |
| Review disk growth trend | `df -h` and check `/var/lib/mysql` size |
| Check for Zabbix/Grafana version updates | `apt list --upgradable` |

---

## Tips

- Always take a Proxmox **snapshot** of the `noc-monitor` container before major changes.
- Keep at least 2-3 recent backups in `/backup/YYYY-MM-DD/`.
- Document any config changes in [CHANGELOG.md](../CHANGELOG.md).
