# 🪵 LGTM Stack Starter Kit

> **L**oki · **G**rafana · **T**empo · **M**imir — the complete Grafana observability stack in a single `docker compose up`.

Spin up a full observability backend in seconds. Ships logs from your Docker containers, collects Prometheus metrics, accepts OTLP traces, and provisions dashboards — all pre-configured and ready to explore.

---

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/YOUR_USER/lgtm-stack.git
cd lgtm-stack

# Start everything
make up
# or: docker compose -f compose.yml up -d

# Open Grafana
open http://localhost:3000
# Login: admin / admin
```

That's it. All four data sources are auto-provisioned. Docker container logs start flowing immediately via Promtail.

---

## 📦 What's Inside

| Service | Port | Purpose |
|---|---|---|
| **Grafana** | `:3000` | Dashboards, alerting, exploration |
| **Loki** | `:3100` | Log aggregation (Docker logs via Promtail) |
| **Tempo** | `:3200` | Distributed tracing (OTLP receiver) |
| **Mimir** | `:9009` | Long-term metrics storage (Prometheus compatible) |
| **Prometheus** | `:9090` | Metrics collection & alerting |
| **Promtail** | `:9080` | Ships Docker container logs → Loki |

---

## 🗂️ Project Structure

```
.
├── compose.yml              # Docker Compose stack definition
├── Makefile                 # Convenience commands (make up, make logs, …)
├── config/
│   ├── mimir-local.yaml     # Mimir server config
│   ├── tempo-local.yaml     # Tempo server config
│   └── promtail-config.yaml # Promtail Docker log scraper config
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasources.yaml  # Auto-provisioned data sources
├── .github/
│   └── workflows/
│       └── validate.yml     # CI: validates compose & YAML on push/PR
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🔧 Makefile Reference

| Command | What it does |
|---|---|
| `make up` | Start all services in the background |
| `make down` | Stop and remove all services |
| `make restart` | Down + up (refresh mounts, configs) |
| `make ps` | Show running containers |
| `make status` | Print service URLs |
| `make logs` | Tail logs from all services |
| `make logs-grafana` | Tail logs from a specific service |
| `make clean` | Stop everything and **delete all data** ⚠️ |
| `make pull` | Pull latest Docker images |
| `make shell-grafana` | Open a shell inside a container |
| `make help` | Show all available commands |

---

## 🖥️ Dashboards

Two dashboards are built-in (use the Grafana MCP or API to create them):

| Dashboard | Description |
|---|---|
| **Docker Container Logs** | Log rate, error rate, recent logs, live log stream |
| **Live Docker Containers** | Active container count, container table, log activity, container events |

To create them via the Grafana API:

```bash
# Docker Container Logs
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboards/docker-container-logs.json

# Live Docker Containers
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboards/live-docker-containers.json
```

---

## 🧾 Frappe Cloud Dashboard

