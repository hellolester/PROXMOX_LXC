# Final Checklist

Use this checklist to verify the stack is fully built and working.

## Proxmox / Infrastructure

- [ ] Proxmox no-subscription repository working (`apt update` runs clean)
- [ ] LXC container `noc-monitor` created and running
- [ ] Container has correct IP (10.0.10.204)
- [ ] DNS resolution working inside the container

## Zabbix

- [ ] Zabbix server service running (`systemctl status zabbix-server`)
- [ ] Zabbix agent service running (`systemctl status zabbix-agent`)
- [ ] MariaDB running and `zabbix` database populated
- [ ] Zabbix web frontend accessible at `http://10.0.10.204:2888/zabbix`
- [ ] Logged in to Zabbix and changed default admin password

## Grafana

- [ ] Grafana service running (`systemctl status grafana-server`)
- [ ] Grafana accessible at `http://10.0.10.204:3000`
- [ ] Logged in to Grafana and changed default admin password
- [ ] Zabbix plugin installed (`grafana-cli plugins ls`)
- [ ] Zabbix plugin visible and enabled in Grafana UI
- [ ] Zabbix data source configured in Grafana

## Backups

- [ ] `scripts/backup.sh` runs successfully
- [ ] Backup files exist under `/backup/YYYY-MM-DD/`
- [ ] Restore procedure tested at least once

## Documentation

- [ ] README.md reviewed and accurate
- [ ] CHANGELOG.md updated with latest changes
