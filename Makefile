.PHONY: up down restart logs ps clean status

# ─── Start / Stop ─────────────────────────────────────────────

up:        ## Start all LGTM services
	docker compose -f compose.yml up -d

down:      ## Stop and remove all services
	docker compose -f compose.yml down

restart:   ## Restart all services
	docker compose -f compose.yml down && docker compose -f compose.yml up -d

# ─── Status & Logs ────────────────────────────────────────────

ps:        ## Show running containers
	docker compose -f compose.yml ps

status:    ## Show service health
	@echo "Grafana:   http://localhost:3000"
	@echo "Prometheus: http://localhost:9090"
	@echo "Loki:       http://localhost:3100"
	@echo "Tempo:      http://localhost:3200"
	@echo "Mimir:      http://localhost:9009"

logs:      ## Tail all service logs
	docker compose -f compose.yml logs -f

logs-%:    ## Tail logs for a specific service (e.g. make logs-grafana)
	docker compose -f compose.yml logs -f $*

# ─── Maintenance ──────────────────────────────────────────────

clean:     ## Stop services and remove volumes (⚠ destroys all data)
	docker compose -f compose.yml down -v

pull:      ## Pull latest images
	docker compose -f compose.yml pull

shell-%:   ## Open a shell in a service container (e.g. make shell-grafana)
	docker compose -f compose.yml exec $* sh

# ─── Help ─────────────────────────────────────────────────────

help:      ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
