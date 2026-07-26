# Proxmox NOC Monitoring Stack

A lightweight Network Operations Center (NOC) monitoring platform built with **Zabbix** and **Grafana**, running inside a single **Ubuntu LXC container** on **Proxmox VE**.

This repository documents the full build process so the server can be rebuilt from scratch at any time.

---

## 1. Project Overview

This project provides a simple, self-hosted monitoring stack for small networks and homelabs.

It runs entirely inside **one Ubuntu 22.04 LXC container** on Proxmox, and includes:

| Component | Purpose |
|---|---|
| Zabbix Server 7.0 | Collects and stores monitoring data |
| Zabbix Agent | Monitors the local container/host |
| MariaDB | Database backend for Zabbix |
| Nginx | Web server for the Zabbix frontend |
| PHP 8.1-FPM | Runs the Zabbix PHP frontend |
| Grafana 12 | Dashboards and visualization |
| Grafana Zabbix Plugin | Connects Grafana to Zabbix data |

The result is a single container that gives you full network monitoring with dashboards, alerting, and historical graphs.

---

## 2. Architecture Diagram

```
Internet
   |
Router
10.0.10.1
   |
Proxmox VE 8.4
   |
Ubuntu LXC
noc-monitor
10.0.10.204
   |
--------------------------------
Zabbix Server
Port 2888

Grafana
Port 3000

MariaDB

Nginx

PHP-FPM
--------------------------------
```

See [docs/architecture.md](docs/architecture.md) for a more detailed breakdown.

---

## 3. Requirements

### Hardware Requirements

| Item | Minimum |
|---|---|
| CPU | Intel i5 3rd Gen (3.6 GHz) |
| RAM | 4 GB |
| Disk | 30 GB free (for LXC) |

### Software Requirements

| Item | Version |
|---|---|
| Proxmox VE | 8.4 |
| Ubuntu Server | 22.04 LTS |
| Zabbix Server | 7.0 |
| Grafana | 12.0.0 |
| MariaDB | Latest stable (repo default) |
| Nginx | Latest stable (repo default) |
| PHP | 8.1-FPM |

### Network Requirements

| Item | Value |
|---|---|
| Router IP | 10.0.10.1 |
| Subnet | 10.0.10.0/24 |
| LXC Hostname | noc-monitor |
| LXC IP | 10.0.10.204 |

---

## 4. Access URLs

| Service | URL |
|---|---|
| Zabbix | http://localhost:port/zabbix |
| Grafana | http://localhost:3000 |

---

## 5. Repository Structure

```
proxmox-noc-monitoring-stack/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── installation-guide.md
│   ├── maintenance.md
│   ├── troubleshooting.md
│   ├── backup-restore.md
│   └── checklist.md
├── scripts/
│   ├── 01-proxmox-preparation.sh
│   ├── 02-create-lxc.sh
│   ├── 03-ubuntu-setup.sh
│   ├── 04-install-zabbix.sh
│   ├── 05-install-grafana.sh
│   ├── 06-install-zabbix-plugin.sh
│   └── backup.sh
├── config/
│   ├── grafana.ini.example
│   ├── nginx.conf.example
│   ├── zabbix-server.conf.example
│   └── mariadb.cnf.example
└── CHANGELOG.md
```

---

## 6. Quick Start

1. Read [docs/installation-guide.md](docs/installation-guide.md) for the full step-by-step build.
2. Run the scripts in the `scripts/` folder **in order**, from `01` to `06`.
3. Check [docs/checklist.md](docs/checklist.md) to confirm everything works.
4. Set up backups using [docs/backup-restore.md](docs/backup-restore.md).

---

## 7. Documentation Index

| Document | Description |
|---|---|
| [architecture.md](docs/architecture.md) | System design and diagram |
| [installation-guide.md](docs/installation-guide.md) | Full step-by-step install |
| [maintenance.md](docs/maintenance.md) | Daily/weekly/monthly tasks |
| [troubleshooting.md](docs/troubleshooting.md) | Known issues and fixes |
| [backup-restore.md](docs/backup-restore.md) | How to back up and restore |
| [checklist.md](docs/checklist.md) | Final verification checklist |

---

## 8. License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