A separate, self-contained stack (`compose.frappe.yml`) runs a Grafana that talks to a Frappe/ERPNext site over its REST API, using the [Infinity](https://grafana.com/grafana/plugins/yesoreyeram-infinity-datasource/) data source (Frappe has no native Grafana protocol).

```bash
cp .env.example .env          # then fill in FRAPPE_API_KEY / FRAPPE_API_SECRET
make frappe-up
open http://localhost:3001    # dashboard: "Frappe — Site Overview"
```

Get the credentials from your Frappe site: open your **User** doc → **API Access** → **Generate Keys**. The secret is shown only once.

| Setting | Default |
|---|---|
| `FRAPPE_URL` | `https://teebatkarbala.frappe.cloud` |
| `FRAPPE_GRAFANA_PORT` | `3001` (3000 is used by the LGTM stack) |
| `FRAPPE_PROM_PORT` | `9091` (9090 is used by the LGTM stack) |

### What the stack runs

| Service | Purpose |
|---|---|
| `frappe-grafana` | Dashboards, on `:3001` |
| `frappe-blackbox` | Probes the site over HTTPS every 30s — latency, status code, TLS expiry |
| `frappe-prometheus` | Stores the probe results, 30d retention, on `:9091` |

The Frappe REST API tells you *what happened* (errors, jobs, logins) but not *how fast the site is* — that's why the blackbox exporter is here. Probe targets live in `config/frappe-prometheus.yml`; edit them if the site URL changes.

### Dashboards

| Dashboard | Source | Panels |
|---|---|---|
| **Frappe — Website Performance** | blackbox → Prometheus | up/down, response time, uptime %, HTTP status, TLS expiry, page size, per-phase latency breakdown (DNS/TCP/TLS/server think time), p50/p95, availability timeline |
| **Frappe — Logs & Errors** | Frappe REST API via Infinity | error count + Error Log table, failed scheduled jobs, job runs by status, scheduler config with last/next run, email queue, logins and activity, document change log |
| **Frappe — Cloud Platform** | Frappe Cloud press API | site status, plan and price, region, CPU/database/disk quota gauges, daily CPU accounting, installed apps with commits, backups, domains |

The Cloud Platform dashboard needs `FRAPPE_CLOUD_API_KEY` / `FRAPPE_CLOUD_API_SECRET` (generated on the **cloud.frappe.io account**, not the site). Its `$site` and `$timezone` are dashboard variables, so pointing it at another site is a text-box edit.

Not everything on the platform API is reachable with an API key: `press.api.analytics.get_uptime`, `get_usage` and `request_logs` exist but Frappe Cloud does not whitelist them for key auth, so server-side request volume and response times stay dashboard-only. That gap is what the blackbox probes cover.

Every log panel honours the dashboard time range — it is passed to Frappe as a `creation` filter using Grafana's `${__from:date:...}` macros. Add panels by pointing new Infinity queries at `/api/resource/<Doctype>` or `/api/method/frappe.client.get_list`.

Frappe 16 rejects SQL strings in `fields`, so aggregates use dict syntax — `fields=["status",{"COUNT":"*"}]` — and the response key is literally `COUNT(*)`, which is what the Infinity column selector must be.

### Persistence — what survives a restart

The JSON files are the source of truth for these dashboards. Grafana re-reads them on start and every 30s, so **edits made in the UI are not saved** — Grafana marks them read-only and rejects the save rather than reverting it silently later.

To change a panel: edit it in the UI → panel menu → **Inspect → Panel JSON** (or dashboard **Export → JSON**) → paste into the matching file in `dashboards/frappe/`. It reloads within 30s, no restart needed. Deleting a file deletes the dashboard from Grafana on the next cycle.

| Thing | Survives restart | Stored in |
|---|---|---|
| The provisioned Frappe dashboards | ✅ (from the files) | `dashboards/frappe/*.json` — in git |
| Probe history (response times, uptime) | ✅ 30 days | `frappe_prometheus_data` volume |
| Dashboards you create yourself in the UI | ✅ | `frappe_grafana_storage` volume |
| Admin password, users, alert rules, UI dashboards | ✅ | same volume |
| …all of the above after `docker compose down -v` | ❌ | `-v` deletes the volume — export anything you care about first |

---

## 🔌 Data Source Details

All four data sources are **automatically provisioned** on first start via `grafana/provisioning/datasources/datasources.yaml`.

| Name | Type | Internal URL | Notes |
|---|---|---|---|
| **Prometheus** | prometheus | `http://prometheus:9090` | Default data source |
| **Loki** | loki | `http://loki:3100` | — |
| **Tempo** | tempo | `http://tempo:3200` | Linked to Loki (trace→logs) & Prometheus (trace→metrics) |
| **Mimir** | prometheus | `http://mimir:9009/prometheus` | Uses `X-Scope-OrgID: anonymous` header |

---

## 📤 Sending Data

### Logs (Loki via Promtail)

Docker container logs are automatically collected by Promtail. No configuration needed.

To send logs from your app directly:

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{"streams":[{"stream":{"job":"myapp"},"values":[["'$(date +%s)000000000'","hello from my app"]]}]}'
```

### Metrics (Prometheus)

Scrape your app by adding it as a target in Prometheus, or push via remote write.

### Traces (Tempo — OTLP)

Send OTLP traces from your app to `http://localhost:4318/v1/traces` (HTTP) or `localhost:4317` (gRPC).

---

## ⚙️ Customization

- **Change Grafana admin password**: edit `GF_SECURITY_ADMIN_PASSWORD` in `compose.yml`
- **Add custom dashboards**: place JSON files in `grafana/provisioning/dashboards/` and mount the directory
- **Adjust Mimir retention**: edit `compactor_blocks_retention_period` in `config/mimir-local.yaml`
- **Add more Prometheus scrape targets**: mount a custom `prometheus.yml`
- **Filter which containers Promtail collects**: edit `config/promtail-config.yaml`

---

## 📋 Requirements

- [Docker](https://docs.docker.com/get-docker/) 24+
- [Docker Compose](https://docs.docker.com/compose/) v2+
- ~2 GB free disk space (images + volumes)
- ~1 GB RAM

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feat/amazing`)
5. Open a Pull Request

CI will automatically validate `compose.yml` and YAML syntax on every push and PR.

---

## 📄 License

[GNU AGPLv3](LICENSE) © 2026
