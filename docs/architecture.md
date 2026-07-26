# Architecture

## Overview

This stack runs entirely inside **one Ubuntu LXC container** on top of Proxmox VE. All services (Zabbix, Grafana, MariaDB, Nginx, PHP-FPM) live together in that single container.

## Diagram

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

## Components

| Layer | Component | Role |
|---|---|---|
| Network | Router (10.0.10.1) | Provides internet + LAN routing |
| Hypervisor | Proxmox VE 8.4 | Hosts the LXC container |
| Container | Ubuntu 22.04 LXC (`noc-monitor`, 10.0.10.204) | Runs the whole monitoring stack |
| Data collection | Zabbix Server 7.0 + Zabbix Agent | Collects metrics from monitored hosts |
| Database | MariaDB | Stores Zabbix historical and configuration data |
| Web layer | Nginx + PHP 8.1-FPM | Serves the Zabbix web frontend on port 2888 |
| Visualization | Grafana 12 + Zabbix plugin | Builds dashboards from Zabbix data on port 3000 |

## Data Flow

1. Monitored devices/hosts send data to the **Zabbix Agent** or are polled directly by **Zabbix Server**.
2. Zabbix Server stores collected data in **MariaDB**.
3. The **Zabbix web frontend** (Nginx + PHP-FPM) reads from MariaDB to display the Zabbix UI.
4. **Grafana** connects to Zabbix via the **Zabbix plugin** (which talks to the Zabbix API) to build dashboards.

## Why a Single LXC Container?

- Low resource usage — fits comfortably on a 4 GB RAM host.
- Simple to back up and restore as one unit.
- Easy to snapshot/clone in Proxmox.
- Good fit for small networks or homelabs where a full multi-VM setup is unnecessary.
