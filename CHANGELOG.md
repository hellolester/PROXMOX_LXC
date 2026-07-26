# Changelog

All notable changes to this project are documented here.

## [1.0.0] - 2026-07-26

### Added
- Initial build of NOC monitoring stack on Proxmox VE 8.4.
- Ubuntu 22.04 LTS LXC container (`noc-monitor`, 10.0.10.204).
- Zabbix Server 7.0 with MariaDB backend.
- Zabbix web frontend served via Nginx + PHP 8.1-FPM on port 2888.
- Grafana 12 installed and configured on port 3000.
- Grafana Zabbix plugin (`alexanderzobnin-zabbix-app`) installed.
- Full documentation set: architecture, installation guide, maintenance, troubleshooting, backup/restore, checklist.
- Automation scripts for each build stage (`scripts/01` - `scripts/06`).
- Backup script for database and configuration files.

### Fixed
- DNS resolution failure (`Temporary failure resolving archive.ubuntu.com`) by adding public DNS servers.
- Zabbix database import interruption error (`ERROR 1317`) by recreating the database and re-importing.
- Grafana Zabbix plugin not appearing after install, fixed by allowing unsigned plugins in `grafana.ini`.
