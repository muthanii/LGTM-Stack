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
